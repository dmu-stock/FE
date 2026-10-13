import '../core/json_utils.dart';

/// `GET /market/recap` — previous-day US market wrap-up.
///
/// Note `keyPoints` here is a list of plain strings. The identically named
/// field on [NewsSummary] is a list of objects — do not share a parser.
class MarketRecap {
  const MarketRecap({
    required this.headline,
    required this.indexSummary,
    required this.marketTheme,
    required this.notableMovers,
    required this.macroGeopolitics,
    required this.keyPoints,
    required this.watchToday,
    required this.asOf,
  });

  final String headline;
  final String indexSummary;
  final String marketTheme;
  final String notableMovers;
  final String macroGeopolitics;
  final List<String> keyPoints;
  final String watchToday;
  final String asOf;

  /// `indexSummary` is one comma-joined line ("S&P500: 7,637.76 (+1.14%), ...").
  /// Split on the commas that separate entries, not the ones inside numbers.
  List<String> get indexParts => indexSummary
      .split(RegExp(r',(?=\s*[A-Za-z])'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  factory MarketRecap.fromJson(Map<String, dynamic> json) => MarketRecap(
    headline: asString(json['headline']),
    indexSummary: asString(json['index_summary']),
    marketTheme: asString(json['market_theme']),
    notableMovers: asString(json['notable_movers']),
    macroGeopolitics: asString(json['macro_geopolitics']),
    keyPoints: asStringList(json['key_points']),
    watchToday: asString(json['watch_today']),
    asOf: asString(json['as_of']),
  );
}
