import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/signup_progress.dart';
import 'signup_info_screen.dart';

class _TermItem {
  final String title;
  final bool required;
  bool agreed;

  _TermItem({
    required this.title,
    required this.required,
    this.agreed = false,
  });
}

class SignupAgreementScreen extends StatefulWidget {
  const SignupAgreementScreen({super.key});

  @override
  State<SignupAgreementScreen> createState() => _SignupAgreementScreenState();
}

class _SignupAgreementScreenState extends State<SignupAgreementScreen> {
  final List<_TermItem> _terms = [
    _TermItem(title: '만 14세 이상입니다', required: true),
    _TermItem(title: '서비스 이용약관 동의', required: true),
    _TermItem(title: '개인정보 수집 및 이용 동의', required: true),
    _TermItem(title: '투자정보 제공 및 분석 활용 동의', required: true),
    _TermItem(title: '마케팅 정보 수신 동의', required: false),
  ];

  bool get _allAgreed => _terms.every((t) => t.agreed);
  bool get _canProceed => _terms.where((t) => t.required).every((t) => t.agreed);

  void _toggleAll(bool value) {
    setState(() {
      for (final t in _terms) {
        t.agreed = value;
      }
    });
  }

  void _toggle(int index) {
    setState(() => _terms[index].agreed = !_terms[index].agreed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            const SignupProgress(currentStep: 1),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildTitle(),
                    const SizedBox(height: 24),
                    _buildAllAgreeCard(),
                    const SizedBox(height: 12),
                    ..._terms.asMap().entries.map(
                          (e) => _buildTermRow(e.key, e.value),
                        ),
                    const SizedBox(height: 20),
                    _buildInfoNotice(),
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
          '약관에 동의해주세요',
          style: TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'GamJabi 가입을 위해 아래 약관 확인이 필요해요',
          style: TextStyle(
            color: GamJabiApp.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAllAgreeCard() {
    return InkWell(
      onTap: () => _toggleAll(!_allAgreed),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _allAgreed ? GamJabiApp.softBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _allAgreed
                ? GamJabiApp.primaryBlue.withOpacity(0.3)
                : const Color(0xFFE4E9F2),
            width: _allAgreed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _checkBox(_allAgreed, big: true),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '모든 약관에 동의합니다',
                style: TextStyle(
                  color: GamJabiApp.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermRow(int index, _TermItem term) {
    return InkWell(
      onTap: () => _toggle(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            _checkBox(term.agreed),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    term.required ? '[필수] ' : '[선택] ',
                    style: TextStyle(
                      color: term.required
                          ? GamJabiApp.primaryBlue
                          : GamJabiApp.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      term.title,
                      style: const TextStyle(
                        color: GamJabiApp.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showTermDetail(term.title),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '보기',
                style: TextStyle(
                  color: GamJabiApp.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkBox(bool checked, {bool big = false}) {
    final size = big ? 24.0 : 22.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? GamJabiApp.primaryBlue : Colors.transparent,
        border: Border.all(
          color: checked ? GamJabiApp.primaryBlue : const Color(0xFFCED4DE),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(big ? 8 : 7),
      ),
      child: checked
          ? Icon(Icons.check_rounded,
              size: big ? 16 : 15, color: Colors.white)
          : null,
    );
  }

  Widget _buildInfoNotice() {
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
              'GamJabi는 투자정보를 참고용으로 제공하며, '
              '최종 투자 결정은 사용자 본인의 판단과 책임에 따릅니다.',
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
          onPressed: _canProceed
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignupInfoScreen(),
                    ),
                  );
                }
              : null,
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
            '동의하고 계속하기',
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

  void _showTermDetail(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCED4DE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: GamJabiApp.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      color: GamJabiApp.textMuted,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEF1F7)),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '본 약관은 GamJabi 서비스 이용에 관한 기본 사항을 규정합니다.\n\n'
                    '1. 목적\n이 약관은 회사가 제공하는 주식 예측 및 포트폴리오 관리 '
                    '서비스의 이용조건 및 절차를 정함을 목적으로 합니다.\n\n'
                    '2. 수집 항목\n아이디, 비밀번호, 이메일, 관심 종목 정보, 투자 성향.\n\n'
                    '3. 수집 및 이용 목적\n서비스 제공, 맞춤 추천, 통계 분석.\n\n'
                    '4. 보유 기간\n회원 탈퇴 시까지 또는 관련 법령이 정한 기간까지.\n\n'
                    '5. 기타\n본 서비스는 투자 자문이 아닌 참고용 정보를 제공하며, '
                    '최종 투자 판단의 책임은 이용자에게 있습니다.',
                    style: TextStyle(
                      color: GamJabiApp.textDark,
                      fontSize: 13,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
