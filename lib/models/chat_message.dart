enum Sender { user, bot }

class ChatMessage {
  final String text;
  final Sender sender;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.sender,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}
