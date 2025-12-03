import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _lightBg = Colors.white;
  static const _darkBg = Color(0xFF121212);
  static const _electric = Colors.teal; 

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _electric,
      brightness: Brightness.light,
      surface: _lightBg,
      primary: _electric, // 强制主色
    ),
    // 优化字体：使用 Inter，增加字符间距提升可读性
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerTheme: DividerThemeData(
      color: Colors.grey.withValues(alpha: 0.1),
      thickness: 1,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _electric,
      brightness: Brightness.dark,
      surface: _darkBg,
      primary: _electric,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white70,
      displayColor: Colors.white,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerTheme: DividerThemeData(
      color: Colors.white.withValues(alpha: 0.1),
      thickness: 1,
    ),
  );
}