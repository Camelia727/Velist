import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/hive_models.dart';
import '../../providers/task_controller.dart';

class TaskItem extends ConsumerWidget {
  final Task task;

  const TaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = task.isCompleted;

    // 获取控制器
    final controller = ref.read(taskControllerProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Phase 3.3: 这里预留给详情页弹窗
          print("Tap item: ${task.title}");
        },
        // 增加圆角，使得点击时的水波纹不溢出
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          // 增加垂直内边距，让列表呼吸感更强
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 自定义 Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 2), 
                child: InkWell(
                  onTap: () => controller.toggleTaskCompletion(task),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone
                            ? colorScheme.primary.withValues(alpha: 0.5)
                            : colorScheme.outline.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      color: isDone ? colorScheme.primary : Colors.transparent,
                    ),
                    child: isDone
                        ? Icon(Icons.check,
                            size: 16, color: colorScheme.onPrimary)
                        : null,
                  ),
                ),
              ),

              const Gap(16),

              // 2. 任务主体内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? colorScheme.onSurface.withValues(alpha: 0.4)
                            : colorScheme.onSurface,
                        fontWeight:
                            isDone ? FontWeight.normal : FontWeight.w500,
                        height: 1.2,
                      ),
                    ),

                    // 辅助信息行 (日期 + Tags)
                    if (task.dueDate != null || task.tags.isNotEmpty) ...[
                      const Gap(6),
                      Row(
                        children: [
                          // 日期tag
                          if (task.dueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _DateBadge(
                                date: task.dueDate!,
                                hasTime: task.hasTime,
                                isDone: isDone,
                              ),
                            ),

                          // Tags 显示
                          if (task.tags.isNotEmpty)
                            ...task.tags.map((tag) => Padding(
                                  padding: const EdgeInsets.only(right: 6.0),
                                  child: Text(
                                    "#$tag",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.secondary.withValues(
                                          alpha: isDone ? 0.4 : 0.8),
                                    ),
                                  ),
                                )),
                        ],
                      ),
                    ],

                    // 描述 (如果有且不为空)
                    if (task.description != null &&
                        task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          task.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: isDone ? 0.3 : 0.7),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------
// 内部组件：日期tag
// ----------------------
class _DateBadge extends StatelessWidget {
  final DateTime date;
  final bool hasTime;
  final bool isDone;

  const _DateBadge({
    required this.date,
    required this.hasTime,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    final isOverdue = checkDate.isBefore(today);

    // 如果任务已完成，日期颜色淡化，不再显示红色警报
    Color bgColor = colorScheme.surfaceContainerHighest;
    Color textColor = colorScheme.onSurfaceVariant;

    String text;

    if (checkDate.isAtSameMomentAs(today)) {
      text = hasTime ? DateFormat.Hm().format(date) : 'Today';
      if (!isDone) {
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
      }
    } else if (checkDate.isAtSameMomentAs(tomorrow)) {
      text = 'Tmrrw'; // 简写
    } else {
      text = DateFormat.MMMd().format(date);
    }

    // 只有在未完成时才处理 Overdue 红色
    if (isOverdue && !isDone) {
      bgColor = colorScheme.errorContainer.withValues(alpha: 0.6);
      textColor = colorScheme.error;
    }

    // 已完成时，强制变灰
    if (isDone) {
      bgColor = Colors.transparent; // 去掉背景
      textColor = colorScheme.onSurface.withValues(alpha: 0.3); // 纯文本显示
    }

    return Container(
      padding: isDone
          ? const EdgeInsets.all(0)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
