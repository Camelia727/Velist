import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../providers/settings_provider.dart';
import '../../../core/widgets/window_title_bar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // 简单的 AppBar
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
              const _SectionHeader(title: "Intelligence"),
              SwitchListTile(
                title: const Text("Smart Parsing"),
                subtitle: const Text("Auto-detect dates and times from input"),
                value: settings.enableSmartParsing,
                onChanged: (value) => notifier.toggleSmartParsing(value),
                secondary: const Icon(Icons.auto_awesome),
              ),
              const Divider(height: 32),
              const _SectionHeader(title: "About"),
              const ListTile(
                title: Text("Velist"),
                subtitle: Text("v0.3.5 (Phase 3.5)"),
                leading: Icon(Icons.info_outline),
              ),
            ],
          ),
        )
      ],
    ));
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
