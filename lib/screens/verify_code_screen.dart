import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../widgets/signup_progress.dart';
import 'find_password_screen.dart';
import 'reset_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String destination;
  final FindMethod method;

  const VerifyCodeScreen({
    super.key,
    required this.destination,
    this.method = FindMethod.email,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 180;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 180);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining <= 0) {
        t.cancel();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();
  bool get _canProceed => _code.length == 6 && _secondsRemaining > 0;

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _errorText = null);
  }

  void _verify() {
    if (_secondsRemaining <= 0) {
      setState(() => _errorText = '인증 시간이 만료되었어요. 재전송해주세요');
      return;
    }
    if (_code.length != 6) {
      setState(() => _errorText = '6자리 코드를 모두 입력해주세요');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ResetPasswordScreen(),
      ),
    );
  }

  void _resend() {
    _startTimer();
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('인증 코드가 재전송되었어요'),
        backgroundColor: GamJabiApp.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      appBar: AppBar(
        backgroundColor: GamJabiApp.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: GamJabiApp.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '비밀번호 찾기',
          style: TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SignupProgress(currentStep: 2, totalSteps: 3),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildTitle(),
                    const SizedBox(height: 28),
                    _buildCodeInputs(),
                    const SizedBox(height: 16),
                    _buildTimerRow(),
                    if (_errorText != null) ...[
                      const SizedBox(height: 12),
                      _buildErrorBox(_errorText!),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '인증 코드를 입력해주세요',
          style: TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: GamJabiApp.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: widget.method == FindMethod.email
                    ? '아래 이메일로 6자리 코드를 보냈어요\n'
                    : '아래 휴대폰으로 6자리 코드를 보냈어요\n',
              ),
              TextSpan(
                text: widget.destination,
                style: const TextStyle(
                  color: GamJabiApp.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        final filled = _controllers[i].text.isNotEmpty;
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: filled ? GamJabiApp.softBlue : Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: filled
                      ? GamJabiApp.primaryBlue.withOpacity(0.4)
                      : const Color(0xFFE4E9F2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: GamJabiApp.primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (v) => _onCodeChanged(i, v),
          ),
        );
      }),
    );
  }

  Widget _buildTimerRow() {
    final expired = _secondsRemaining <= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 16,
              color: expired ? const Color(0xFFE53935) : GamJabiApp.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              expired ? '시간 만료' : '남은 시간 ${_formatTime(_secondsRemaining)}',
              style: TextStyle(
                color: expired
                    ? const Color(0xFFE53935)
                    : GamJabiApp.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _resend,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '코드 재전송',
            style: TextStyle(
              color: GamJabiApp.primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE53935),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: const BoxDecoration(
        color: GamJabiApp.backgroundWhite,
        border: Border(top: BorderSide(color: Color(0xFFEEF1F7))),
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canProceed ? _verify : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: GamJabiApp.primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFCED4DE),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            '인증 확인',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}
