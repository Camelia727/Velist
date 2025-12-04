import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/database_service.dart';

class TaskItem extends ConsumerWidget {
  final Task task;

  const TaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDone = task.isCompleted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 点击整个条目可以进入详情模式（后续实现）
          // 目前暂时作为切换完成状态
          _toggleCompletion(ref);
        },
        borderRadius: BorderRadius.circular(8),
        hoverColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // 1. 自定义 Checkbox (圆形，更现代)
              InkWell(
                onTap: () => _toggleCompletion(ref),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    color: isDone ? theme.colorScheme.primary : Colors.transparent,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              
              const Gap(16),

              // 2. 任务内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone 
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4) 
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // 如果有备注或日期，显示在下面
                    if (task.description != null || task.dueDate != null) ...[
                      const Gap(4),
                      Row(
                        children: [
                          if (task.dueDate != null)
                            _DateBadge(date: task.dueDate!, hasTime: task.hasTime),
                        ],
                      )
                    ]
                  ],
                ),
              ),
              
              // 3. 删除按钮 (仅悬停或向左滑时显示，简化起见先放这里)
              // 也可以做成 Invisible Action，只在 Hover 时显示
              IconButton(
                icon: Icon(Icons.close, size: 18, color: theme.colorScheme.outline),
                onPressed: () {
                  ref.read(databaseServiceProvider).deleteTask(task);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleCompletion(WidgetRef ref) {
    ref.read(databaseServiceProvider).toggleTaskCompletion(task);
  }
}

// 小组件：日期徽章
class _DateBadge extends StatelessWidget {
  final DateTime date;
  final bool hasTime;

  const _DateBadge({required this.date, required this.hasTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = date.isBefore(DateTime.now()) && !DateUtils.isSameDay(date, DateTime.now());
    
    // 格式化日期：如果是今天显示 "Today", 否则显示 "MM-dd"
    String text;
    if (DateUtils.isSameDay(date, DateTime.now())) {
      text = hasTime ? DateFormat.Hm().format(date) : 'Today';
    } else {
      text = DateFormat.MMMd().format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOverdue 
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.5) 
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}