import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  static const deep = Color(0xFF07110F);
  static const panel = Color(0xFF0D1F1B);
  static const glass = Color(0x1FFFFFFF);
  static const emerald = Color(0xFF0E7C66);
  static const mint = Color(0xFF58D6B0);
  static const gold = Color(0xFFE7C568);
  static const danger = Color(0xFFFF5C7A);
  static const text = Color(0xFFF3FBF8);
  static const muted = Color(0xFF95AAA4);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: deep,
      colorScheme: const ColorScheme.dark(
        primary: emerald,
        secondary: gold,
        surface: panel,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(.10)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      cardTheme: CardTheme(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
