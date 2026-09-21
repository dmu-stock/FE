/// Backend configuration for the GamJabi API (FastAPI, `DMU_adv_AI API`).
///
/// Values come from `--dart-define` so the same build can point at a local
/// backend. They must be `static const` because `String.fromEnvironment` only
/// resolves in a const context.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'GAMJABI_API_BASE',
    defaultValue: 'https://gamjabi.onrender.com',
  );

  static const String apiPrefix = '/api/v1';

  /// The API has no auth — a member row is created on the first watchlist POST,
  /// keyed by this free-form string. Override with
  /// `--dart-define=GAMJABI_USER=...` to use a separate portfolio.
  static const String demoUserKey = String.fromEnvironment(
    'GAMJABI_USER',
    defaultValue: 'gamjabi-demo-user',
  );

  /// Timeout tiers, sized from measured latency plus Render cold-start headroom.
  static const Duration fast = Duration(seconds: 25); // health, watchlist
  static const Duration medium = Duration(seconds: 75); // chat, news/summary
  static const Duration slow = Duration(seconds: 150); // predict, market/recap

  /// Total attempts (not retries) before giving up on a waking server.
  static const int maxAttempts = 3;

  /// Upper bound on a `Retry-After` value we are willing to honour.
  static const Duration maxRetryDelay = Duration(seconds: 15);
}
