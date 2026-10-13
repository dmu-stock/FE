import 'package:flutter/material.dart';
import '../core/format.dart';
import '../main.dart';
import '../models/watchlist_item.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/async_view.dart';
import '../widgets/cold_start_banner.dart';
import '../widgets/skeleton_box.dart';
import 'analysis_detail_sheet.dart';
import 'login_screen.dart';

/// Portfolio overview backed by `/members/{userKey}/watchlist`.
///
/// Stateful rather than a `FutureBuilder`: [MainScaffold] keeps every tab
/// mounted in an `IndexedStack`, so a one-shot future would never notice a
/// stock added from the 등록 tab. Subscribing to [AppState] does.
class HomeScreen extends StatefulWidget {
  final VoidCallback? onRegisterTap;

  const HomeScreen({super.key, this.onRegisterTap});

  static const Color positiveRed = Color(0xFFE53935);
  static const Color negativeBlue = Color(0xFF1E88E5);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// How the 보유 종목 list is ordered.
enum HoldingSort {
  added('등록순'),
  value('금액순'),
  returnPct('수익률순'),
  ticker('이름순');

  const HoldingSort(this.label);
  final String label;
}

class _HomeScreenState extends State<HomeScreen> {
  bool _requested = false;
  HoldingSort _sort = HoldingSort.added;

  List<WatchlistItem> _sorted(List<WatchlistItem> items) {
    final list = [...items];
    switch (_sort) {
      case HoldingSort.added:
        break; // server already returns newest first
      case HoldingSort.value:
        list.sort((a, b) => (b.value ?? b.cost).compareTo(a.value ?? a.cost));
      case HoldingSort.returnPct:
        // Unpriced rows sink to the bottom rather than sorting as 0%.
        list.sort((a, b) {
          final ar = a.returnPct;
          final br = b.returnPct;
          if (ar == null && br == null) return 0;
          if (ar == null) return 1;
          if (br == null) return -1;
          return br.compareTo(ar);
        });
      case HoldingSort.ticker:
        list.sort((a, b) => a.ticker.compareTo(b.ticker));
    }
    return list;
  }

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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                const ColdStartBanner(margin: EdgeInsets.only(bottom: 12)),
                _buildSummaryCards(state),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _buildSectionTitle('보유 종목'),
                    const SizedBox(width: 8),
                    if (state.pricesLoading)
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: GamJabiApp.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AsyncView<List<WatchlistItem>>(
                  value: state.watchlist,
                  loading: Column(
                    children: List.generate(
                      3,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: SkeletonBox(height: 74, radius: 16),
                      ),
                    ),
                  ),
                  isEmpty: (items) => items.isEmpty,
                  emptyIcon: Icons.account_balance_wallet_rounded,
                  emptyTitle: '아직 등록한 자산이 없어요',
                  emptyDescription: '등록 탭에서 보유한 미국 주식을 추가하면\n여기에서 한눈에 볼 수 있어요.',
                  emptyAction: _buildRegisterButton(),
                  onRetry: () => state.refreshWatchlist(force: true),
                  builder: (context, items) => Column(
                    children: [
                      if (items.length > 1) ...[
                        _buildSortBar(),
                        const SizedBox(height: 10),
                      ],
                      ..._sorted(items).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildHoldingCard(item),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildRegisterButton(),
                    ],
                  ),
                ),
              ],
            ),
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
            border: Border.all(
              color: GamJabiApp.primaryBlue.withValues(alpha: 0.15),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.login_rounded,
                color: GamJabiApp.primaryBlue,
                size: 16,
              ),
              SizedBox(width: 6),
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

  Widget _buildSummaryCards(AppState state) {
    // Natural heights. Both cards carry the same three rows, so they line up
    // without IntrinsicHeight — which miscomputes here because the left card
    // holds a Flexible, and overflowed by 4px as a result.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildTotalAssetCard(state)),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildHoldingCountCard(state)),
      ],
    );
  }

  Widget _buildTotalAssetCard(AppState state) {
    // Cost basis is known offline, so it shows immediately. Market value needs
    // one slow /predict per ticker and fills in behind it.
    // A partial sum shown as '평가 금액' would simply be a wrong number, so the
    // card stays on cost basis until every holding has a price.
    final bool hasValue = state.allPricesLoaded && state.totalValue != null;
    final value = state.totalValue;
    final returnPct = hasValue ? state.totalReturnPct : null;

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
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasValue ? '평가 금액' : '총 매입금액',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            formatUsd(hasValue ? value! : state.totalCost),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          if (returnPct != null)
            Row(
              children: [
                Icon(
                  returnPct >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${formatPercent(returnPct)} · 매입 '
                    '${formatUsd(state.totalCost)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              state.holdingCount == 0
                  ? '등록된 종목이 없어요'
                  : (state.pricesLoading ? '현재가 불러오는 중…' : '매입가 기준'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHoldingCountCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E9F2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
          Text(
            '${state.holdingCount}종목',
            style: const TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '미국 주식',
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

  Widget _buildHoldingCard(WatchlistItem item) {
    final returnPct = item.returnPct;
    // Korean convention: gains red, losses blue.
    final color = (returnPct ?? 0) >= 0
        ? HomeScreen.positiveRed
        : HomeScreen.negativeBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAnalysis(item.ticker),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E9F2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                  item.initial,
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
                      item.ticker,
                      style: const TextStyle(
                        color: GamJabiApp.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatShares(item.quantity)}주 · 평균 '
                      '${formatUsd(item.avgBuyPrice)}',
                      style: TextStyle(
                        color: GamJabiApp.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (returnPct == null)
                // Price still in flight, or this ticker is outside the backend's
                // coverage — either way the row stays readable.
                const SkeletonBox(height: 26, width: 58, radius: 10)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        formatPercent(returnPct),
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatUsd(item.value ?? 0),
                      style: const TextStyle(
                        color: GamJabiApp.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: GamJabiApp.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortBar() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: HoldingSort.values.map((s) {
          final selected = _sort == s;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: GestureDetector(
              onTap: () => setState(() => _sort = s),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected ? GamJabiApp.softBlue : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? GamJabiApp.primaryBlue.withValues(alpha: 0.25)
                        : const Color(0xFFE4E9F2),
                  ),
                ),
                child: Text(
                  s.label,
                  style: TextStyle(
                    color: selected
                        ? GamJabiApp.primaryBlue
                        : GamJabiApp.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Opens the same analysis sheet the 분석 tab uses, for the tapped ticker.
  void _openAnalysis(String ticker) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnalysisDetailSheet(ticker: ticker),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onRegisterTap,
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
