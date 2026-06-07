import 'package:flutter/material.dart';
import '../main.dart';
import '../models/holding.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onRegisterTap;

  const HomeScreen({super.key, this.onRegisterTap});

  static const List<Holding> _holdings = [
    Holding(name: '삼성전자', code: '005930', shares: 20, changePercent: 3.1),
    Holding(name: 'SK하이닉스', code: '000660', shares: 8, changePercent: 1.4),
    Holding(name: 'NAVER', code: '035420', shares: 5, changePercent: -0.9),
  ];

  static const Color positiveRed = Color(0xFFE53935);
  static const Color negativeBlue = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildSummaryCards(),
              const SizedBox(height: 28),
              _buildSectionTitle('보유 종목'),
              const SizedBox(height: 12),
              ..._holdings.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildHoldingCard(h),
                ),
              ),
              const SizedBox(height: 20),
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GamJabi 🥔',
                style: TextStyle(
                  color: GamJabiApp.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '총 자산과 보유 종목 현황을 한 화면에서 확인해요',
                style: TextStyle(
                  color: GamJabiApp.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildLoginButton(context),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/login'),
              builder: (_) => const LoginScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: GamJabiApp.softBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GamJabiApp.primaryBlue.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.login_rounded,
                size: 15,
                color: GamJabiApp.primaryBlue,
              ),
              SizedBox(width: 5),
              Text(
                '로그인',
                style: TextStyle(
                  color: GamJabiApp.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildTotalAssetCard()),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildHoldingCountCard()),
      ],
    );
  }

  Widget _buildTotalAssetCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F86FF), Color(0xFF2F6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: GamJabiApp.primaryBlue.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '총 자산',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '₩28,640,000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                '2.31% 오늘',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingCountCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E9F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GamJabiApp.softBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: GamJabiApp.primaryBlue,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '보유 종목',
                style: TextStyle(
                  color: GamJabiApp.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '4종목',
            style: TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '국내 주식',
            style: TextStyle(
              color: GamJabiApp.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: GamJabiApp.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildHoldingCard(Holding h) {
    final isPositive = h.changePercent >= 0;
    final color = isPositive ? positiveRed : negativeBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: GamJabiApp.softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              h.name.substring(0, 1),
              style: const TextStyle(
                color: GamJabiApp.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.name,
                  style: const TextStyle(
                    color: GamJabiApp.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${h.code} · ${h.shares}주 보유',
                  style: TextStyle(
                    color: GamJabiApp.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${h.changePercent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onRegisterTap,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          '자산 등록하기',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: GamJabiApp.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
