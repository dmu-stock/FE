import 'package:flutter/material.dart';
import '../main.dart';

class SignupProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const SignupProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'STEP $currentStep',
                style: const TextStyle(
                  color: GamJabiApp.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ $totalSteps',
                style: TextStyle(
                  color: GamJabiApp.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(totalSteps, (i) {
              final active = i < currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active
                          ? GamJabiApp.primaryBlue
                          : const Color(0xFFE4E9F2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
