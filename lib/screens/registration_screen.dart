import 'package:flutter/material.dart';
import '../main.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _sharesController = TextEditingController();
  final _priceController = TextEditingController();
  final _memoController = TextEditingController();

  String _assetType = '국내주식';
  String _strategy = '추천 종목';

  final List<_PortfolioAsset> _assets = [
    const _PortfolioAsset(
      type: '국내주식',
      name: '삼성전자',
      code: '005930',
      shares: 20,
      averagePrice: 72000,
      strategy: '장기 보유',
      memo: '반도체 회복 구간 확인',
    ),
    const _PortfolioAsset(
      type: '미국주식',
      name: 'NVIDIA',
      code: 'NVDA',
      shares: 4,
      averagePrice: 920,
      strategy: '추천 종목',
      memo: 'AI 수요 모멘텀',
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _sharesController.dispose();
    _priceController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _registerAsset() {
    if (!_formKey.currentState!.validate()) return;

    final asset = _PortfolioAsset(
      type: _assetType,
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      shares: int.parse(_sharesController.text.trim()),
      averagePrice: int.parse(_priceController.text.trim()),
      strategy: _strategy,
      memo: _memoController.text.trim(),
    );

    setState(() {
      _assets.insert(0, asset);
      _nameController.clear();
      _codeController.clear();
      _sharesController.clear();
      _priceController.clear();
      _memoController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${asset.name}을(를) 포트폴리오에 등록했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int get _totalValue => _assets.fold(0, (sum, asset) => sum + asset.value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildSummary(),
              const SizedBox(height: 18),
              _buildFormCard(),
              const SizedBox(height: 22),
              _buildPortfolioHeader(),
              const SizedBox(height: 12),
              ..._assets.map(
                (asset) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildAssetCard(asset),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: GamJabiApp.softBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.add_chart_rounded,
            color: GamJabiApp.primaryBlue,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '자산 등록',
                style: TextStyle(
                  color: GamJabiApp.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '보유 자산을 추가하고 포트폴리오 기준을 관리하세요',
                style: TextStyle(
                  color: GamJabiApp.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.account_balance_wallet_rounded,
            label: '평가 기준 금액',
            value: '${_formatCurrency(_totalValue)}원',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.pie_chart_rounded,
            label: '등록 자산',
            value: '${_assets.length}개',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: GamJabiApp.primaryBlue, size: 20),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: GamJabiApp.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E9F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '등록 정보',
              style: TextStyle(
                color: GamJabiApp.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _buildChoiceChips(
              label: '자산 구분',
              values: const ['국내주식', '미국주식', 'ETF'],
              selected: _assetType,
              onChanged: (value) => setState(() => _assetType = value),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nameController,
                    label: '종목명',
                    hint: '예: 삼성전자',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _codeController,
                    label: '종목코드',
                    hint: '005930',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _sharesController,
                    label: '보유 수량',
                    hint: '10',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: '평균 단가',
                    hint: '72000',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildChoiceChips(
              label: '관리 기준',
              values: const ['추천 종목', '장기 보유', '관심 관찰'],
              selected: _strategy,
              onChanged: (value) => setState(() => _strategy = value),
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _memoController,
              label: '메모',
              hint: '진입 근거 또는 리스크 메모',
              requiredField: false,
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _registerAsset,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  '포트폴리오에 등록',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GamJabiApp.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChips({
    required String label,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = selected == value;
            return ChoiceChip(
              label: Text(value),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
              showCheckmark: false,
              selectedColor: GamJabiApp.softBlue,
              backgroundColor: const Color(0xFFF4F6FB),
              labelStyle: TextStyle(
                color: isSelected
                    ? GamJabiApp.primaryBlue
                    : GamJabiApp.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide(
                color: isSelected
                    ? GamJabiApp.primaryBlue.withValues(alpha: 0.25)
                    : const Color(0xFFE4E9F2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool requiredField = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        color: GamJabiApp.textDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: GamJabiApp.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: GamJabiApp.textMuted, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF7F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE4E9F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE4E9F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: GamJabiApp.primaryBlue,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (requiredField && text.isEmpty) return '$label을(를) 입력하세요';
        if (keyboardType == TextInputType.number && text.isNotEmpty) {
          final number = int.tryParse(text);
          if (number == null || number <= 0) return '양수로 입력하세요';
        }
        return null;
      },
    );
  }

  Widget _buildPortfolioHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '포트폴리오',
            style: TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '등록순',
          style: TextStyle(
            color: GamJabiApp.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(_PortfolioAsset asset) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: GamJabiApp.softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              asset.initial,
              style: const TextStyle(
                color: GamJabiApp.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        asset.name,
                        style: const TextStyle(
                          color: GamJabiApp.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatCurrency(asset.value)}원',
                      style: const TextStyle(
                        color: GamJabiApp.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${asset.type} · ${asset.code} · ${asset.shares}주 · 평균 ${_formatCurrency(asset.averagePrice)}원',
                  style: const TextStyle(
                    color: GamJabiApp.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTag(asset.strategy, GamJabiApp.primaryBlue),
                    if (asset.memo.isNotEmpty)
                      _buildTag(asset.memo, const Color(0xFF22A06B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _formatCurrency(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class _PortfolioAsset {
  final String type;
  final String name;
  final String code;
  final int shares;
  final int averagePrice;
  final String strategy;
  final String memo;

  const _PortfolioAsset({
    required this.type,
    required this.name,
    required this.code,
    required this.shares,
    required this.averagePrice,
    required this.strategy,
    required this.memo,
  });

  int get value => shares * averagePrice;
  String get initial => name.isEmpty ? '?' : name.characters.first;
}
