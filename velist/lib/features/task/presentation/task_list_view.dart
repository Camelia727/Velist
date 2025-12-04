import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';

import '../../../../data/models/hive_models.dart';
import '../providers/task_providers.dart';
import '../providers/task_controller.dart';
import 'widgets/task_item.dart';

class TaskListView extends ConsumerWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);
    final groupedTasks = ref.watch(groupedTasksProvider);
    
    // 获取 Controller
    final taskController = ref.watch(taskControllerProvider);

    // 封装列表项渲染逻辑 (含滑动)
    Widget buildSlidableItem(Task task) {
      final isDone = task.isCompleted;

      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Slidable(
          key: ValueKey(task.uuid),
          // 左滑：完成
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            dismissible: DismissiblePane(onDismissed: () {
              taskController.toggleTaskCompletion(task);
            }),
            children: [
              SlidableAction(
                onPressed: (_) => taskController.toggleTaskCompletion(task),
                backgroundColor: isDone ? Colors.amber[700]! : Colors.green,
                foregroundColor: Colors.white,
                icon: isDone ? Icons.undo : Icons.check,
                label: isDone ? 'Undo' : 'Done',
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
          // 右滑：删除
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            dismissible: DismissiblePane(onDismissed: () {
              taskController.deleteTask(task);
            }),
            children: [
              SlidableAction(
                onPressed: (_) => taskController.deleteTask(task),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          ),
          child: TaskItem(task: task),
        ),
      );
    }

    // 空状态视图
    Widget buildEmptyState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const Gap(16),
            Text("No tasks yet", style: TextStyle(color: Colors.grey[400])),
            const Gap(4),
            Text(
              "Type directly (Cmd+J) to add one",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (tasks) {
        if (tasks.isEmpty) return buildEmptyState();

        // 场景 A: Inbox 视图 -> 使用分组渲染
        if (filter == TaskFilter.inbox && groupedTasks.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            // 为了简单起见，直接渲染 Group 列表，每个 Group 内部是一个 Column
            itemCount: groupedTasks.length,
            itemBuilder: (context, index) {
              final group = groupedTasks[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
                    child: Text(
                      group.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: group.isOverdue ? Colors.red : Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Items
                  ...group.tasks.map((task) => buildSlidableItem(task)),
                ],
              );
            },
          );
        }

        // 场景 B: 其他视图 (Completed/Upcoming等) -> 扁平列表
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return buildSlidableItem(task);
          },
        );
      },
    );
  }
}