import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/async_value.dart';
import '../main.dart';

/// Renders the four states of an [AsyncValue] with the app's own visual
/// language, so five screens don't each re-invent loading/error/empty.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.loading,
    this.loadingLabel,
    this.isEmpty,
    this.emptyTitle,
    this.emptyDescription,
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyAction,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;

  /// Preferred over a spinner where the final layout is known — pass a stack of
  /// [SkeletonBox]es shaped like the content.
  final Widget? loading;
  final String? loadingLabel;

  final bool Function(T data)? isEmpty;
  final String? emptyTitle;
  final String? emptyDescription;
  final IconData emptyIcon;
  final Widget? emptyAction;

  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (value) {
      case AsyncIdle<T>():
        return loading ?? _spinner(null);
      case AsyncLoading<T>(:final label):
        return loading ?? _spinner(label ?? loadingLabel);
      case AsyncError<T>(:final error):
        return _error(context, error);
      case AsyncData<T>(value: final data):
        if (isEmpty?.call(data) ?? false) return _empty(context);
        return builder(context, data);
    }
  }

  Widget _spinner(String? label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: GamJabiApp.primaryBlue,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GamJabiApp.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _error(BuildContext context, ApiException error) {
    final waking = error is ServerWakingException;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E9F2)),
      ),
      child: Column(
        children: [
          Icon(
            waking ? Icons.bedtime_rounded : Icons.cloud_off_rounded,
            size: 28,
            color: GamJabiApp.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            error.userMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GamJabiApp.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => onRetry!(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('다시 시도'),
              style: OutlinedButton.styleFrom(
                foregroundColor: GamJabiApp.primaryBlue,
                side: BorderSide(
                  color: GamJabiApp.primaryBlue.withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: GamJabiApp.softBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(emptyIcon, color: GamJabiApp.primaryBlue, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          emptyTitle ?? '표시할 내용이 없어요',
          style: const TextStyle(
            color: GamJabiApp.textDark,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (emptyDescription != null) ...[
          const SizedBox(height: 8),
          Text(
            emptyDescription!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GamJabiApp.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
        if (emptyAction != null) ...[const SizedBox(height: 16), emptyAction!],
      ],
    ),
  );
}
