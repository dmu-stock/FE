import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/watchlist_item.dart';

/// Watchlist CRUD under `/members/{userKey}/watchlist`.
///
/// The API has no auth: posting to a key creates that member on the fly.
class WatchlistService {
  const WatchlistService(this._api);

  final ApiClient _api;

  String _base(String userKey) =>
      '/members/${Uri.encodeComponent(userKey)}/watchlist';

  Future<List<WatchlistItem>> list(String userKey) async {
    final json = await _api.getJson(_base(userKey));
    return WatchlistResponse.fromJson(json).items;
  }

  /// Returns true when the ticker was already on the list (the server reports
  /// `already: true` and updates the quantity/price instead of inserting).
  Future<bool> add(
    String userKey, {
    required String ticker,
    double? quantity,
    double? avgBuyPrice,
  }) async {
    final json = await _api.postJson(
      _base(userKey),
      body: {
        'ticker': ticker.toUpperCase(),
        'quantity': ?quantity,
        'avg_buy_price': ?avgBuyPrice,
      },
    );
    return asBool(json['already']);
  }

  Future<void> update(
    String userKey,
    String ticker, {
    double? quantity,
    double? avgBuyPrice,
  }) => _api.patchJson(
    '${_base(userKey)}/${Uri.encodeComponent(ticker.toUpperCase())}',
    body: {'quantity': ?quantity, 'avg_buy_price': ?avgBuyPrice},
  );

  Future<void> remove(String userKey, String ticker) => _api.deleteJson(
    '${_base(userKey)}/${Uri.encodeComponent(ticker.toUpperCase())}',
  );
}
