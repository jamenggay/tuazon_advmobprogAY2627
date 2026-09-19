import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../poviders/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/app_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // logout function
  Future<void> _logout(BuildContext context) async {
    final userService = UserService();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => buildAppDialog(
        dialogContext: dialogContext,
        title: 'Log out',
        message: 'Are you sure you want to log out?',
        confirmLabel: 'Log out',
        isDanger: true,
        fields: const [],
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );

    if (confirmed != true) return;

    await userService.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          const Divider(height: 1),
          // logout button 
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Log out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
