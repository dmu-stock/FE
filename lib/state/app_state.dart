import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/async_value.dart';
import '../models/watchlist_item.dart';
import '../services/market_service.dart';
import '../services/news_service.dart';
import '../services/predict_service.dart';
import '../services/watchlist_service.dart';

/// App-wide shared state.
///
/// A shared notifier is required rather than optional here: [MainScaffold] uses
/// an `IndexedStack`, so every tab stays mounted and a `FutureBuilder` inside
/// the home screen would fetch once and never see a stock added from the
/// 등록 tab.
class AppState extends ChangeNotifier {
  AppState({ApiClient? api})
    : api = api ?? ApiClient(),
      // Not 1 << 32: JavaScript bitwise ops are 32-bit, so that overflows to
      // 0 on web and nextInt throws.
      _sessionSeed = Random.secure().nextInt(1 << 30) {
    watchlistService = WatchlistService(this.api);
    predictService = PredictService(this.api);
    newsService = NewsService(this.api);
    marketService = MarketService(this.api);
    this.api.onColdStart = _onColdStart;
    chatSessionId = _newSessionId();
  }

  final ApiClient api;
  late final WatchlistService watchlistService;
  late final PredictService predictService;
  late final NewsService newsService;
  late final MarketService marketService;

  final int _sessionSeed;
  int _sessionCounter = 0;

  /// No auth exists on the backend, so identity is a fixed key.
  String get userKey => ApiConfig.demoUserKey;

  late String chatSessionId;

  /// True while the client is waiting out a booting Render dyno.
  bool isWarmingUp = false;
  Timer? _warmupTimer;

  AsyncValue<List<WatchlistItem>> watchlist = const AsyncIdle();
  bool _pricesLoading = false;

  bool get pricesLoading => _pricesLoading;

  List<WatchlistItem> get holdings => watchlist.dataOrNull ?? const [];

  bool holds(String ticker) =>
      holdings.any((h) => h.ticker == ticker.toUpperCase());

  /// A tab the app wants to jump to, consumed by [MainScaffold].
  int? requestedTab;

  /// A question queued for the chat tab, consumed by [ChatScreen] when it
  /// becomes visible. Lets other screens hand a ticker off to the bot.
  String? pendingChatMessage;

  /// Sends the user to the chat tab with a question about [ticker] ready.
  void askChatAbout(String ticker) {
    pendingChatMessage = '$ticker 지금 어때? 최근 뉴스랑 전망 정리해줘';
    requestedTab = _chatTabIndex;
    notifyListeners();
  }

  static const int _chatTabIndex = 3;

  String? takePendingChatMessage() {
    final message = pendingChatMessage;
    pendingChatMessage = null;
    return message;
  }

  int? takeRequestedTab() {
    final tab = requestedTab;
    requestedTab = null;
    return tab;
  }

  double get totalCost =>
      holdings.fold<double>(0, (sum, item) => sum + item.cost);

  int get holdingCount => holdings.length;

  /// Total market value, counting only the holdings whose price has landed.
  /// Null until at least one has.
  double? get totalValue {
    final priced = holdings.where((h) => h.currentPrice != null);
    if (priced.isEmpty) return null;
    return priced.fold<double>(0, (sum, item) => sum + (item.value ?? 0));
  }

  /// Cost basis of the holdings that have a price, so profit compares like
  /// with like while the rest are still loading.
  double? get pricedCost {
    final priced = holdings.where((h) => h.currentPrice != null);
    if (priced.isEmpty) return null;
    return priced.fold<double>(0, (sum, item) => sum + item.cost);
  }

  double? get totalReturnPct {
    final value = totalValue;
    final cost = pricedCost;
    if (value == null || cost == null || cost <= 0) return null;
    return (value - cost) / cost * 100;
  }

  bool get allPricesLoaded =>
      holdings.isNotEmpty && holdings.every((h) => h.currentPrice != null);

  /// Wakes the Render dyno so the first real request is not the one that pays
  /// the 30–60s cold start.
  Future<void> bootstrap() async {
    try {
      await api.getJson('/health');
    } on ApiException {
      // Best-effort only; the screens surface their own failures.
    }
    _setWarming(false);
  }

  Future<void> refreshWatchlist({bool force = false}) async {
    if (watchlist.isLoading) return;
    if (!force && watchlist.hasData) return;

    watchlist = const AsyncLoading('포트폴리오를 불러오는 중…');
    notifyListeners();

    try {
      final items = await watchlistService.list(userKey);
      // Carry over prices we already fetched so a refresh doesn't blank them.
      final previous = {
        for (final h in holdings)
          if (h.currentPrice != null) h.ticker: h.currentPrice!,
      };
      for (final item in items) {
        item.currentPrice = previous[item.ticker];
      }
      watchlist = AsyncData(items);
      notifyListeners();
      unawaited(loadPrices());
    } on ApiException catch (e) {
      watchlist = AsyncError(e);
      notifyListeners();
    }
  }

  Future<void> addHolding({
    required String ticker,
    double? quantity,
    double? avgBuyPrice,
  }) async {
    final already = await watchlistService.add(
      userKey,
      ticker: ticker,
      quantity: quantity,
      avgBuyPrice: avgBuyPrice,
    );
    predictService.invalidate(ticker);
    await refreshWatchlist(force: true);
    _lastAddWasUpdate = already;
  }

  bool _lastAddWasUpdate = false;

  /// Whether the most recent [addHolding] updated an existing row.
  bool get lastAddWasUpdate => _lastAddWasUpdate;

  Future<void> updateHolding(
    String ticker, {
    double? quantity,
    double? avgBuyPrice,
  }) async {
    await watchlistService.update(
      userKey,
      ticker,
      quantity: quantity,
      avgBuyPrice: avgBuyPrice,
    );
    await refreshWatchlist(force: true);
  }

  Future<void> removeHolding(String ticker) async {
    await watchlistService.remove(userKey, ticker);
    predictService.invalidate(ticker);
    await refreshWatchlist(force: true);
  }

  /// Fills in current prices from `/predict`, two tickers at a time.
  ///
  /// Each call takes 10–60s, so results are published as they land rather than
  /// awaited as a batch, and the concurrency cap keeps a large portfolio from
  /// stampeding the backend.
  Future<void> loadPrices({bool force = false}) async {
    if (_pricesLoading) return;
    final pending = holdings
        .where((h) => force || h.currentPrice == null)
        .map((h) => h.ticker)
        .toList();
    if (pending.isEmpty) return;

    _pricesLoading = true;
    notifyListeners();

    final queue = List<String>.from(pending);

    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final ticker = queue.removeAt(0);
        try {
          final prediction = await predictService.predict(
            ticker,
            useCache: !force,
          );
          if (!prediction.hasPrice) continue;
          for (final item in holdings) {
            if (item.ticker == ticker) {
              item.currentPrice = prediction.currentPrice;
            }
          }
          notifyListeners();
        } on ApiException {
          // A ticker outside the backend's coverage just stays unpriced.
        }
      }
    }

    await Future.wait([worker(), worker()]);

    _pricesLoading = false;
    notifyListeners();
  }

  /// Rotates the chat session so the server-side conversation memory is
  /// dropped too — clearing the local message list alone would leave the bot
  /// still remembering the previous turns.
  String startNewChatSession() {
    chatSessionId = _newSessionId();
    notifyListeners();
    return chatSessionId;
  }

  String _newSessionId() =>
      '${userKey.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '-')}'
      '-${_sessionSeed.toRadixString(36)}'
      '-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}'
      '-${_sessionCounter++}';

  void _onColdStart(Duration waitHint) {
    _setWarming(true);
    _warmupTimer?.cancel();
    // Clear the banner shortly after the wait would have elapsed, in case the
    // retry succeeds without another callback.
    _warmupTimer = Timer(waitHint + const Duration(seconds: 5), () {
      _setWarming(false);
    });
  }

  void _setWarming(bool value) {
    if (isWarmingUp == value) return;
    isWarmingUp = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _warmupTimer?.cancel();
    api.close();
    super.dispose();
  }
}
