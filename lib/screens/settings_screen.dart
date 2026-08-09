import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../poviders/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: SwitchListTile(
        title: const Text('Dark Mode'),
        value: themeProvider.isDark,
        onChanged: (_) => themeProvider.toggleTheme(),
      ),
    );
  }
}