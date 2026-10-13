import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/async_value.dart';
import '../core/format.dart';
import '../main.dart';
import '../models/prediction.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/async_view.dart';
import '../widgets/skeleton_box.dart';

/// Full analysis for one ticker, opened from the 분석 list.
///
/// The chart renders first because it returns in seconds; `/predict` is
/// LLM-backed and can take a minute, so it fills in underneath.
class AnalysisDetailSheet extends StatefulWidget {
  const AnalysisDetailSheet({super.key, required this.ticker});

  final String ticker;

  @override
  State<AnalysisDetailSheet> createState() => _AnalysisDetailSheetState();
}

class _AnalysisDetailSheetState extends State<AnalysisDetailSheet> {
  AsyncValue<Prediction> _prediction = const AsyncIdle();
  String _period = '6mo';
  bool _adding = false;

  /// Escalates the loading copy so a long wait doesn't look like a hang.
  Timer? _patienceTimer;
  bool _takingLong = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _patienceTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    final state = AppScope.read(context);
    setState(() {
      _prediction = const AsyncLoading('AI가 분석 중이에요…');
      _takingLong = false;
    });

    _patienceTimer?.cancel();
    _patienceTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _prediction.isLoading) {
        setState(() => _takingLong = true);
      }
    });

    try {
      final result = await state.predictService.predict(
        widget.ticker,
        useCache: !force,
      );
      if (!mounted) return;
      setState(() => _prediction = AsyncData(result));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _prediction = AsyncError(e));
    } finally {
      _patienceTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: GamJabiApp.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            _buildGrabber(),
            _buildHeader(),
            _buildActions(state),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  _buildChart(
                    state.marketService.chartUri(
                      widget.ticker,
                      period: _period,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPeriodChips(),
                  const SizedBox(height: 22),
                  AsyncView<Prediction>(
                    value: _prediction,
                    loading: _buildPredictionLoading(),
                    onRetry: () => _load(force: true),
                    builder: (context, p) => _buildPrediction(p),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrabber() => Container(
    margin: const EdgeInsets.only(top: 10, bottom: 6),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: const Color(0xFFE4E9F2),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
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
              widget.ticker.isEmpty ? '?' : widget.ticker[0],
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
                Text(
                  widget.ticker,
                  style: const TextStyle(
                    color: GamJabiApp.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '종합 분석',
                  style: TextStyle(
                    color: GamJabiApp.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: GamJabiApp.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Closes the discover → own loop: a ticker found in the signal list can be
  /// added here instead of being retyped in the 등록 tab.
  Widget _buildActions(AppState state) {
    final held = state.holds(widget.ticker);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: held
                ? OutlinedButton.icon(
                    onPressed: _adding ? null : _removeFromWatchlist,
                    icon: _adding
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 17),
                    label: const Text('보유 중'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF22A06B),
                      side: const BorderSide(color: Color(0xFF22A06B)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _adding ? null : _addToWatchlist,
                    icon: _adding
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded, size: 18),
                    label: const Text('내 종목에 추가'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GamJabiApp.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                AppScope.read(context).askChatAbout(widget.ticker);
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('챗봇에 묻기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GamJabiApp.primaryBlue,
                side: BorderSide(
                  color: GamJabiApp.primaryBlue.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToWatchlist() async {
    // The sheet knows the price but not how many shares the user owns, so it
    // registers a watch-only row (quantity 0) they can fill in from 등록.
    final state = AppScope.read(context);
    setState(() => _adding = true);
    try {
      await state.addHolding(ticker: widget.ticker);
      if (!mounted) return;
      _snack('${widget.ticker}을(를) 추가했어요. 등록 탭에서 수량을 입력해보세요.');
    } on ApiException catch (e) {
      if (mounted) _snack(e.userMessage, error: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _removeFromWatchlist() async {
    final state = AppScope.read(context);
    setState(() => _adding = true);
    try {
      await state.removeHolding(widget.ticker);
      if (!mounted) return;
      _snack('${widget.ticker}을(를) 내 종목에서 뺐어요.');
    } on ApiException catch (e) {
      if (mounted) _snack(e.userMessage, error: true);
    } finally {
      if (mounted) setState(() => _adding = false);
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

  Widget _buildChart(Uri uri) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.white,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Image.network(
            uri.toString(),
            key: ValueKey(uri.toString()),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: GamJabiApp.primaryBlue,
                  ),
                ),
              );
            },
            // /chart intermittently 404s with `x-error: no OHLCV` even for
            // tickers /predict handles fine, so this path is routine.
            errorBuilder: (context, error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.show_chart_rounded,
                    color: GamJabiApp.textMuted,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '차트를 불러오지 못했어요',
                    style: TextStyle(
                      color: GamJabiApp.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    const periods = ['3mo', '6mo', '1y', '2y'];
    return Wrap(
      spacing: 8,
      children: periods.map((p) {
        final selected = _period == p;
        return ChoiceChip(
          label: Text(p),
          selected: selected,
          onSelected: (_) => setState(() => _period = p),
          showCheckmark: false,
          selectedColor: GamJabiApp.softBlue,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? GamJabiApp.primaryBlue : GamJabiApp.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          side: BorderSide(
            color: selected
                ? GamJabiApp.primaryBlue.withValues(alpha: 0.25)
                : const Color(0xFFE4E9F2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPredictionLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: GamJabiApp.primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _takingLong ? '조금만 더 기다려 주세요 (최대 1분)' : 'AI가 분석 중이에요…',
                style: TextStyle(
                  color: GamJabiApp.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const SkeletonBox(height: 78, radius: 16),
        const SizedBox(height: 10),
        const SkeletonBox(height: 120, radius: 16),
      ],
    );
  }

  Widget _buildPrediction(Prediction p) {
    if (!p.ok) {
      return _card(
        child: Text(
          '${p.ticker}에 대한 분석 데이터를 만들지 못했어요.\n'
          'API가 다루는 미국 우량주 범위 밖일 수 있어요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: GamJabiApp.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      );
    }

    // Korean market convention: gains red, falls blue.
    final color = p.isUp ? const Color(0xFFE53935) : const Color(0xFF1E88E5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSignalCard(p, color),
        const SizedBox(height: 12),
        _buildPriceLadder(p),
        const SizedBox(height: 12),
        _buildIndicators(p),
        if (p.flags.isNotEmpty) ...[const SizedBox(height: 12), _buildFlags(p)],
        const SizedBox(height: 18),
        _sectionTitle('AI 코멘트'),
        const SizedBox(height: 10),
        _comment('한 줄 요약', p.say, Icons.chat_bubble_outline_rounded),
        _comment('분석', p.result, Icons.insights_rounded),
        _comment(
          '유의할 점',
          p.caution,
          Icons.warning_amber_rounded,
          accent: const Color(0xFFE8A33D),
        ),
        _comment(
          '상승 트리거',
          p.upsideTrigger,
          Icons.trending_up_rounded,
          accent: const Color(0xFF22A06B),
        ),
        if (p.llmReasoning.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildReasoning(p),
        ],
        const SizedBox(height: 14),
        _buildFooter(p),
      ],
    );
  }

  Widget _buildSignalCard(Prediction p, Color color) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      p.isUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      p.signal.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (p.currentPrice > 0)
                Text(
                  formatUsd(p.currentPrice),
                  style: const TextStyle(
                    color: GamJabiApp.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _stat('확률', '${p.probability * 100 ~/ 1}%')),
              Expanded(child: _stat('신뢰도', '${p.confidence * 100 ~/ 1}%')),
              Expanded(child: _stat('추세', p.trend)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceLadder(Prediction p) {
    final rows = <(String, double, Color)>[
      ('2차 저항', p.resistance2, const Color(0xFFE53935)),
      ('1차 저항', p.resistance1, const Color(0xFFEF6B6B)),
      ('현재가', p.currentPrice, GamJabiApp.primaryBlue),
      ('추천 매수', p.recommendedBuy, const Color(0xFF22A06B)),
      ('지지선', p.support, const Color(0xFF1E88E5)),
    ].where((r) => r.$2 > 0).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('가격 레벨'),
          const SizedBox(height: 10),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 15,
                    decoration: BoxDecoration(
                      color: r.$3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      r.$1,
                      style: TextStyle(
                        color: r.$1 == '현재가'
                            ? GamJabiApp.textDark
                            : GamJabiApp.textMuted,
                        fontSize: 12.5,
                        fontWeight: r.$1 == '현재가'
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formatUsd(r.$2),
                    style: TextStyle(
                      color: r.$1 == '현재가' ? r.$3 : GamJabiApp.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators(Prediction p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('기술 지표'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _stat('RSI(14)', p.rsi14.toStringAsFixed(1))),
              Expanded(child: _stat('SMA 5', formatUsd(p.sma5))),
              Expanded(child: _stat('SMA 20', formatUsd(p.sma20))),
              Expanded(child: _stat('SMA 60', formatUsd(p.sma60))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlags(Prediction p) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: p.flags
          .map(
            (f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: GamJabiApp.softBlue,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                f,
                style: const TextStyle(
                  color: GamJabiApp.primaryBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildReasoning(Prediction p) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4E9F2)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: const Text(
            'AI 판단 근거',
            style: TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                p.llmReasoning,
                style: const TextStyle(
                  color: GamJabiApp.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(Prediction p) {
    final parts = <String>[
      if (p.asOf.isNotEmpty) '기준일 ${p.asOf}',
      p.signalSource == 'llm_csv' ? 'LLM 판단' : '규칙 기반',
      p.nArticles == 0 ? '뉴스 없음 (지표만 반영)' : '뉴스 ${p.nArticles}건 반영',
    ];
    return Text(
      parts.join(' · '),
      style: TextStyle(
        color: GamJabiApp.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4E9F2)),
    ),
    child: child,
  );

  Widget _cardTitle(String text) => Text(
    text,
    style: const TextStyle(
      color: GamJabiApp.textDark,
      fontSize: 13,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      color: GamJabiApp.textDark,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
  );

  Widget _stat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          color: GamJabiApp.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: GamJabiApp.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _comment(
    String label,
    String body,
    IconData icon, {
    Color accent = GamJabiApp.primaryBlue,
  }) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              body,
              style: const TextStyle(
                color: GamJabiApp.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
