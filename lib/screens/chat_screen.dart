import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_exception.dart';
import '../main.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../state/app_scope.dart';
import '../widgets/cold_start_banner.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [
    ChatMessage(
      sender: Sender.bot,
      text:
          '안녕하세요! 감자비(GamJabi)입니다 🥔\n'
          '관심있는 종목이나 시장 분석이 필요하신가요?\n'
          '무엇이든 편하게 물어보세요!',
    ),
  ];

  bool _isTyping = false;

  /// Prompts built from what the user actually holds, falling back to the
  /// blue chips the backend covers when the watchlist is empty.
  List<String> get _suggestions {
    final holdings = AppScope.of(context).holdings;
    if (holdings.isEmpty) {
      return const [
        'NVDA 전망 어때?',
        '오늘 미국 시장 요약해줘',
        '테슬라 최근 뉴스 정리해줘',
        '애플 지금 사도 될까?',
      ];
    }
    final tickers = holdings.take(3).map((h) => h.ticker).toList();
    return [
      '${tickers.first} 전망 어때?',
      '오늘 미국 시장 요약해줘',
      if (tickers.length > 1) '${tickers[1]} 최근 뉴스 정리해줘',
      '내 보유 종목 ${tickers.join(', ')} 중에 뭐가 제일 괜찮아?',
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Another screen may have queued a question (e.g. 챗봇에 묻기 on the
    // analysis sheet). Send it once the tab is actually showing.
    final queued = AppScope.of(context).takePendingChatMessage();
    if (queued == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sendMessage(queued);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    // Guard against a double tap while a reply is still in flight.
    if (trimmed.isEmpty || _isTyping) return;

    final state = AppScope.read(context);

    setState(() {
      _messages.add(ChatMessage(sender: Sender.user, text: trimmed));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final reply = await ChatService(
        state.api,
      ).send(message: trimmed, sessionId: state.chatSessionId);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(sender: Sender.bot, text: reply));
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(sender: Sender.bot, text: e.userMessage, isError: true),
        );
      });
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _startNewChat() {
    // The server keeps conversation memory per session_id, so clearing
    // only the local list would leave the bot still remembering.
    AppScope.read(context).startNewChatSession();
    setState(() {
      _isTyping = false;
      _messages.clear();
      _messages.add(
        ChatMessage(sender: Sender.bot, text: '새 대화를 시작합니다. 무엇을 도와드릴까요? 💬'),
      );
    });
  }

  /// True once the user has asked something, so there is more to copy than
  /// the greeting.
  bool get _hasConversation => _messages.any((m) => m.sender == Sender.user);

  void _copyConversation() {
    // Error bubbles are request failures, not part of the conversation.
    final text = _messages
        .where((m) => !m.isError)
        .map((m) => '${m.sender == Sender.user ? '나' : 'GamJabi'}: ${m.text}')
        .join('\n\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('대화 내용을 복사했어요'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return const TypingIndicator();
                  }
                  return MessageBubble(message: _messages[index]);
                },
              ),
            ),
            if (_messages.length <= 1) _buildSuggestions(),
            const ColdStartBanner(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFEEF1F7), width: 1),
      ),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F86FF), Color(0xFF2F6BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: GamJabiApp.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GamJabi',
                style: TextStyle(
                  color: GamJabiApp.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AI 분석가 온라인',
                    style: TextStyle(
                      color: GamJabiApp.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.refresh_rounded,
            color: GamJabiApp.textDark,
            size: 22,
          ),
          onPressed: _startNewChat,
        ),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: GamJabiApp.textDark,
            size: 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (value) {
            if (value == 'copy') _copyConversation();
            if (value == 'new') _startNewChat();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'copy',
              enabled: _hasConversation,
              child: const Text('대화 내용 복사'),
            ),
            const PopupMenuItem(value: 'new', child: Text('새 대화 시작')),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '추천 질문',
              style: TextStyle(
                color: GamJabiApp.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              return InkWell(
                onTap: () => _sendMessage(s),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: GamJabiApp.softBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: GamJabiApp.primaryBlue.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      color: GamJabiApp.primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF1F7), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E9F2)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: GamJabiApp.textMuted,
                      size: 22,
                    ),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      style: const TextStyle(
                        color: GamJabiApp.textDark,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: '종목이나 시장에 대해 물어보세요',
                        hintStyle: TextStyle(
                          color: GamJabiApp.textMuted,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F86FF), Color(0xFF2F6BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: GamJabiApp.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
