import '../core/json_utils.dart';

/// One holding in the user's watchlist.
///
/// The server stores exactly three things — ticker, quantity and average buy
/// price. [currentPrice] is filled in later from `/predict` and is null until
/// that (slow) call lands.
class WatchlistItem {
  WatchlistItem({
    required this.ticker,
    this.quantity = 0,
    this.avgBuyPrice = 0,
    this.currentPrice,
    this.addedAt,
  });

  final String ticker;
  final double quantity;
  final double avgBuyPrice;
  double? currentPrice;

  /// Server-side insertion time; the API already returns newest-first.
  final DateTime? addedAt;

  /// What the position cost — known offline, so the UI can show it immediately.
  double get cost => quantity * avgBuyPrice;

  double? get value => currentPrice == null ? null : quantity * currentPrice!;

  double? get profit {
    final v = value;
    return v == null ? null : v - cost;
  }

  double? get returnPct {
    if (currentPrice == null || avgBuyPrice <= 0) return null;
    return (currentPrice! - avgBuyPrice) / avgBuyPrice * 100;
  }

  /// Quantities come back as `number`, but positions are whole shares in the UI.
  int get shares => quantity.round();

  String get initial => ticker.isEmpty ? '?' : ticker[0].toUpperCase();

  /// Keys verified against a live response:
  /// `{"ticker":"NVDA","quantity":4.0,"avg_buy_price":219.34,
  ///   "added_at":"2026-09-21 11:26:51","updated_at":"..."}`
  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
    ticker: asString(json['ticker']).toUpperCase(),
    quantity: asDouble(json['quantity']),
    avgBuyPrice: asDouble(json['avg_buy_price']),
    addedAt: asDate(json['added_at']),
  );

  WatchlistItem copyWith({
    double? quantity,
    double? avgBuyPrice,
    double? currentPrice,
  }) => WatchlistItem(
    ticker: ticker,
    quantity: quantity ?? this.quantity,
    avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
    currentPrice: currentPrice ?? this.currentPrice,
  );
}

/// `GET /members/{id}/watchlist`
class WatchlistResponse {
  const WatchlistResponse({
    required this.discordId,
    required this.count,
    required this.items,
  });

  final String discordId;
  final int count;
  final List<WatchlistItem> items;

  factory WatchlistResponse.fromJson(Map<String, dynamic> json) =>
      WatchlistResponse(
        discordId: asString(json['discord_id']),
        count: asInt(json['count']),
        items: asMapList(json['items'])
            .map(WatchlistItem.fromJson)
            .where((i) => i.ticker.isNotEmpty)
            .toList(),
      );
}
