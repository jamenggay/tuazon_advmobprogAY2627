import 'package:flutter/material.dart';

import '../constants.dart';

class ThemeProvider with ChangeNotifier {
  // Controls the app-wide light and dark color theme.
  bool _isDark = false;
  bool get isDark => _isDark;

  // Defines the light theme.
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          primary: AppColors.teal,
          onPrimary: Colors.white,
          secondary: AppColors.ember,
          onSecondary: Colors.white,
          tertiary: AppColors.tealLight,
          error: AppColors.error,
        ).copyWith(
          primaryContainer: AppColors.sand,
          onPrimaryContainer: AppColors.tealDeep,
          secondaryContainer: AppColors.sand,
          onSecondaryContainer: AppColors.emberDeep,
          surface: AppColors.lightBackground,
          outline: AppColors.lightBorder,
        ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardTheme: const CardThemeData(color: AppColors.lightCard, elevation: 0.0),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.teal,
      foregroundColor: Colors.white,
      elevation: 0.0,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.lightBorder),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.tealDeep,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.teal,
    ),
  );

  // Defines the dark theme.
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.dark,
          primary: AppColors.tealLight,
          onPrimary: AppColors.tealDeep,
          secondary: AppColors.ember,
          onSecondary: Colors.white,
          tertiary: AppColors.sand,
          error: AppColors.errorLight,
        ).copyWith(
          primaryContainer: AppColors.tealDeep,
          onPrimaryContainer: AppColors.sand,
          secondaryContainer: AppColors.emberDeep,
          onSecondaryContainer: AppColors.sand,
          surface: AppColors.darkBackground,
          outline: AppColors.darkBorder,
        ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardTheme: const CardThemeData(color: AppColors.darkCard, elevation: 0.0),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkCard,
      foregroundColor: AppColors.sand,
      elevation: 0.0,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.darkBorder),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.tealLight,
        foregroundColor: AppColors.tealDeep,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.tealDeep,
      contentTextStyle: TextStyle(color: AppColors.sand),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.tealLight,
    ),
  );

  // Switches the app theme.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
