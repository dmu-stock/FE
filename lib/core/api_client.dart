import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';
import 'json_utils.dart';

/// Called just before the client sleeps to wait out a waking Render dyno, so
/// the UI can show a "server is booting" banner.
typedef ColdStartCallback = void Function(Duration waitHint);

/// Thin JSON transport over the GamJabi API.
///
/// Two non-obvious rules this class exists to enforce:
///
/// 1. **Decode from bytes.** The server sends `Content-Type: application/json`
///    with no charset, and `package:http` then falls back to latin-1 per
///    RFC 2616 — which mangles every Korean string the API returns. So we read
///    [http.Response.bodyBytes] and never `.body`.
/// 2. **Encode to bytes.** A Korean request body sent as a plain `String` comes
///    back as `400 {"detail":"There was an error parsing the body"}`.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl, this.onColdStart})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Reused across calls so the TLS connection stays warm.
  final http.Client _client;
  final String _baseUrl;

  /// Assignable so [AppState] can wire the banner up after construction.
  ColdStartCallback? onColdStart;

  static const Map<String, String> _readHeaders = {
    'Accept': 'application/json',
  };
  static const Map<String, String> _writeHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
  };

  Uri uriFor(String path, {Map<String, dynamic>? query}) {
    final uri = Uri.parse('$_baseUrl${ApiConfig.apiPrefix}$path');
    if (query == null || query.isEmpty) return uri;
    final params = <String, String>{};
    query.forEach((key, value) {
      if (value != null) params[key] = value.toString();
    });
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query,
    Duration timeout = ApiConfig.fast,
  }) => _send(
    () => _client.get(uriFor(path, query: query), headers: _readHeaders),
    timeout: timeout,
    // GET is safe to repeat, so network blips and timeouts may be retried.
    idempotent: true,
  );

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = ApiConfig.medium,
  }) => _send(
    () =>
        _client.post(uriFor(path), headers: _writeHeaders, body: _encode(body)),
    timeout: timeout,
    idempotent: false,
  );

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = ApiConfig.fast,
  }) => _send(
    () => _client.patch(
      uriFor(path),
      headers: _writeHeaders,
      body: _encode(body),
    ),
    timeout: timeout,
    idempotent: false,
  );

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Duration timeout = ApiConfig.fast,
  }) => _send(
    () => _client.delete(uriFor(path), headers: _readHeaders),
    timeout: timeout,
    idempotent: false,
  );

  void close() => _client.close();

  static List<int>? _encode(Map<String, dynamic>? body) =>
      body == null ? null : utf8.encode(jsonEncode(body));

  /// Runs [send] with a per-attempt [timeout], retrying while the server looks
  /// like it is still booting.
  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() send, {
    required Duration timeout,
    required bool idempotent,
  }) async {
    ApiException? lastFailure;

    for (var attempt = 1; attempt <= ApiConfig.maxAttempts; attempt++) {
      final bool isLast = attempt == ApiConfig.maxAttempts;
      http.Response response;

      try {
        response = await send().timeout(timeout);
      } on TimeoutException {
        lastFailure = ApiTimeoutException(
          'request exceeded ${timeout.inSeconds}s',
          timeout,
        );
        // Only replay a request we know is safe to repeat.
        if (isLast || !idempotent) throw lastFailure;
        await _waitBefore(attempt, null);
        continue;
      } on http.ClientException catch (e) {
        // IOClient wraps SocketException in ClientException, so this covers
        // native and web without importing dart:io.
        lastFailure = NetworkException(e.message);
        if (isLast || !idempotent) throw lastFailure;
        await _waitBefore(attempt, null);
        continue;
      }

      // 502/503/504 come from Render's edge before the app is reached, so no
      // request was executed — safe to replay even for POST/PATCH/DELETE.
      if (_isWaking(response.statusCode)) {
        lastFailure = ServerWakingException(
          'server returned ${response.statusCode} while waking',
        );
        if (isLast) throw lastFailure;
        await _waitBefore(attempt, response.headers['retry-after']);
        continue;
      }

      return _decode(response);
    }

    throw lastFailure ?? const ServerWakingException('retries exhausted');
  }

  static bool _isWaking(int status) =>
      status == 502 || status == 503 || status == 504;

  Future<void> _waitBefore(int attempt, String? retryAfterHeader) async {
    final seconds = int.tryParse(retryAfterHeader?.trim() ?? '');
    var delay = seconds != null
        ? Duration(seconds: seconds)
        : Duration(seconds: attempt == 1 ? 2 : 5);
    if (delay > ApiConfig.maxRetryDelay) delay = ApiConfig.maxRetryDelay;
    if (delay < const Duration(seconds: 1)) delay = const Duration(seconds: 1);

    onColdStart?.call(delay);
    await Future<void>.delayed(delay);
  }

  Map<String, dynamic> _decode(http.Response response) {
    // See the class doc: `.body` would latin-1 decode the Korean payloads.
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    final status = response.statusCode;

    Object? decoded;
    if (text.isNotEmpty) {
      try {
        decoded = jsonDecode(text);
      } on FormatException catch (e) {
        if (status >= 200 && status < 300) {
          throw ParseException('invalid JSON: ${e.message}');
        }
        // A non-JSON error body is still an HTTP failure; report the status.
        throw HttpStatusException('HTTP $status', status, null);
      }
    }

    if (status == 422) {
      throw ValidationException('HTTP 422', _fieldErrors(decoded));
    }

    if (status < 200 || status >= 300) {
      throw HttpStatusException('HTTP $status', status, _detailOf(decoded));
    }

    final map = asMapOrNull(decoded);
    if (map == null) {
      throw ParseException(
        'expected a JSON object, got ${decoded.runtimeType}',
      );
    }
    return map;
  }

  /// Flattens FastAPI's `{"detail":[{"loc":[...],"msg":"..."}]}` into
  /// `{field: message}`.
  static Map<String, String> _fieldErrors(Object? decoded) {
    final detail = asMapOrNull(decoded)?['detail'];
    final errors = <String, String>{};
    for (final entry in asMapList(detail)) {
      final loc = entry['loc'];
      final field = loc is List && loc.isNotEmpty ? asString(loc.last) : 'body';
      errors[field] = asString(entry['msg'], '올바르지 않은 값');
    }
    return errors;
  }

  static String? _detailOf(Object? decoded) {
    final detail = asMapOrNull(decoded)?['detail'];
    return detail is String && detail.isNotEmpty ? detail : null;
  }
}
