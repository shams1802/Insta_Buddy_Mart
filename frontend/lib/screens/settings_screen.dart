import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_mode_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeModeProvider>().mode;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Appearance'),
            subtitle: const Text('Dark, light, or match the device'),
            trailing: DropdownButton<ThemeMode>(
              value: mode,
              underline: const SizedBox.shrink(),
              onChanged: (v) {
                if (v != null) context.read<ThemeModeProvider>().setMode(v);
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              ],
            ),
          ),
          const Divider(height: 32),
          const ListTile(title: Text('Notifications'), subtitle: Text('Push & SMS — connect in production')),
          SwitchListTile(
            title: const Text('Order updates'),
            subtitle: const Text('Demo toggle (local only)'),
            value: true,
            onChanged: (_) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved locally (demo)')));
            },
          ),
        ],
      ),
    );
  }
}
