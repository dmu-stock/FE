import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_exception.dart';
import '../core/async_value.dart';
import '../main.dart';
import '../models/market_recap.dart';
import '../models/news_summary.dart';
import '../state/app_scope.dart';
import '../widgets/async_view.dart';
import '../widgets/cold_start_banner.dart';
import '../widgets/skeleton_box.dart';

/// 뉴스 tab — `/market/recap` on top, `/news/summary` per ticker below.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  /// Shown when the user has no holdings yet.
  static const List<String> _fallbackTickers = ['NVDA', 'AAPL', 'MSFT', 'TSLA'];

  AsyncValue<MarketRecap> _recap = const AsyncIdle();
  AsyncValue<NewsSummary> _summary = const AsyncIdle();
  String? _selectedTicker;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    // _loadRecap() calls setState synchronously; defer past the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadRecap();
    });
  }

  List<String> get _tickers {
    final holdings = AppScope.of(context).holdings;
    if (holdings.isEmpty) return _fallbackTickers;
    return holdings.map((h) => h.ticker).toList();
  }

  Future<void> _loadRecap({bool force = false}) async {
    final state = AppScope.read(context);
    // The recap covers a whole trading day, so today's is worth keeping.
    if (!force && _recap.hasData) return;

    setState(() => _recap = const AsyncLoading('어제 미국 시장을 정리하는 중이에요…'));
    try {
      final recap = await state.newsService.recap();
      if (!mounted) return;
      setState(() => _recap = AsyncData(recap));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _recap = AsyncError(e));
    }
  }

  Future<void> _loadSummary(String ticker) async {
    final state = AppScope.read(context);
    setState(() {
      _selectedTicker = ticker;
      _summary = AsyncLoading('$ticker 뉴스를 읽는 중이에요…');
    });
    try {
      final summary = await state.newsService.summary(ticker: ticker);
      if (!mounted || _selectedTicker != ticker) return;
      setState(() => _summary = AsyncData(summary));
    } on ApiException catch (e) {
      if (!mounted || _selectedTicker != ticker) return;
      setState(() => _summary = AsyncError(e));
    }
  }

  void _copy(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('링크를 복사했어요'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: GamJabiApp.primaryBlue,
          onRefresh: () async {
            await state.refreshWatchlist(force: true);
            await _loadRecap(force: true);
            final ticker = _selectedTicker;
            if (ticker != null) await _loadSummary(ticker);
          },
          child: SingleChildScrollView(
            // Every tab stays mounted in the IndexedStack; without this they all
            // attach to the PrimaryScrollController and scroll actions break.
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                const ColdStartBanner(margin: EdgeInsets.only(bottom: 12)),
                AsyncView<MarketRecap>(
                  value: _recap,
                  loading: const SkeletonBox(height: 190, radius: 20),
                  onRetry: () => _loadRecap(force: true),
                  builder: (context, recap) => _buildRecapCard(recap),
                ),
                const SizedBox(height: 26),
                _buildSectionTitle('종목 뉴스'),
                const SizedBox(height: 10),
                _buildTickerChips(),
                const SizedBox(height: 14),
                if (_selectedTicker == null)
                  _buildPrompt()
                else
                  AsyncView<NewsSummary>(
                    value: _summary,
                    loading: Column(
                      children: List.generate(
                        3,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: SkeletonBox(height: 62, radius: 14),
                        ),
                      ),
                    ),
                    onRetry: () => _loadSummary(_selectedTicker!),
                    builder: (context, summary) => _buildSummary(summary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: GamJabiApp.softBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.newspaper_rounded,
            color: GamJabiApp.primaryBlue,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '뉴스',
                style: TextStyle(
                  color: GamJabiApp.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '전날 미국 증시 요약과 종목별 뉴스를 AI가 정리해요',
                style: TextStyle(
                  color: GamJabiApp.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecapCard(MarketRecap recap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F86FF), Color(0xFF2F6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: GamJabiApp.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '시장 브리핑',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (recap.asOf.isNotEmpty)
                Text(
                  recap.asOf,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            recap.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
          if (recap.indexParts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recap.indexParts
                  .map(
                    (part) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        part,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (recap.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...recap.keyPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _recapDetail('시장 흐름', recap.marketTheme),
          _recapDetail('특징주', recap.notableMovers),
          _recapDetail('매크로·지정학', recap.macroGeopolitics),
          _recapDetail('오늘 볼 것', recap.watchToday),
        ],
      ),
    );
  }

  Widget _recapDetail(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTickerChips() {
    final tickers = _tickers;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tickers.map((ticker) {
        final selected = _selectedTicker == ticker;
        return ChoiceChip(
          label: Text(ticker),
          selected: selected,
          onSelected: (_) => _loadSummary(ticker),
          showCheckmark: false,
          selectedColor: GamJabiApp.softBlue,
          backgroundColor: const Color(0xFFF4F6FB),
          labelStyle: TextStyle(
            color: selected ? GamJabiApp.primaryBlue : GamJabiApp.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          side: BorderSide(
            color: selected
                ? GamJabiApp.primaryBlue.withValues(alpha: 0.25)
                : const Color(0xFFE4E9F2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color: GamJabiApp.textMuted,
            size: 26,
          ),
          const SizedBox(height: 10),
          Text(
            '종목을 선택하면 최신 뉴스를 요약해드려요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: GamJabiApp.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(NewsSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _toneBadge(summary.overallTone),
            const Spacer(),
            if (summary.asOf.isNotEmpty)
              Text(
                summary.asOf,
                style: TextStyle(
                  color: GamJabiApp.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (summary.keyPoints.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E9F2)),
            ),
            child: Text(
              '${summary.ticker}에 대한 최근 뉴스를 찾지 못했어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GamJabiApp.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ...summary.keyPoints.map(_buildPointCard),
        if (summary.notableEvents.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GamJabiApp.softBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주요 이벤트',
                  style: TextStyle(
                    color: GamJabiApp.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  summary.notableEvents,
                  style: const TextStyle(
                    color: GamJabiApp.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPointCard(NewsKeyPoint point) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E9F2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              point.point,
              style: const TextStyle(
                color: GamJabiApp.textDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            if (point.sourceHost.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _copy(point.source),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: GamJabiApp.softBlue,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 13,
                        color: GamJabiApp.primaryBlue,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        point.sourceHost,
                        style: const TextStyle(
                          color: GamJabiApp.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toneBadge(String tone) {
    final color = switch (tone) {
      '긍정' => const Color(0xFF22A06B),
      '부정' => const Color(0xFFE53935),
      _ => GamJabiApp.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '전반 분위기 · ${tone.isEmpty ? '중립' : tone}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: GamJabiApp.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }
}
