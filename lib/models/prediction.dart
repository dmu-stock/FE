import '../core/json_utils.dart';

/// `GET /predict?ticker=` — the LLM-backed analysis for one ticker.
///
/// Only [currentPrice] is used by the home screen today; the rest is parsed so
/// the 분석 tab can be built on it without touching this file.
class Prediction {
  const Prediction({
    required this.ticker,
    required this.ok,
    required this.signal,
    required this.probability,
    required this.confidence,
    required this.trend,
    required this.currentPrice,
    required this.recommendedBuy,
    required this.resistance1,
    required this.resistance2,
    required this.support,
    required this.sma5,
    required this.sma20,
    required this.sma60,
    required this.rsi14,
    required this.flags,
    required this.asOf,
    required this.nArticles,
    required this.signalSource,
    required this.llmReasoning,
    required this.say,
    required this.result,
    required this.caution,
    required this.upsideTrigger,
  });

  final String ticker;

  /// False when the backend could not analyse this ticker at all — check before
  /// rendering any of the figures below.
  final bool ok;

  final String signal; // 'up' | 'down' | ...
  final double probability;
  final double confidence;
  final String trend;

  final double currentPrice;
  final double recommendedBuy;
  final double resistance1;
  final double resistance2;
  final double support;

  final double sma5;
  final double sma20;
  final double sma60;
  final double rsi14;
  final List<String> flags;

  final String asOf;
  final int nArticles;
  final String signalSource; // 'llm_csv' | 'heuristic'
  final String llmReasoning;

  final String say;
  final String result;
  final String caution;
  final String upsideTrigger;

  bool get isUp => signal.toLowerCase() == 'up';

  bool get hasPrice => ok && currentPrice > 0;

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
    ticker: asString(json['ticker']).toUpperCase(),
    ok: asBool(json['ok'], true),
    signal: asString(json['signal']),
    probability: asDouble(json['probability']),
    confidence: asDouble(json['confidence']),
    trend: asString(json['trend']),
    currentPrice: asDouble(json['current_price']),
    recommendedBuy: asDouble(json['recommended_buy']),
    resistance1: asDouble(json['resistance_1']),
    resistance2: asDouble(json['resistance_2']),
    support: asDouble(json['support']),
    sma5: asDouble(json['sma_5']),
    sma20: asDouble(json['sma_20']),
    sma60: asDouble(json['sma_60']),
    rsi14: asDouble(json['rsi_14']),
    flags: asStringList(json['flags']),
    asOf: asString(json['as_of']),
    nArticles: asInt(json['n_articles']),
    signalSource: asString(json['signal_source']),
    llmReasoning: asString(json['llm_reasoning']),
    say: asString(json['say']),
    result: asString(json['result']),
    caution: asString(json['caution']),
    upsideTrigger: asString(json['upside_trigger']),
  );
}
