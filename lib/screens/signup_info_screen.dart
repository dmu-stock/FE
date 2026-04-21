import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../widgets/signup_progress.dart';
import 'signup_complete_screen.dart';

class SignupInfoScreen extends StatefulWidget {
  const SignupInfoScreen({super.key});

  @override
  State<SignupInfoScreen> createState() => _SignupInfoScreenState();
}

class _SignupInfoScreenState extends State<SignupInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneCodeController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();

  bool _obscurePw = true;
  bool _obscurePwConfirm = true;

  bool _emailCodeSent = false;
  bool _emailVerified = false;
  int _emailSecondsLeft = 0;
  Timer? _emailTimer;

  bool _phoneCodeSent = false;
  bool _phoneVerified = false;
  int _phoneSecondsLeft = 0;
  Timer? _phoneTimer;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _pwError;
  String? _pwConfirmError;

  final RegExp _emailRegex = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$');
  final RegExp _phoneRegex = RegExp(r'^01[0-9]{8,9}$');
  final RegExp _specialRegex = RegExp(r'[^a-zA-Z0-9\s]');

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameController,
      _emailController,
      _phoneController,
      _pwController,
      _pwConfirmController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _emailTimer?.cancel();
    _phoneTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _phoneController.dispose();
    _phoneCodeController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    return _nameController.text.trim().length >= 2 &&
        _emailVerified &&
        _phoneVerified &&
        _pwController.text.length >= 8 &&
        _specialRegex.hasMatch(_pwController.text) &&
        _pwController.text == _pwConfirmController.text;
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  void _sendEmailCode() {
    if (!_emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() => _emailError = '올바른 이메일 형식을 입력해주세요');
      return;
    }
    _emailTimer?.cancel();
    setState(() {
      _emailError = null;
      _emailCodeSent = true;
      _emailVerified = false;
      _emailCodeController.clear();
      _emailSecondsLeft = 180;
    });
    _emailTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_emailSecondsLeft <= 0) {
        t.cancel();
        return;
      }
      setState(() => _emailSecondsLeft--);
    });
    _showSnack('이메일로 인증 코드를 보냈어요 (데모: 아무 6자리)');
  }

  void _verifyEmailCode() {
    if (_emailSecondsLeft <= 0) {
      setState(() => _emailError = '인증 시간이 만료되었어요');
      return;
    }
    if (_emailCodeController.text.length != 6) {
      setState(() => _emailError = '6자리 코드를 입력해주세요');
      return;
    }
    _emailTimer?.cancel();
    setState(() {
      _emailVerified = true;
      _emailError = null;
    });
    _showSnack('이메일 인증이 완료되었어요');
  }

  void _sendPhoneCode() {
    if (!_phoneRegex.hasMatch(_phoneController.text.trim())) {
      setState(() => _phoneError = '올바른 휴대폰 번호를 입력해주세요');
      return;
    }
    _phoneTimer?.cancel();
    setState(() {
      _phoneError = null;
      _phoneCodeSent = true;
      _phoneVerified = false;
      _phoneCodeController.clear();
      _phoneSecondsLeft = 180;
    });
    _phoneTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_phoneSecondsLeft <= 0) {
        t.cancel();
        return;
      }
      setState(() => _phoneSecondsLeft--);
    });
    _showSnack('문자로 인증 코드를 보냈어요 (데모: 아무 6자리)');
  }

  void _verifyPhoneCode() {
    if (_phoneSecondsLeft <= 0) {
      setState(() => _phoneError = '인증 시간이 만료되었어요');
      return;
    }
    if (_phoneCodeController.text.length != 6) {
      setState(() => _phoneError = '6자리 코드를 입력해주세요');
      return;
    }
    _phoneTimer?.cancel();
    setState(() {
      _phoneVerified = true;
      _phoneError = null;
    });
    _showSnack('휴대폰 인증이 완료되었어요');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: GamJabiApp.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _validateAndSubmit() {
    setState(() {
      _nameError = _nameController.text.trim().length < 2
          ? '이름은 2자 이상 입력해주세요'
          : null;
      _pwError = _pwController.text.length < 8
          ? '비밀번호는 8자 이상이어야 해요'
          : (!_specialRegex.hasMatch(_pwController.text)
              ? '특수문자를 하나 이상 포함해주세요'
              : null);
      _pwConfirmError = _pwController.text != _pwConfirmController.text
          ? '비밀번호가 일치하지 않아요'
          : null;
    });

    if (!_emailVerified) {
      _showSnack('이메일 인증을 완료해주세요');
      return;
    }
    if (!_phoneVerified) {
      _showSnack('휴대폰 인증을 완료해주세요');
      return;
    }
    if (_nameError != null || _pwError != null || _pwConfirmError != null) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            SignupCompleteScreen(name: _nameController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            const SignupProgress(currentStep: 2),
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
                    _buildField(
                      label: '이름',
                      hint: '실명을 입력해주세요',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      errorText: _nameError,
                    ),
                    const SizedBox(height: 18),
                    _buildEmailSection(),
                    const SizedBox(height: 18),
                    _buildPhoneSection(),
                    const SizedBox(height: 18),
                    _buildPasswordField(
                      label: '비밀번호',
                      hint: '영문+숫자+특수문자 8자 이상',
                      controller: _pwController,
                      obscure: _obscurePw,
                      onToggle: () => setState(() => _obscurePw = !_obscurePw),
                      errorText: _pwError,
                    ),
                    const SizedBox(height: 18),
                    _buildPasswordField(
                      label: '비밀번호 확인',
                      hint: '비밀번호를 다시 입력해주세요',
                      controller: _pwConfirmController,
                      obscure: _obscurePwConfirm,
                      onToggle: () => setState(
                          () => _obscurePwConfirm = !_obscurePwConfirm),
                      errorText: _pwConfirmError,
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordHint(),
                    const SizedBox(height: 16),
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
        '회원가입',
        style: TextStyle(
          color: GamJabiApp.textDark,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기본 정보를 입력해주세요',
          style: TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '이메일과 휴대폰 인증이 필요해요',
          style: TextStyle(
            color: GamJabiApp.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSection() {
    final emailFormatOk =
        _emailRegex.hasMatch(_emailController.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('이메일', verified: _emailVerified),
        const SizedBox(height: 8),
        _inputBox(
          controller: _emailController,
          hint: 'example@gamjabi.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          hasError: _emailError != null,
          enabled: !_emailVerified,
          suffix: _emailVerified
              ? null
              : _inlineActionButton(
                  label: _emailCodeSent ? '재전송' : '인증',
                  enabled: emailFormatOk,
                  onTap: _sendEmailCode,
                ),
        ),
        if (_emailCodeSent && !_emailVerified) ...[
          const SizedBox(height: 10),
          _codeInputBox(
            controller: _emailCodeController,
            hint: '6자리 인증 코드',
            secondsLeft: _emailSecondsLeft,
            suffix: _inlineActionButton(
              label: '확인',
              enabled: _emailCodeController.text.length == 6 &&
                  _emailSecondsLeft > 0,
              onTap: _verifyEmailCode,
            ),
          ),
        ],
        if (_emailError != null) _errorText(_emailError!),
      ],
    );
  }

  Widget _buildPhoneSection() {
    final phoneFormatOk =
        _phoneRegex.hasMatch(_phoneController.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('휴대폰 번호', verified: _phoneVerified),
        const SizedBox(height: 8),
        _inputBox(
          controller: _phoneController,
          hint: '01012345678',
          icon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          hasError: _phoneError != null,
          enabled: !_phoneVerified,
          suffix: _phoneVerified
              ? null
              : _inlineActionButton(
                  label: _phoneCodeSent ? '재전송' : '인증',
                  enabled: phoneFormatOk,
                  onTap: _sendPhoneCode,
                ),
        ),
        if (_phoneCodeSent && !_phoneVerified) ...[
          const SizedBox(height: 10),
          _codeInputBox(
            controller: _phoneCodeController,
            hint: '6자리 인증 코드',
            secondsLeft: _phoneSecondsLeft,
            suffix: _inlineActionButton(
              label: '확인',
              enabled: _phoneCodeController.text.length == 6 &&
                  _phoneSecondsLeft > 0,
              onTap: _verifyPhoneCode,
            ),
          ),
        ],
        if (_phoneError != null) _errorText(_phoneError!),
      ],
    );
  }

  Widget _fieldLabel(String text, {bool verified = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (verified) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: GamJabiApp.softBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_rounded,
                      size: 12, color: GamJabiApp.primaryBlue),
                  SizedBox(width: 3),
                  Text(
                    '인증 완료',
                    style: TextStyle(
                      color: GamJabiApp.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool hasError = false,
    bool enabled = true,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              hasError ? const Color(0xFFE53935) : const Color(0xFFE4E9F2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: GamJabiApp.textMuted, size: 20),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
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
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: suffix,
            ),
        ],
      ),
    );
  }

  Widget _inlineActionButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color:
                enabled ? GamJabiApp.primaryBlue : const Color(0xFFCED4DE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _codeInputBox({
    required TextEditingController controller,
    required String hint,
    required int secondsLeft,
    Widget? suffix,
  }) {
    final expired = secondsLeft <= 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: expired
              ? const Color(0xFFE53935).withOpacity(0.4)
              : GamJabiApp.primaryBlue.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.pin_rounded,
            color: GamJabiApp.primaryBlue,
            size: 20,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: GamJabiApp.textDark,
                fontSize: 15,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: GamJabiApp.textMuted,
                  fontSize: 14,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 8),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: suffix == null ? 14 : 8),
            child: Text(
              expired ? '만료' : _formatTime(secondsLeft),
              style: TextStyle(
                color: expired
                    ? const Color(0xFFE53935)
                    : GamJabiApp.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: suffix,
            ),
        ],
      ),
    );
  }

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE53935),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        _inputBox(
          controller: controller,
          hint: hint,
          icon: icon,
          keyboardType: keyboardType,
          hasError: errorText != null,
        ),
        if (errorText != null) _errorText(errorText),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFE53935)
                  : const Color(0xFFE4E9F2),
            ),
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
        ),
        if (hasError) _errorText(errorText),
      ],
    );
  }

  Widget _buildPasswordHint() {
    final hints = [
      _HintItem('8자 이상', _pwController.text.length >= 8),
      _HintItem(
        '특수문자 1개 이상 포함',
        _specialRegex.hasMatch(_pwController.text),
      ),
      _HintItem(
        '비밀번호 일치',
        _pwController.text.isNotEmpty &&
            _pwController.text == _pwConfirmController.text,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GamJabiApp.softBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hints
            .map(
              (h) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      h.ok
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: h.ok
                          ? GamJabiApp.primaryBlue
                          : GamJabiApp.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      h.text,
                      style: TextStyle(
                        color: h.ok
                            ? GamJabiApp.primaryBlue
                            : GamJabiApp.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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
          onPressed: _canProceed ? _validateAndSubmit : null,
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
            '가입 완료',
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

class _HintItem {
  final String text;
  final bool ok;
  _HintItem(this.text, this.ok);
}
