import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/settings_provider.dart';
import '../../../core/widgets/window_title_bar.dart';
import '../../../data/services/auth_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
        body: Column(
      children: [
        const WindowTitleBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back)),
              const Gap(8),
              Text(
                "Settings",
                style: Theme.of(context).textTheme.titleLarge,
              )
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Account Section ---
              const _SectionHeader(title: "Account"),
              _buildAccountTile(context, ref, currentUser),
              const Divider(height: 32),

              // --- General Section ---
              const _SectionHeader(title: "General"),
              SwitchListTile(
                title: const Text("Dark Mode"),
                subtitle: const Text("Switch between light and dark themes"),
                value: settings.isDarkMode,
                onChanged: (value) => notifier.toggleTheme(value),
                secondary: Icon(
                  settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
              ),
              const Divider(height: 32),

              // --- Intelligence Section ---
              const _SectionHeader(title: "Intelligence"),
              SwitchListTile(
                title: const Text("Smart Parsing"),
                subtitle: const Text("Auto-detect dates and times from input"),
                value: settings.enableSmartParsing,
                onChanged: (value) => notifier.toggleSmartParsing(value),
                secondary: const Icon(Icons.auto_awesome),
              ),
              const Divider(height: 32),

              // --- About Section ---
              const _SectionHeader(title: "About"),
              const ListTile(
                title: Text("Velist"),
                subtitle: Text("v0.4.0 (Sync Beta)"), // 更新版本号提示
                leading: Icon(Icons.info_outline),
              ),
            ],
          ),
        )
      ],
    ));
  }

  Widget _buildAccountTile(BuildContext context, WidgetRef ref, User? user) {
    if (user == null) {
      // 未登录状态
      return ListTile(
        leading: const Icon(Icons.account_circle_outlined),
        title: const Text("Sync Account"),
        subtitle: const Text("Sign in to sync across devices"),
        trailing: FilledButton.tonal(
          onPressed: () => context.push('/auth'), // 跳转路由
          child: const Text("Sign In"),
        ),
      );
    } else {
      // 已登录状态
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.person, size: 20),
        ),
        title: Text(
          user.email ?? "User",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: const Text(
          "Sync Active", 
          style: TextStyle(color: Colors.green),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: "Log Out",
          onPressed: () async {
            await ref.read(authServiceProvider).signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            }
          },
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}