import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/signup_progress.dart';

class SignupCompleteScreen extends StatefulWidget {
  final String name;

  const SignupCompleteScreen({super.key, required this.name});

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const SignupProgress(currentStep: 3),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F86FF), Color(0xFF2F6BFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: GamJabiApp.primaryBlue.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        '${widget.name}님, 환영해요! 🎉',
                        style: const TextStyle(
                          color: GamJabiApp.textDark,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '가입이 완료되었어요.\n지금 바로 GamJabi의 똑똑한\n'
                        '주식 분석을 시작해보세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GamJabiApp.textMuted,
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GamJabiApp.softBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.auto_graph_rounded, 'AI 주가 예측 분석 제공'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.chat_bubble_rounded, '24시간 챗봇 투자 상담'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.notifications_active_rounded,
              '관심 종목 실시간 알림'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: GamJabiApp.primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: GamJabiApp.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'GamJabi 시작하기',
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
