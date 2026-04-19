import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_provider.dart';
import 'settings_screen.dart';
import 'runner_onboarding_screen.dart';
import 'simple_page.dart';
import 'orders_screen.dart';
import 'change_password_dialog.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _push(context, const SettingsScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.userName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(auth.userEmail, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (auth.isRunner)
                          Chip(
                            avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                            label: Text(auth.userRating.toStringAsFixed(1)),
                          ),
                        Chip(
                          label: Text(auth.isRunner ? 'Runner' : 'Requester'),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text(auth.kycCompleted ? 'KYC ✓' : 'KYC pending'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _push(context, const EditProfileScreen()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _stat(context, 'Wallet', '₹${auth.walletBalance.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _stat(context, 'Earnings', '₹${auth.earnings.toStringAsFixed(0)}', Icons.savings_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => _push(context, const RunnerOnboardingScreen()),
            icon: const Icon(Icons.directions_run),
            label: Text(auth.isRunner ? 'Runner setup (review)' : 'Become a Runner'),
          ),
          const SizedBox(height: 24),
          _section(context, 'Menu', [
            _tile(context, 'My Orders', Icons.receipt_long, () => _push(context, const OrdersScreen())),
            _tile(context, 'Wallet', Icons.wallet, () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wallet balance: ₹${auth.walletBalance.toStringAsFixed(0)}')));
            }),
            _tile(context, 'Earnings', Icons.trending_up, () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Total earnings (demo): ₹${auth.earnings.toStringAsFixed(0)}')));
            }),
            _tile(context, 'Change Password', Icons.security, () {
              showDialog(context: context, builder: (_) => const ChangePasswordDialog());
            }),
            _tile(context, 'Settings', Icons.settings, () => _push(context, const SettingsScreen())),
            _tile(context, 'Notifications', Icons.notifications_outlined, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification center — demo')));
            }),
          ]),
          const SizedBox(height: 12),
          _section(context, 'Support', [
            _tile(
              context,
              'About Us',
              Icons.info_outline,
              () => _push(
                context,
                const SimplePage(
                  title: 'About Insta Buddy Mart',
                  body:
                      'Insta Buddy Mart connects people who need groceries and essentials with nearby runners who shop and deliver. '
                      'This build uses demo data and offline auth so you can explore the full flow.',
                ),
              ),
            ),
            _tile(
              context,
              'Help Center',
              Icons.help_outline,
              () => _push(
                context,
                const SimplePage(
                  title: 'Help Center',
                  body: '• Post an order from Home after checkout\n'
                      '• Runners accept from Orders → Nearby\n'
                      '• Chat opens automatically for coordination\n'
                      '• For production, connect IAM + chat services.',
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppTheme.surfaceCard : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.surfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.25)),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
