import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/json_utils.dart';
import '../models/chat_message.dart';

/// A chat restored from the device: the server session it belongs to and the
/// messages that were on screen.
class SavedChat {
  const SavedChat({required this.sessionId, required this.messages});

  final String sessionId;
  final List<ChatMessage> messages;
}

/// Keeps the current chat on the device (localStorage on web) so it survives
/// an app restart.
///
/// The server only remembers a conversation per session_id and has no history
/// endpoint (docs/backend-requests.md P2-15), so this copy is the only one.
class ChatHistoryStore {
  static const _key = 'chat_history_v1';

  /// Older messages are dropped past this so storage can't grow forever.
  static const maxMessages = 100;

  Future<SavedChat?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final json = asMapOrNull(jsonDecode(raw)) ?? const {};
      final sessionId = asString(json['session_id']);
      final messages = asMapList(
        json['messages'],
      ).map(ChatMessage.fromJson).where((m) => m.text.isNotEmpty).toList();
      if (sessionId.isEmpty || messages.isEmpty) return null;
      return SavedChat(sessionId: sessionId, messages: messages);
    } catch (_) {
      // Corrupt data or no storage (private browsing, widget tests): start
      // fresh rather than break the chat tab.
      return null;
    }
  }

  Future<void> save(String sessionId, List<ChatMessage> messages) async {
    // Error bubbles are failed requests, not conversation worth restoring.
    final kept = messages.where((m) => !m.isError).toList();
    final recent = kept.length > maxMessages
        ? kept.sublist(kept.length - maxMessages)
        : kept;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode({
          'session_id': sessionId,
          'messages': [for (final m in recent) m.toJson()],
        }),
      );
    } catch (_) {
      // Best effort: losing history beats crashing the chat.
    }
  }
}
