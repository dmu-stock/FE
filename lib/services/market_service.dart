import '../config/api_config.dart';
import '../core/api_client.dart';
import '../models/signal.dart';

/// The endpoints behind the 분석 tab that aren't already covered by
/// [PredictService].
class MarketService {
  const MarketService(this._api);

  final ApiClient _api;

  /// Today's ML buy signals. Cheap — measured around 0.5s warm.
  Future<SignalResponse> signal({int topN = 5}) async {
    final json = await _api.getJson(
      '/signal',
      query: {'top_n': topN},
      timeout: ApiConfig.fast,
    );
    return SignalResponse.fromJson(json);
  }

  /// Candle + moving-average + volume PNG.
  ///
  /// Returned as a URL rather than bytes so `Image.network` can handle the
  /// fetch: Flutter's ImageCache plus the server's own `max-age=300` gives
  /// caching for free, and `errorBuilder` covers the intermittent 404.
  Uri chartUri(String ticker, {String period = '6mo'}) => _api.uriFor(
    '/chart',
    query: {'ticker': ticker.toUpperCase(), 'period': period},
  );
}
