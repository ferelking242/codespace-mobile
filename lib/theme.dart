import 'package:flutter/material.dart';

class AppTheme {
  // DiohHub-inspired GitHub dark palette
  static const Color bg      = Color(0xFF010409);
  static const Color surface = Color(0xFF0D1117);
  static const Color card    = Color(0xFF161B22);
  static const Color border  = Color(0xFF21262D);
  static const Color accent  = Color(0xFF2F81F7);
  static const Color accentDim = Color(0xFF1F6FEB);
  static const Color text    = Color(0xFFF0F6FC);
  static const Color textSub = Color(0xFFE6EDF3);
  static const Color muted   = Color(0xFF8B949E);
  static const Color green   = Color(0xFF3FB950);
  static const Color danger  = Color(0xFFF85149);
  static const Color orange  = Color(0xFFD29922);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        onSurface: text,
        outline: border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: muted, size: 22),
        actionsIconTheme: const IconThemeData(color: muted, size: 22),
        shape: const Border(
          bottom: BorderSide(color: border, width: 1),
        ),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentDim,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
