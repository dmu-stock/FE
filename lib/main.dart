import 'package:flutter/material.dart';
import 'screens/main_scaffold.dart';

void main() {
  runApp(const GamJabiApp());
}

class GamJabiApp extends StatelessWidget {
  const GamJabiApp({super.key});

  static const Color primaryBlue = Color(0xFF2F6BFF);
  static const Color softBlue = Color(0xFFE8F0FF);
  static const Color backgroundWhite = Color(0xFFFAFBFF);
  static const Color textDark = Color(0xFF1A1F36);
  static const Color textMuted = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GamJabi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundWhite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: textDark, fontSize: 15),
          titleLarge: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: const MainScaffold(),
    );
  }
}
