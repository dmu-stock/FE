/// Typed failures from [ApiClient].
///
/// Sealed so `switch` over a failure is exhaustively checked at compile time.
/// Every case carries a developer-facing [message] and a Korean [userMessage]
/// that screens can show verbatim.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  String get userMessage;

  @override
  String toString() => '$runtimeType: $message';
}

/// No usable connection — DNS failure, offline, TLS handshake.
class NetworkException extends ApiException {
  const NetworkException(super.message);

  @override
  String get userMessage => '인터넷 연결을 확인해 주세요.';
}

/// A single attempt exceeded its time budget.
///
/// Named to avoid colliding with `dart:async`'s `TimeoutException`.
class ApiTimeoutException extends ApiException {
  const ApiTimeoutException(super.message, this.limit);

  final Duration limit;

  @override
  String get userMessage => 'AI 분석이 오래 걸리고 있어요. 잠시 후 다시 시도해 주세요.';
}

/// Render's free tier was still booting after every retry.
class ServerWakingException extends ApiException {
  const ServerWakingException(super.message);

  @override
  String get userMessage => '서버가 깨어나는 중이에요. 30초 뒤 다시 시도해 주세요.';
}

/// Any other non-2xx response.
class HttpStatusException extends ApiException {
  const HttpStatusException(super.message, this.statusCode, this.detail);

  final int statusCode;

  /// FastAPI's `detail` field when the body carried one.
  final String? detail;

  @override
  String get userMessage => switch (statusCode) {
    404 => '해당 데이터를 찾을 수 없어요.',
    400 => detail ?? '요청 형식이 올바르지 않아요.',
    >= 500 => '서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요.',
    _ => '요청을 처리하지 못했어요. (오류 $statusCode)',
  };
}

/// 422 — FastAPI rejected the request body, parsed into per-field messages.
class ValidationException extends ApiException {
  const ValidationException(super.message, this.fieldErrors);

  /// Field name (the last element of `loc`) to its `msg`.
  final Map<String, String> fieldErrors;

  @override
  String get userMessage => fieldErrors.isEmpty
      ? '입력값을 확인해 주세요.'
      : '입력값 오류: ${fieldErrors.entries.map((e) => '${e.key} ${e.value}').join(', ')}';
}

/// The response was not the JSON object we expected.
class ParseException extends ApiException {
  const ParseException(super.message);

  @override
  String get userMessage => '서버 응답을 읽지 못했어요.';
}
