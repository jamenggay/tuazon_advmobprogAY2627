import 'package:flutter/material.dart';

import '../constants.dart';

class ThemeProvider with ChangeNotifier {
  // Checks if the app is currently in dark mode
  bool _isDark = false;
  bool get isDark => _isDark;

  // Configuration for the light mode theme
  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          primary: AppColors.teal, // #007979
          onPrimary: Colors.white,
          secondary: AppColors.ember, // #E37434
          onSecondary: Colors.white,
          tertiary: AppColors.tealLight, // #24B1B1
          error: AppColors.error,
        ).copyWith(
          primaryContainer: AppColors.sand, // #FFE2AF
          onPrimaryContainer: AppColors.tealDeep,
          secondaryContainer: AppColors.sand,
          onSecondaryContainer: AppColors.emberDeep,
          surface: AppColors.lightBackground,
          outline: AppColors.lightBorder,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardTheme: const CardThemeData(
          color: AppColors.lightCard,
          elevation: 0.0,
        ),
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

  // Configuration for the dark mode theme
  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.dark,
          primary: AppColors.tealLight, // #24B1B1
          onPrimary: AppColors.tealDeep,
          secondary: AppColors.ember, // #E37434
          onSecondary: Colors.white,
          tertiary: AppColors.sand, // #FFE2AF
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
        cardTheme: const CardThemeData(
          color: AppColors.darkCard,
          elevation: 0.0,
        ),
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

  // Switches between light and dark mode and updates the UI
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
