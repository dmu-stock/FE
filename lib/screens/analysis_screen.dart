import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/async_value.dart';
import '../main.dart';
import '../models/signal.dart';
import '../state/app_scope.dart';
import '../widgets/async_view.dart';
import '../widgets/cold_start_banner.dart';
import '../widgets/skeleton_box.dart';
import 'analysis_detail_sheet.dart';

/// 분석 tab — the ML buy-signal list, plus per-ticker analysis on tap.
///
/// `/signal` is cheap so it loads up front; `/predict` costs 10–60s per
/// ticker, so it only runs when the user opens one.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  AsyncValue<SignalResponse> _signal = const AsyncIdle();
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load({bool force = false}) async {
    if (!force && _signal.hasData) return;
    final state = AppScope.read(context);
    setState(() => _signal = const AsyncLoading('오늘의 시그널을 불러오는 중…'));
    try {
      final result = await state.marketService.signal(topN: 5);
      if (!mounted) return;
      setState(() => _signal = AsyncData(result));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _signal = AsyncError(e));
    }
  }

  void _openDetail(String ticker) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnalysisDetailSheet(ticker: ticker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final holdings = AppScope.of(context).holdings;

    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: GamJabiApp.primaryBlue,
          onRefresh: () => _load(force: true),
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
                const SizedBox(height: 16),
                const ColdStartBanner(margin: EdgeInsets.only(bottom: 12)),
                AsyncView<SignalResponse>(
                  value: _signal,
                  loading: Column(
                    children: [
                      const SkeletonBox(height: 64, radius: 16),
                      const SizedBox(height: 12),
                      ...List.generate(
                        3,
                        (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: SkeletonBox(height: 72, radius: 16),
                        ),
                      ),
                    ],
                  ),
                  isEmpty: (s) => s.picks.isEmpty,
                  emptyIcon: Icons.insights_rounded,
                  emptyTitle: '시그널이 없어요',
                  emptyDescription: '오늘 계산된 매수 시그널이 없습니다.\n잠시 후 다시 확인해보세요.',
                  onRetry: () => _load(force: true),
                  builder: (context, s) => _buildSignal(s),
                ),
                const SizedBox(height: 26),
                _buildHoldingsSection(holdings.map((h) => h.ticker).toList()),
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
            Icons.insights_rounded,
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
                '분석',
                style: TextStyle(
                  color: GamJabiApp.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'AI 매수 시그널과 종목별 종합 분석을 확인해요',
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

  Widget _buildSignal(SignalResponse s) {
    // The server returns picks unsorted (observed: 0.5255, 0.5378, 0.5172,
    // 0.5291, 0.5130), so ranking them in arrival order would label the
    // wrong ticker #1.
    final picks = [...s.picks]
      ..sort((a, b) => b.finalProb.compareTo(a.finalProb));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(s),
        const SizedBox(height: 14),
        Row(
          children: [
            _sectionTitle('매수 시그널 Top ${picks.length}'),
            const Spacer(),
            Text(
              '탭하면 상세 분석',
              style: TextStyle(
                color: GamJabiApp.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...picks.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildPickCard(e.key + 1, e.value),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(SignalResponse s) {
    return Container(
      width: double.infinity,
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
            color: GamJabiApp.primaryBlue.withValues(alpha: 0.25),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ML 시그널',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VIX',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.vix.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (s.asOf.isNotEmpty) _buildAsOfBadge(s.asOf),
            ],
          ),
          if (s.reason.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              s.reason,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The signal CSV is refreshed manually and has run weeks behind, so the
  /// date is shown plainly and flagged once it is clearly stale.
  Widget _buildAsOfBadge(String asOf) {
    final date = DateTime.tryParse(asOf);
    final daysOld = date == null ? 0 : DateTime.now().difference(date).inDays;
    final stale = daysOld >= 7;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: stale ? 0.26 : 0.18),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stale ? Icons.history_rounded : Icons.event_available_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            stale ? '$asOf · $daysOld일 전 데이터' : '기준일 $asOf',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickCard(int rank, SignalPick pick) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(pick.ticker),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E9F2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? GamJabiApp.primaryBlue
                          : GamJabiApp.softBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank == 1
                            ? Colors.white
                            : GamJabiApp.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    pick.ticker,
                    style: const TextStyle(
                      color: GamJabiApp.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (pick.extra) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22A06B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '추가',
                        style: TextStyle(
                          color: Color(0xFF22A06B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${pick.finalPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: GamJabiApp.primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: GamJabiApp.textMuted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pick.barFraction,
                  minHeight: 5,
                  color: GamJabiApp.primaryBlue,
                  backgroundColor: const Color(0xFFF0F3FA),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  _miniStat('LGB', pick.probLgb),
                  const SizedBox(width: 14),
                  _miniStat('LSTM', pick.probLstm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, double value) => Text(
    '$label ${(value * 100).toStringAsFixed(1)}%',
    style: TextStyle(
      color: GamJabiApp.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _buildHoldingsSection(List<String> tickers) {
    if (tickers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('내 보유 종목 분석'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tickers
              .map(
                (t) => ActionChip(
                  label: Text(t),
                  onPressed: () => _openDetail(t),
                  backgroundColor: Colors.white,
                  labelStyle: const TextStyle(
                    color: GamJabiApp.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  side: const BorderSide(color: Color(0xFFE4E9F2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      color: GamJabiApp.textDark,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
  );
}
