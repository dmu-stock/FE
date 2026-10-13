import '../config/api_config.dart';
import '../core/api_client.dart';
import '../models/market_recap.dart';
import '../models/news_summary.dart';

/// The two endpoints behind the 뉴스 tab.
class NewsService {
  const NewsService(this._api);

  final ApiClient _api;

  /// Previous-day US market wrap-up. Measured around 15s warm.
  Future<MarketRecap> recap() async {
    final json = await _api.getJson('/market/recap', timeout: ApiConfig.slow);
    return MarketRecap.fromJson(json);
  }

  /// Recent news for one ticker, summarised with sources.
  Future<NewsSummary> summary({required String ticker, int limit = 8}) async {
    final upper = ticker.toUpperCase();
    final json = await _api.postJson(
      '/news/summary',
      body: {'ticker': upper, 'limit': limit.clamp(1, 20)},
    );
    return NewsSummary.fromJson(json, ticker: upper);
  }
}
