import 'package:flutter/material.dart';
import '../main.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'placeholder_screen.dart';
import 'registration_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    HomeScreen(onRegisterTap: () => setState(() => _currentIndex = 4)),
    const PlaceholderScreen(
      title: '뉴스',
      icon: Icons.article_rounded,
      description: '관심 종목과 시장 소식을 한눈에 모아볼 수 있어요.',
    ),
    const PlaceholderScreen(
      title: '분석',
      icon: Icons.insights_rounded,
      description: '예측 모델 기반 종목 분석을 곧 제공합니다.',
    ),
    const ChatScreen(),
    const RegistrationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEEF1F7), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, '홈'),
              _buildNavItem(1, Icons.article_rounded, '뉴스'),
              _buildNavItem(2, Icons.insights_rounded, '분석'),
              _buildNavItem(3, Icons.chat_bubble_rounded, '채팅'),
              _buildNavItem(4, Icons.add_chart_rounded, '등록'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? GamJabiApp.softBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? GamJabiApp.primaryBlue
                      : GamJabiApp.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? GamJabiApp.primaryBlue
                      : GamJabiApp.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
