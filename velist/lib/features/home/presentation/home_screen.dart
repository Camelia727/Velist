import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter/services.dart';
import '../../task/providers/task_providers.dart';
import '../../task/presentation/task_list_view.dart';
import 'widgets/desktop_sidebar.dart';
import '../../task/presentation/super_input_box.dart';

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

  void _showSuperInput() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) => const SuperInputBox(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(taskFilterProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 700;

    // 平台判断
    final platform = Theme.of(context).platform;
    final isMac = platform == TargetPlatform.macOS;
    final isiOS = platform == TargetPlatform.iOS;

    // 显示文案
    final shortcutLabel = isMac ? "⌘ J" : "Ctrl J";

    // 1. 最外层：定义快捷键监听 (父级)
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyJ,
            meta: isMac, control: !isMac && !isiOS): _showSuperInput,
      },
      // 2. 中间层：管理焦点 (子级)
      // Focus 必须在 Shortcuts 的下面(Child)，这样事件冒泡时 Shortcuts 才能拦截到
      child: Focus(
        autofocus: true, // 确保页面打开时，焦点就在这里
        debugLabel: 'RootFocus',
        child: Scaffold(
          // 点击背景重新聚焦应用
          body: GestureDetector(
            onTap: () {
              // 显式让 RootFocus 重新获得焦点
              FocusScope.of(context).requestFocus();
            },
            behavior: HitTestBehavior.translucent,
            child: Row(
              children: [
                if (isDesktop)
                  DesktopSidebar(
                    selectedIndex: currentFilter.index,
                    onDestinationSelected: (index) {
                      final filter = TaskFilter.values[index];
                      ref.read(taskFilterProvider.notifier).state = filter;
                    },
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -1.0,
                                  ),
                            ),
                            const Gap(16),

                            // 触发区域
                            GestureDetector(
                              onTap: _showSuperInput,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(Icons.add,
                                        color: Theme.of(context).hintColor),
                                    const Gap(12),
                                    Text(
                                      "Add a task...",
                                      style: TextStyle(
                                          color: Theme.of(context).hintColor,
                                          fontSize: 16),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).canvasColor,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color:
                                                Theme.of(context).dividerColor),
                                      ),
                                      child: Text(
                                        shortcutLabel,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).hintColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: TaskListView(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                    NavigationDestination(
                        icon: Icon(Icons.inbox), label: 'Inbox'),
                    NavigationDestination(
                        icon: Icon(Icons.wb_sunny), label: 'Today'),
                    NavigationDestination(
                        icon: Icon(Icons.calendar_month), label: 'Upcoming'),
                    NavigationDestination(
                        icon: Icon(Icons.done_all), label: 'Done'),
                  ],
                ),
        ),
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
