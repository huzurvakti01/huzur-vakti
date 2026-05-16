import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const emerald = Color(0xFF0E7C66);
  static const deepEmerald = Color(0xFF063D35);
  static const gold = Color(0xFFE2B659);
  static const sand = Color(0xFFF7F1E7);
  static const pearl = Color(0xFFFEFCF7);
  static const ink = Color(0xFF101816);
  static const night = Color(0xFF06111F);
  static const nightBlue = Color(0xFF071A2E);
  static const mysticBlue = Color(0xFF102A43);
  static const glassWhite = Color(0x33FFFFFF);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: emerald,
      primary: emerald,
      secondary: gold,
      tertiary: const Color(0xFF76D7C4),
      surface: pearl,
      brightness: Brightness.light,
    );

    return base.copyWith(
      platform: TargetPlatform.iOS,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F1E7),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        titleTextStyle: GoogleFonts.inter(
          color: ink,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: -.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: pearl.withOpacity(.92),
        indicatorColor: emerald.withOpacity(.13),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: pearl.withOpacity(.88),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(.70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: ink.withOpacity(.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: ink.withOpacity(.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: emerald, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: emerald,
          side: BorderSide(color: emerald.withOpacity(.35)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: emerald,
      primary: const Color(0xFF65D8C1),
      secondary: gold,
      tertiary: const Color(0xFF92E4D3),
      surface: const Color(0xFF13221E),
      brightness: Brightness.dark,
    );

    return base.copyWith(
      platform: TargetPlatform.iOS,
      colorScheme: scheme,
      scaffoldBackgroundColor: night,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: -.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 74,
        backgroundColor: const Color(0xFF071A2E).withOpacity(.92),
        indicatorColor: gold.withOpacity(.18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            color: states.contains(WidgetState.selected) ? gold : Colors.white70,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? gold : Colors.white70,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF14231F).withOpacity(.88),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

class KidsTheme {
  const KidsTheme._();

  static const sky = Color(0xFF35A7FF);
  static const sun = Color(0xFFFFD447);
  static const orange = Color(0xFFFF8A3D);
  static const mint = Color(0xFF67E8C1);
  static const cream = Color(0xFFFFF7DF);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: sky,
      primary: sky,
      secondary: sun,
      tertiary: orange,
      surface: cream,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withOpacity(.92),
        indicatorColor: sun.withOpacity(.32),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF243047),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 21,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF243047),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  static ThemeData dark() => AppTheme.dark();
}
