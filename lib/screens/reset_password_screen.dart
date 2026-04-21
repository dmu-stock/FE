import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/signup_progress.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();
  bool _obscurePw = true;
  bool _obscurePwConfirm = true;

  final RegExp _specialRegex = RegExp(r'[^a-zA-Z0-9\s]');

  @override
  void initState() {
    super.initState();
    _pwController.addListener(() => setState(() {}));
    _pwConfirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pwController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _pwController.text.length >= 8 &&
      _specialRegex.hasMatch(_pwController.text) &&
      _pwController.text == _pwConfirmController.text;

  void _submit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildSuccessDialog(),
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
            const SignupProgress(currentStep: 3, totalSteps: 3),
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
                    _buildLabel('새 비밀번호'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _pwController,
                      hint: '영문+숫자+특수문자 8자 이상',
                      obscure: _obscurePw,
                      onToggle: () => setState(() => _obscurePw = !_obscurePw),
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('새 비밀번호 확인'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _pwConfirmController,
                      hint: '비밀번호를 다시 입력해주세요',
                      obscure: _obscurePwConfirm,
                      onToggle: () => setState(
                          () => _obscurePwConfirm = !_obscurePwConfirm),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordHint(),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '새 비밀번호를 설정해주세요',
          style: TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '이전에 사용하지 않은 비밀번호로 설정해주세요',
          style: TextStyle(
            color: GamJabiApp.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: GamJabiApp.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          color: GamJabiApp.textDark,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: GamJabiApp.textMuted,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: GamJabiApp.textMuted,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: GamJabiApp.textMuted,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordHint() {
    final lengthOk = _pwController.text.length >= 8;
    final specialOk = _specialRegex.hasMatch(_pwController.text);
    final matchOk = _pwController.text.isNotEmpty &&
        _pwController.text == _pwConfirmController.text;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GamJabiApp.softBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hintRow('8자 이상', lengthOk),
          const SizedBox(height: 6),
          _hintRow('특수문자 1개 이상 포함', specialOk),
          const SizedBox(height: 6),
          _hintRow('비밀번호 일치', matchOk),
        ],
      ),
    );
  }

  Widget _hintRow(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: ok ? GamJabiApp.primaryBlue : GamJabiApp.textMuted,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: ok ? GamJabiApp.primaryBlue : GamJabiApp.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
          onPressed: _canProceed ? _submit : null,
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
            '비밀번호 변경',
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

  Widget _buildSuccessDialog() {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F86FF), Color(0xFF2F6BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: GamJabiApp.primaryBlue.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '비밀번호가 변경되었어요',
              style: TextStyle(
                color: GamJabiApp.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새 비밀번호로 로그인해주세요',
              style: TextStyle(
                color: GamJabiApp.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil(
                    (route) => route.settings.name == '/login',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GamJabiApp.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '로그인하러 가기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
