import '../config/api_config.dart';
import '../core/api_client.dart';
import '../models/prediction.dart';

/// `GET /predict?ticker=` — the only endpoint that returns a current price.
///
/// It is LLM-backed and takes 10–60s per ticker, so results are cached and
/// callers are expected to run it in the background rather than block on it.
class PredictService {
  PredictService(this._api);

  final ApiClient _api;
  final Map<String, _CachedPrediction> _cache = {};

  static const Duration _ttl = Duration(minutes: 10);

  Future<Prediction> predict(String ticker, {bool useCache = true}) async {
    final key = ticker.toUpperCase();

    if (useCache) {
      final hit = _cache[key];
      if (hit != null && DateTime.now().difference(hit.at) < _ttl) {
        return hit.value;
      }
    }

    final json = await _api.getJson(
      '/predict',
      query: {'ticker': key},
      timeout: ApiConfig.slow,
    );
    final prediction = Prediction.fromJson(json);
    _cache[key] = _CachedPrediction(prediction, DateTime.now());
    return prediction;
  }

  void invalidate(String ticker) => _cache.remove(ticker.toUpperCase());

  void clear() => _cache.clear();
}

class _CachedPrediction {
  const _CachedPrediction(this.value, this.at);

  final Prediction value;
  final DateTime at;
}
