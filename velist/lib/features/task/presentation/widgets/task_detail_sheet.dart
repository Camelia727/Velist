import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/hive_models.dart';
import '../../providers/task_controller.dart';

class TaskDetailSheet extends HookConsumerWidget {
  final Task task;

  const TaskDetailSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Hooks: 管理输入框状态
    final titleController = useTextEditingController(text: task.title);
    final descController = useTextEditingController(text: task.description);

    // Hooks: 管理临时状态 (日期/时间)，点击保存前不写入 Hive
    final selectedDate = useState<DateTime?>(task.dueDate);
    final hasTime = useState<bool>(task.hasTime);

    // 保存逻辑
    void handleSave() {
      ref.read(taskControllerProvider).updateTask(
            task,
            title: titleController.text,
            description: descController.text,
            dueDate: selectedDate.value,
            hasTime: hasTime.value,
          );
      Navigator.pop(context); // 关闭弹窗
    }

    // 日期选择器逻辑
    Future<void> pickDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value ?? now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) {
        selectedDate.value = picked;
      }
    }

    // 切换是否包含时间 (简单版：点一下变成今天/明天 9:00，或者清除时间)
    // 实际项目中建议用专门的 DateTimePicker 库，这里用原生组件模拟
    Future<void> pickTime() async {
      if (selectedDate.value == null) {
        selectedDate.value = DateTime.now();
      }
      final picked =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());

      if (picked != null) {
        final d = selectedDate.value!;
        selectedDate.value =
            DateTime(d.year, d.month, d.day, picked.hour, picked.minute);
        hasTime.value = true;
      }
    }

    return Container(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24 // 键盘避让
          ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 顶部把手
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(24),

          // 2. 标题输入
          TextField(
            controller: titleController,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: "Task title",
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
            textInputAction: TextInputAction.next,
          ),

          const Gap(16),

          // 3. 属性栏 (日期, 时间, Tag占位)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 日期 Chip
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(selectedDate.value == null
                      ? 'No Date'
                      : DateFormat('MMM d').format(selectedDate.value!)),
                  onPressed: pickDate,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),

                const Gap(8),

                // 时间 Chip
                ActionChip(
                  avatar: const Icon(Icons.access_time, size: 16),
                  label: Text((hasTime.value && selectedDate.value != null)
                      ? DateFormat('HH:mm').format(selectedDate.value!)
                      : 'No Time'),
                  onPressed: pickTime, // 简单调用 TimePicker
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),

                const Gap(8),

                // Tag 占位 (Phase 4)
                ActionChip(
                  avatar: const Icon(Icons.tag, size: 16),
                  label: const Text('Tags'),
                  onPressed: () {
                    // TODO: Implement Tag Picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tag system coming in Phase 4'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ],
            ),
          ),

          const Gap(16),

          // 4. 描述输入
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: descController,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: "Add notes...",
                border: InputBorder.none,
                isDense: true,
              ),
              maxLines: 5,
              minLines: 3,
            ),
          ),

          const Gap(24),

          // 5. 底部操作栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 删除按钮
              TextButton.icon(
                onPressed: () {
                  ref.read(taskControllerProvider).deleteTask(task);
                  Navigator.pop(context);
                },
                icon:
                    Icon(Icons.delete_outline, color: theme.colorScheme.error),
                label: Text("Delete",
                    style: TextStyle(color: theme.colorScheme.error)),
              ),

              // 保存按钮
              FilledButton(
                onPressed: handleSave,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
