import 'package:flutter/material.dart';

class AppTheme {
  // Brand color guidelines (HSL derivatives)
  static const Color darkBg = Color(0xFF0B121E);
  static const Color darkSurface = Color(0xFF141F32);
  static const Color darkAccent = Color(0xFF2196F3); // Neon electric blue
  static const Color darkCardBorder = Color(0xFF30363D);

  static const Color lightBg = Color(0xFFF0F2F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFF0F62FE); // Deep royal blue
  static const Color lightCardBorder = Color(0xFFE1E4E8);

  static const Color bullColor = Color(0xFF00D09C); // Web app green
  static const Color bearColor = Color(0xFFFF5353); // Web app red

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBg,
      primaryColor: darkAccent,
      cardColor: darkSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      colorScheme: const ColorScheme.dark().copyWith(
        primary: darkAccent,
        surface: darkSurface,
        error: bearColor,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: lightBg,
      primaryColor: lightAccent,
      cardColor: lightSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      colorScheme: const ColorScheme.light().copyWith(
        primary: lightAccent,
        surface: lightSurface,
        error: bearColor,
      ),
    );
  }
}
