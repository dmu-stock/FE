import 'package:flutter/material.dart';
import '../main.dart';
import 'signup_agreement_screen.dart';
import 'find_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  bool _obscurePw = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              _buildLogo(),
              const SizedBox(height: 28),
              _buildTitle(),
              const SizedBox(height: 36),
              _buildLabel('아이디'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _idController,
                hint: '아이디 또는 이메일 입력',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 18),
              _buildLabel('비밀번호'),
              const SizedBox(height: 8),
              _buildPasswordField(),
              const SizedBox(height: 14),
              _buildOptionsRow(),
              const SizedBox(height: 28),
              _buildLoginButton(),
              const SizedBox(height: 28),
              _buildSignupRow(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F86FF), Color(0xFF2F6BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: GamJabiApp.primaryBlue.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_graph_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'GamJabi에 오신 걸 환영해요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '로그인하고 맞춤 포트폴리오를 받아보세요',
          textAlign: TextAlign.center,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: TextField(
        controller: controller,
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
          prefixIcon: Icon(icon, color: GamJabiApp.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: TextField(
        controller: _pwController,
        obscureText: _obscurePw,
        style: const TextStyle(
          color: GamJabiApp.textDark,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: '비밀번호 입력',
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
              _obscurePw
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: GamJabiApp.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePw = !_obscurePw),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _rememberMe
                        ? GamJabiApp.primaryBlue
                        : Colors.transparent,
                    border: Border.all(
                      color: _rememberMe
                          ? GamJabiApp.primaryBlue
                          : const Color(0xFFCED4DE),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _rememberMe
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                const Text(
                  '자동 로그인',
                  style: TextStyle(
                    color: GamJabiApp.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FindPasswordScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '비밀번호 찾기',
            style: TextStyle(
              color: GamJabiApp.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: GamJabiApp.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: GamJabiApp.primaryBlue.withOpacity(0.4),
        ),
        child: const Text(
          '로그인',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSignupRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '아직 계정이 없으신가요?',
          style: TextStyle(
            color: GamJabiApp.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SignupAgreementScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '회원가입',
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
}
