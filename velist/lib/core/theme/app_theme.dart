import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 核心色板 (Page 2)
  static const _lightBg = Colors.white;
  static const _darkBg = Color(0xFF121212);
  static const _electricViolet = Colors.teal;

  static const _primaryColor = _electricViolet;

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      surface: _lightBg,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    // 去除 Material 默认的水波纹，符合 "Invisible UI"
    splashFactory: NoSplash.splashFactory, 
    highlightColor: Colors.transparent,
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
      surface: _darkBg,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}