import 'package:flutter/material.dart';

abstract final class DashboardTheme {
  static const ink = Color(0xFF17243B);
  static const muted = Color(0xFF64748B);
  static const accent = Color(0xFF4059D8);
  static const canvas = Color(0xFFF5F7FB);
  static const border = Color(0xFFE2E8F0);
  static const sidebar = Color(0xFF142238);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Segoe UI',
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      primary: accent,
      surface: Colors.white,
      onSurface: ink,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: ink,
        letterSpacing: -0.7,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: muted),
      bodySmall: TextStyle(fontSize: 12, height: 1.5, color: muted),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 350),
    ),
  );
}
