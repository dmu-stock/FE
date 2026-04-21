import 'package:flutter/material.dart';
import '../main.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GamJabiApp.backgroundWhite,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: GamJabiApp.softBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  color: GamJabiApp.primaryBlue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: GamJabiApp.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: GamJabiApp.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
