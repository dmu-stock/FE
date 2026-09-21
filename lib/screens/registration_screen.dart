import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_exception.dart';
import '../core/format.dart';
import '../main.dart';
import '../models/watchlist_item.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/async_view.dart';
import '../widgets/cold_start_banner.dart';
import '../widgets/skeleton_box.dart';

/// Registers holdings against `/members/{userKey}/watchlist`.
///
/// The form mirrors the server exactly — ticker, quantity, average buy price —
/// because those are the only three fields the API stores. The original
/// 종목명 / 자산 구분 / 관리 기준 / 메모 inputs had nowhere to go.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tickerController = TextEditingController();
  final _sharesController = TextEditingController();
  final _priceController = TextEditingController();

  bool _submitting = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    // refreshWatchlist() notifies synchronously, but didChangeDependencies runs
    // during build, where marking an ancestor dirty is illegal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).refreshWatchlist();
    });
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _sharesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final state = AppScope.read(context);
    final ticker = _tickerController.text.trim().toUpperCase();

    setState(() => _submitting = true);
    try {
      await state.addHolding(
        ticker: ticker,
        quantity: double.parse(_sharesController.text.trim()),
        avgBuyPrice: double.parse(_priceController.text.trim()),
      );
      if (!mounted) return;
      _tickerController.clear();
      _sharesController.clear();
      _priceController.clear();
      _formKey.currentState!.reset();
      _snack(
        state.lastAddWasUpdate
            ? '$ticker은(는) 이미 등록돼 있어 수량·평단가를 갱신했어요.'
            : '$ticker을(를) 포트폴리오에 등록했습니다.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.userMessage, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(WatchlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('종목 삭제'),
        content: Text('${item.ticker}을(를) 포트폴리오에서 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final state = AppScope.read(context);
    try {
      await state.removeHolding(item.ticker);
      if (mounted) _snack('${item.ticker}을(를) 삭제했어요.');
    } on ApiException catch (e) {
      if (mounted) _snack(e.userMessage, error: true);
    }
  }

  Future<void> _edit(WatchlistItem item) async {
    final sharesController = TextEditingController(
      text: formatShares(item.quantity),
    );
    final priceController = TextEditingController(
      text: item.avgBuyPrice.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.ticker} 수정',
                style: const TextStyle(
                  color: GamJabiApp.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: sharesController,
                      label: '보유 수량',
                      hint: '4',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberField(
                      controller: priceController,
                      label: '평균 단가 (USD)',
                      hint: '219.34',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(ctx).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GamJabiApp.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final quantity = double.tryParse(sharesController.text.trim());
    final price = double.tryParse(priceController.text.trim());
    sharesController.dispose();
    priceController.dispose();

    if (saved != true || !mounted || quantity == null || price == null) return;

    final state = AppScope.read(context);
    try {
      await state.updateHolding(
        item.ticker,
        quantity: quantity,
        avgBuyPrice: price,
      );
      if (mounted) _snack('${item.ticker} 정보를 수정했어요.');
    } on ApiException catch (e) {
      if (mounted) _snack(e.userMessage, error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFE53935) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: GamJabiApp.primaryBlue,
          onRefresh: () => state.refreshWatchlist(force: true),
          child: SingleChildScrollView(
            // Every tab stays mounted in the IndexedStack; without this they all
            // attach to the PrimaryScrollController and scroll actions break.
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 14),
                const ColdStartBanner(margin: EdgeInsets.only(bottom: 12)),
                _buildSummary(state),
                const SizedBox(height: 18),
                _buildFormCard(),
                const SizedBox(height: 22),
                _buildPortfolioHeader(),
                const SizedBox(height: 12),
                AsyncView<List<WatchlistItem>>(
                  value: state.watchlist,
                  loading: Column(
                    children: List.generate(
                      2,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: SkeletonBox(height: 84, radius: 16),
                      ),
                    ),
                  ),
                  isEmpty: (items) => items.isEmpty,
                  emptyIcon: Icons.add_chart_rounded,
                  emptyTitle: '등록된 종목이 없어요',
                  emptyDescription: '위 양식에서 티커·수량·평단가를 입력해\n첫 종목을 추가해보세요.',
                  onRetry: () => state.refreshWatchlist(force: true),
                  builder: (context, items) => Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildAssetCard(item),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
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
                '보유한 미국 주식을 추가하면 홈에서 함께 관리돼요',
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

  Widget _buildSummary(AppState state) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.account_balance_wallet_rounded,
            label: '총 매입금액',
            value: formatUsd(state.totalCost),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.pie_chart_rounded,
            label: '등록 종목',
            value: '${state.holdingCount}개',
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
            const SizedBox(height: 6),
            const Text(
              'AI 분석은 미국 주식만 지원해요 (예: NVDA, AAPL, MSFT)',
              style: TextStyle(
                color: GamJabiApp.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tickerController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                UpperCaseFormatter(),
                LengthLimitingTextInputFormatter(7),
              ],
              style: const TextStyle(
                color: GamJabiApp.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: _fieldDecoration(label: '티커', hint: 'NVDA'),
              validator: (value) {
                final text = (value ?? '').trim().toUpperCase();
                if (text.isEmpty) return '티커를 입력하세요';
                if (!RegExp(r'^[A-Z][A-Z.\-]{0,6}$').hasMatch(text)) {
                  return '영문 티커를 입력하세요 (예: NVDA)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _sharesController,
                    label: '보유 수량',
                    hint: '4',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberField(
                    controller: _priceController,
                    label: '평균 단가 (USD)',
                    hint: '219.34',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  _submitting ? '등록 중…' : '포트폴리오에 등록',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GamJabiApp.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: GamJabiApp.primaryBlue.withValues(
                    alpha: 0.5,
                  ),
                  disabledForegroundColor: Colors.white70,
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
          '최근 등록순',
          style: TextStyle(
            color: GamJabiApp.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(WatchlistItem item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
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
              item.initial,
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
                        item.ticker,
                        style: const TextStyle(
                          color: GamJabiApp.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      formatUsd(item.cost),
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
                  '${formatShares(item.quantity)}주 · 평균 '
                  '${formatUsd(item.avgBuyPrice)}',
                  style: const TextStyle(
                    color: GamJabiApp.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: GamJabiApp.textMuted,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              if (value == 'edit') _edit(item);
              if (value == 'delete') _delete(item);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(
                value: 'delete',
                child: Text('삭제', style: TextStyle(color: Color(0xFFE53935))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
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
      borderSide: const BorderSide(color: GamJabiApp.primaryBlue, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );
}

/// Decimal-accepting number field.
///
/// The API types quantity and avg_buy_price as `number`, so the old
/// `int.tryParse` validator wrongly rejected prices like `219.34`.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(
        color: GamJabiApp.textDark,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: _fieldDecoration(label: label, hint: hint),
      validator: (value) {
        final text = (value ?? '').trim();
        if (text.isEmpty) return '$label을(를) 입력하세요';
        final number = double.tryParse(text);
        if (number == null || number <= 0) return '0보다 큰 숫자를 입력하세요';
        return null;
      },
    );
  }
}

/// Keeps the ticker field uppercase as the user types.
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => TextEditingValue(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}
