import '../core/json_utils.dart';

/// One bullet from a news summary, with the article it came from.
class NewsKeyPoint {
  const NewsKeyPoint({required this.point, required this.source});

  final String point;

  /// A full article URL.
  final String source;

  /// The bit worth showing in a chip — "finance.yahoo.com".
  String get sourceHost {
    final host = Uri.tryParse(source)?.host ?? '';
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  factory NewsKeyPoint.fromJson(Map<String, dynamic> json) => NewsKeyPoint(
    point: asString(json['point']),
    source: asString(json['source']),
  );
}

/// `POST /news/summary` — recent news for one ticker.
class NewsSummary {
  const NewsSummary({
    required this.ticker,
    required this.overallTone,
    required this.keyPoints,
    required this.notableEvents,
    required this.asOf,
  });

  /// Echoed back from the request; the response body does not include it.
  final String ticker;

  final String overallTone; // '긍정' | '중립' | '부정'
  final List<NewsKeyPoint> keyPoints;
  final String notableEvents;
  final String asOf;

  factory NewsSummary.fromJson(
    Map<String, dynamic> json, {
    required String ticker,
  }) => NewsSummary(
    ticker: ticker,
    overallTone: asString(json['overall_tone']),
    keyPoints: asMapList(
      json['key_points'],
    ).map(NewsKeyPoint.fromJson).where((p) => p.point.isNotEmpty).toList(),
    notableEvents: asString(json['notable_events']),
    asOf: asString(json['as_of']),
  );
}
