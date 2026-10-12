import '../core/json_utils.dart';

enum Sender { user, bot }

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.sender,
    DateTime? time,
    this.isError = false,
  }) : time = time ?? DateTime.now();

  final String text;
  final Sender sender;
  final DateTime time;

  /// A failed request rendered as a bot bubble, styled to look like a problem
  /// rather than an answer.
  final bool isError;

  /// For the on-device chat history. Error bubbles are never saved, so
  /// [isError] is not stored.
  Map<String, dynamic> toJson() => {
    'text': text,
    'sender': sender.name,
    'time': time.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: asString(json['text']),
    sender: json['sender'] == Sender.user.name ? Sender.user : Sender.bot,
    time: asDate(json['time']),
  );
}
