import 'package:flutter/material.dart';

ThemeData buildMamaTheme(Color primaryColor, Color secondaryColor) {
  final scheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
    surface: Colors.white,
  ).copyWith(primary: primaryColor, secondary: secondaryColor);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    dividerColor: Colors.grey.withOpacity(0.15),
    textTheme: const TextTheme(
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: Color(0xFF1F2937)),
    ),
  );
}
