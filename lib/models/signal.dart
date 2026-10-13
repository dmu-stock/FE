import '../core/json_utils.dart';

/// One ticker from the daily ML buy-signal list.
class SignalPick {
  const SignalPick({
    required this.ticker,
    required this.probLgb,
    required this.probLstm,
    required this.finalProb,
    required this.extra,
  });

  final String ticker;

  /// LightGBM and LSTM model outputs, blended into [finalProb].
  final double probLgb;
  final double probLstm;
  final double finalProb;

  /// Picked outside the core universe.
  final bool extra;

  double get finalPercent => finalProb * 100;

  /// Observed probabilities sit in a narrow band (~0.50–0.55), so a raw 0–1
  /// bar would make every pick look identical. Stretch that band across the
  /// full width while the label still shows the true number.
  double get barFraction {
    const low = 0.45;
    const high = 0.60;
    return ((finalProb - low) / (high - low)).clamp(0.0, 1.0);
  }

  factory SignalPick.fromJson(Map<String, dynamic> json) => SignalPick(
    ticker: asString(json['ticker']).toUpperCase(),
    probLgb: asDouble(json['prob_lgb']),
    probLstm: asDouble(json['prob_lstm']),
    finalProb: asDouble(json['final_prob']),
    extra: asBool(json['extra']),
  );
}

/// `GET /signal?top_n=` — read from a CSV the backend precomputes, so [asOf]
/// can lag the other endpoints by weeks. Always show it next to the picks.
class SignalResponse {
  const SignalResponse({
    required this.picks,
    required this.vix,
    required this.asOf,
    required this.reason,
  });

  final List<SignalPick> picks;
  final double vix;
  final String asOf;
  final String reason;

  factory SignalResponse.fromJson(Map<String, dynamic> json) => SignalResponse(
    picks: asMapList(
      json['picks'],
    ).map(SignalPick.fromJson).where((p) => p.ticker.isNotEmpty).toList(),
    vix: asDouble(json['vix']),
    asOf: asString(json['as_of']),
    reason: asString(json['reason']),
  );
}
