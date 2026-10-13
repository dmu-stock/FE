import 'package:flutter/material.dart';

import '../main.dart';
import '../state/app_scope.dart';

/// Shown while the client is waiting out a booting Render dyno.
///
/// The backend is on a free tier that sleeps, so the first request after an
/// idle period can take 30–60s. Saying so beats an unexplained spinner.
class ColdStartBanner extends StatelessWidget {
  const ColdStartBanner({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.isWarmingUp) return const SizedBox.shrink();

    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: GamJabiApp.softBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GamJabiApp.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bedtime_rounded,
            size: 18,
            color: GamJabiApp.primaryBlue,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '서버를 깨우는 중이에요 · 최대 1분 걸릴 수 있어요',
              style: TextStyle(
                color: GamJabiApp.primaryBlue,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: const LinearProgressIndicator(
                minHeight: 3,
                color: GamJabiApp.primaryBlue,
                backgroundColor: Color(0x332F6BFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
