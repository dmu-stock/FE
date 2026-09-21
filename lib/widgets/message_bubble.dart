import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../main.dart';

/// Matches a markdown inline link: `[label](https://example.com)`.
///
/// The chat agent cites its sources this way, so rendering the raw text would
/// show the brackets and the full URL inline.
final RegExp _linkPattern = RegExp(r'\[([^\]\n]+)\]\(([^)\s]+)\)');

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;
    final isError = message.isError;

    final Color background = isUser
        ? GamJabiApp.primaryBlue
        : (isError ? const Color(0xFFFFF5F5) : Colors.white);
    final Color borderColor = isError
        ? const Color(0xFFE53935).withValues(alpha: 0.35)
        : const Color(0xFFE4E9F2);
    final Color textColor = isUser ? Colors.white : GamJabiApp.textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _botAvatar(isError),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? GamJabiApp.primaryBlue.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isError) ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 8),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ],
                      Flexible(
                        child: _MessageText(
                          text: message.text,
                          color: textColor,
                          linkColor: isUser
                              ? Colors.white
                              : GamJabiApp.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    _formatTime(message.time),
                    style: const TextStyle(
                      color: GamJabiApp.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botAvatar(bool isError) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isError
              ? const [Color(0xFFEF6B6B), Color(0xFFE53935)]
              : const [Color(0xFF4F86FF), Color(0xFF2F6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isError ? const Color(0xFFE53935) : GamJabiApp.primaryBlue)
                .withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        isError ? Icons.cloud_off_rounded : Icons.trending_up_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

/// Renders the message, turning markdown links into tappable labels that copy
/// their URL (opening a browser would need `url_launcher`).
class _MessageText extends StatefulWidget {
  const _MessageText({
    required this.text,
    required this.color,
    required this.linkColor,
  });

  final String text;
  final Color color;
  final Color linkColor;

  @override
  State<_MessageText> createState() => _MessageTextState();
}

class _MessageTextState extends State<_MessageText> {
  /// Recognizers hold gesture state and must be disposed with the widget.
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _copy(String url) {
    Clipboard.setData(ClipboardData(text: url));
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('링크를 복사했어요'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final baseStyle = TextStyle(color: widget.color, fontSize: 15, height: 1.4);

    final matches = _linkPattern.allMatches(widget.text).toList();
    if (matches.isEmpty) {
      return Text(widget.text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, match.start)));
      }
      final label = match.group(1)!;
      final url = match.group(2)!;
      final recognizer = TapGestureRecognizer()..onTap = () => _copy(url);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: label,
          recognizer: recognizer,
          style: TextStyle(
            color: widget.linkColor,
            decoration: TextDecoration.underline,
            decorationColor: widget.linkColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}
