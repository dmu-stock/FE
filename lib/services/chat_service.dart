import '../config/api_config.dart';
import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/json_utils.dart';

/// `POST /chat` — the tool-calling agent behind the 채팅 tab.
///
/// `/ask` exists too, but its "is this about stocks?" guardrail rejects even
/// "엔비디아 요즘 어때?", so the agent endpoint is the one that answers.
class ChatService {
  const ChatService(this._api);

  final ApiClient _api;

  /// Replies in the conversation identified by [sessionId]; the server keeps
  /// memory per session, so a fresh id starts a genuinely new conversation.
  Future<String> send({
    required String message,
    required String sessionId,
  }) async {
    final json = await _api.postJson(
      '/chat',
      body: {'message': message, 'session_id': sessionId},
      timeout: ApiConfig.medium,
    );
    final reply = asString(json['reply']).trim();
    if (reply.isEmpty) {
      throw const ParseException('chat: response had no reply');
    }
    return reply;
  }
}
