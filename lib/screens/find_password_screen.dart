import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../widgets/signup_progress.dart';
import 'verify_code_screen.dart';

enum FindMethod { email, phone }

class FindPasswordScreen extends StatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  State<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  FindMethod _method = FindMethod.email;
  String? _error;

  final RegExp _emailRegex = RegExp(r'^[\w.\-]+@[\w\-]+\.[\w.\-]+$');
  final RegExp _phoneRegex = RegExp(r'^01[0-9]{8,9}$');

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_method == FindMethod.email) {
      return _emailRegex.hasMatch(_emailController.text.trim());
    }
    return _phoneRegex.hasMatch(_phoneController.text.trim());
  }

  void _sendCode() {
    if (!_canProceed) {
      setState(() {
        _error = _method == FindMethod.email
            ? '올바른 이메일 형식을 입력해주세요'
            : '올바른 휴대폰 번호를 입력해주세요';
      });
      return;
    }
    setState(() => _error = null);
    final destination = _method == FindMethod.email
        ? _emailController.text.trim()
        : _phoneController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyCodeScreen(
          destination: destination,
          method: _method,
        ),
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
            const SignupProgress(currentStep: 1, totalSteps: 3),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildIcon(),
                    const SizedBox(height: 24),
                    _buildTitle(),
                    const SizedBox(height: 24),
                    _buildMethodSelector(),
                    const SizedBox(height: 20),
                    _buildInputField(),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 6),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildNotice(),
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

  Widget _buildIcon() {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: GamJabiApp.softBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.lock_reset_rounded,
          color: GamJabiApp.primaryBlue,
          size: 34,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '어떻게 찾으시겠어요?',
          style: TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '가입 시 입력한 이메일 또는 휴대폰 번호로\n인증 코드를 보내드려요',
          style: TextStyle(
            color: GamJabiApp.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _methodTab(
              label: '이메일',
              icon: Icons.mail_outline_rounded,
              selected: _method == FindMethod.email,
              onTap: () => setState(() {
                _method = FindMethod.email;
                _error = null;
              }),
            ),
          ),
          Expanded(
            child: _methodTab(
              label: '휴대폰 번호',
              icon: Icons.phone_iphone_rounded,
              selected: _method == FindMethod.phone,
              onTap: () => setState(() {
                _method = FindMethod.phone;
                _error = null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? GamJabiApp.primaryBlue : GamJabiApp.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? GamJabiApp.primaryBlue
                    : GamJabiApp.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    final isEmail = _method == FindMethod.email;
    final hasError = _error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            isEmail ? '가입한 이메일' : '가입한 휴대폰 번호',
            style: const TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
            controller: isEmail ? _emailController : _phoneController,
            keyboardType:
                isEmail ? TextInputType.emailAddress : TextInputType.phone,
            inputFormatters: isEmail
                ? null
                : [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
            style: const TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: isEmail ? 'example@gamjabi.com' : '01012345678',
              hintStyle: TextStyle(
                color: GamJabiApp.textMuted,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                isEmail
                    ? Icons.mail_outline_rounded
                    : Icons.phone_iphone_rounded,
                color: GamJabiApp.textMuted,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GamJabiApp.softBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: GamJabiApp.primaryBlue,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '가입 시 입력한 정보가 기억나지 않으면\n고객센터로 문의해주세요.',
              style: TextStyle(
                color: GamJabiApp.primaryBlue.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
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
          onPressed: _canProceed ? _sendCode : null,
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
            '인증 코드 받기',
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
