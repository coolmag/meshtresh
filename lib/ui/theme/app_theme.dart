import 'package:flutter/material.dart';

/// Application theme configuration - Retro Radio Terminal Style
class AppTheme {
  // Colors
  static const Color terminalGreen = Color(0xFF00FF41);
  static const Color terminalDarkGreen = Color(0xFF008F11);
  static const Color terminalBlack = Color(0xFF0A0A0A);
  static const Color terminalPureBlack = Color(0xFF000000);
  static const Color errorColor = Color(0xFFFF003C); // Retro red error

  /// Dark theme (Default and Only theme for this style)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: terminalPureBlack,
      primaryColor: terminalGreen,
      colorScheme: const ColorScheme.dark(
        primary: terminalGreen,
        secondary: terminalGreen,
        surface: terminalBlack,
        error: errorColor,
        onPrimary: terminalPureBlack,
        onSecondary: terminalPureBlack,
        onSurface: terminalGreen,
        onError: terminalPureBlack,
      ),
      fontFamily: 'Courier', // Standard monospace
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: terminalGreen, fontFamily: 'Courier', letterSpacing: 1.2),
        bodyMedium: TextStyle(color: terminalGreen, fontFamily: 'Courier', letterSpacing: 1.2),
        titleLarge: TextStyle(color: terminalGreen, fontFamily: 'Courier', fontWeight: FontWeight.bold, letterSpacing: 2.0),
        titleMedium: TextStyle(color: terminalGreen, fontFamily: 'Courier', fontWeight: FontWeight.bold),
        labelLarge: TextStyle(color: terminalPureBlack, fontFamily: 'Courier', fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: terminalPureBlack,
        foregroundColor: terminalGreen,
        centerTitle: true,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: terminalGreen, width: 2)),
        titleTextStyle: TextStyle(
          color: terminalGreen,
          fontFamily: 'Courier',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 3.0,
        ),
      ),
      cardTheme: const CardThemeData(
        color: terminalBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: terminalGreen, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: terminalGreen,
        foregroundColor: terminalPureBlack,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: terminalGreen, width: 2)
        ),
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: terminalPureBlack,
        labelStyle: TextStyle(color: terminalDarkGreen),
        hintStyle: TextStyle(color: terminalDarkGreen),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: terminalGreen, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: terminalDarkGreen, width: 1),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: terminalDarkGreen, width: 1),
        ),
      ),
      iconTheme: const IconThemeData(
        color: terminalGreen,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terminalGreen,
          foregroundColor: terminalPureBlack,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Courier'),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: terminalGreen,
        textColor: terminalGreen,
      ),
      dividerTheme: const DividerThemeData(
        color: terminalDarkGreen,
        thickness: 1,
      ),
    );
  }
}
