import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Account section ──
                if (isLoggedIn) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withAlpha(30),
                            child: Text(
                              (auth.user?.firstName.isNotEmpty == true
                                      ? auth.user!.firstName[0]
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.user?.fullName ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  auth.user?.email ?? '',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              auth.user?.role ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_outlined, color: AppColors.primary),
                      title: const Text('Sign In'),
                      subtitle: const Text('Access predictions, remote alerts & more'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── App settings ──
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: const Text('Bluetooth'),
                        subtitle: const Text('Scanning and device settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/settings/bluetooth'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: const Text('Notifications'),
                        subtitle: const Text('Alert types and thresholds'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/settings/notifications'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── About ──
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('App Version'),
                        trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Terms & Privacy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                if (isLoggedIn) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
