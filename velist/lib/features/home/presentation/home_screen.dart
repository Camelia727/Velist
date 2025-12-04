import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import '../../task/providers/task_providers.dart';
import '../../task/presentation/task_list_view.dart';
import 'widgets/desktop_sidebar.dart';
import '../../../data/services/database_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 临时输入控制器
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submitTask() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      ref.read(databaseServiceProvider).insertTask(text);
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听当前的 Filter
    final currentFilter = ref.watch(taskFilterProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 700; // 调整断点

    return Scaffold(
      body: Row(
        children: [
          // 1. Sidebar (Desktop Only)
          if (isDesktop)
            DesktopSidebar(
              selectedIndex: currentFilter.index,
              onDestinationSelected: (index) {
                // 根据索引切换 Provider 状态
                final filter = TaskFilter.values[index];
                ref.read(taskFilterProvider.notifier).state = filter;
              },
            ),

          // 2. Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2.1 Header Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFilterTitle(currentFilter),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -1.0,
                            ),
                      ),
                      const Gap(16),
                      // 2.2 临时快速输入框 (Simple Input)
                      TextField(
                        controller: _inputController,
                        onSubmitted: (_) => _submitTask(),
                        decoration: InputDecoration(
                          hintText: 'Press Cmd+K to quick add',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          prefixIcon: const Icon(Icons.add),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2.3 Task List
                const Expanded(
                  child: TaskListView(),
                ),
              ],
            ),
          ),
        ],
      ),

      // 3. Mobile Navigation
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: currentFilter.index,
              onDestinationSelected: (index) {
                if (index < TaskFilter.values.length) {
                  ref.read(taskFilterProvider.notifier).state =
                      TaskFilter.values[index];
                }
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
                NavigationDestination(
                    icon: Icon(Icons.wb_sunny), label: 'Today'),
                NavigationDestination(
                    icon: Icon(Icons.calendar_month), label: 'Upcoming'),
                NavigationDestination(
                    icon: Icon(Icons.done_all), label: 'Done'),
              ],
            ),
    );
  }

  String _getFilterTitle(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.inbox:
        return "Inbox";
      case TaskFilter.today:
        return "Today";
      case TaskFilter.upcoming:
        return "Upcoming";
      case TaskFilter.completed:
        return "Completed";
    }
  }
}
