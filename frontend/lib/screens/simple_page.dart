import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SimplePage extends StatelessWidget {
  final String title;
  final String body;

  const SimplePage({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppTheme.surfaceCard : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Text(
              body,
              style: TextStyle(
                height: 1.45,
                color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
