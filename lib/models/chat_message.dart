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
}
