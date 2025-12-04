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
    final colorScheme = theme.colorScheme;

    // Hooks
    final titleController = useTextEditingController(text: task.title);
    final descController = useTextEditingController(text: task.description);

    final selectedDate = useState<DateTime?>(task.dueDate);
    final hasTime = useState<bool>(task.hasTime);
    final tags = useState<List<String>>(List.from(task.tags));

    // Save Logic
    void handleSave() {
      ref.read(taskControllerProvider).updateTask(
            task,
            title: titleController.text,
            description: descController.text,
            dueDate: selectedDate.value,
            hasTime: hasTime.value,
            tags: tags.value,
          );
      Navigator.pop(context);
    }

    Future<void> showSmartDateMenu() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final nextWeek = today.add(const Duration(days: 7));

      // 使用 ModalBottomSheet 展示快捷选项
      await showModalBottomSheet(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.today, color: Colors.blue),
                title: const Text("Today"),
                onTap: () {
                  selectedDate.value = today;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.wb_sunny_outlined, color: Colors.orange),
                title: const Text("Tomorrow"),
                onTap: () {
                  selectedDate.value = tomorrow;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.next_week_outlined, color: Colors.purple),
                title: const Text("Next Week"),
                onTap: () {
                  selectedDate.value = nextWeek;
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text("Pick Custom Date..."),
                onTap: () async {
                  Navigator.pop(ctx); // Close menu first
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate.value ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) selectedDate.value = picked;
                },
              ),
              if (selectedDate.value != null) ...[
                const Divider(),
                ListTile(
                  leading: Icon(Icons.block, color: colorScheme.error),
                  title: Text("Remove Date",
                      style: TextStyle(color: colorScheme.error)),
                  onTap: () {
                    selectedDate.value = null;
                    hasTime.value = false;
                    Navigator.pop(ctx);
                  },
                ),
              ]
            ],
          ),
        ),
      );
    }

    Future<void> showSmartTimeMenu() async {
      // 如果还没选日期，默认设为今天
      if (selectedDate.value == null) selectedDate.value = DateTime.now();

      final baseDate = selectedDate.value!;

      await showModalBottomSheet(
        context: context,
        builder: (ctx) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.wb_twilight, color: Colors.amber),
                title: const Text("Morning (09:00)"),
                onTap: () {
                  selectedDate.value = DateTime(
                      baseDate.year, baseDate.month, baseDate.day, 9, 0);
                  hasTime.value = true;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                title: const Text("Afternoon (14:00)"),
                onTap: () {
                  selectedDate.value = DateTime(
                      baseDate.year, baseDate.month, baseDate.day, 14, 0);
                  hasTime.value = true;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.nights_stay, color: Colors.indigo),
                title: const Text("Evening (19:00)"),
                onTap: () {
                  selectedDate.value = DateTime(
                      baseDate.year, baseDate.month, baseDate.day, 19, 0);
                  hasTime.value = true;
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text("Pick Custom Time..."),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showTimePicker(
                      context: context, initialTime: TimeOfDay.now());
                  if (picked != null) {
                    final d = selectedDate.value!;
                    selectedDate.value = DateTime(
                        d.year, d.month, d.day, picked.hour, picked.minute);
                    hasTime.value = true;
                  }
                },
              ),
              if (hasTime.value) ...[
                const Divider(),
                ListTile(
                  leading: Icon(Icons.close, color: colorScheme.error),
                  title: Text("Remove Time",
                      style: TextStyle(color: colorScheme.error)),
                  onTap: () {
                    hasTime.value = false;
                    Navigator.pop(ctx);
                  },
                ),
              ]
            ],
          ),
        ),
      );
    }

    // Tag Logic (保持不变)
    void addTag(String newTag) {
      final cleanTag = newTag.trim();
      if (cleanTag.isNotEmpty && !tags.value.contains(cleanTag)) {
        tags.value = [...tags.value, cleanTag];
      }
    }

    void removeTag(String tag) {
      final newList = List<String>.from(tags.value);
      newList.remove(tag);
      tags.value = newList;
    }

    Future<void> showAddTagDialog() async {
      final textController = TextEditingController();
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          // ... 保持原样 ...
          title: const Text("Add Tag"),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
                hintText: "e.g. Work", border: OutlineInputBorder()),
            onSubmitted: (val) {
              addTag(val);
              Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            FilledButton(
                onPressed: () {
                  addTag(textController.text);
                  Navigator.pop(ctx);
                },
                child: const Text("Add")),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Gap(24),

          // Title (优化键盘交互)
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
            textInputAction: TextInputAction.next, // 按回车跳到下一个
          ),

          const Gap(16),

          // Properties (Using Smart Logic)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date Chip
                FilterChip(
                  showCheckmark: false,
                  avatar: Icon(Icons.calendar_today,
                      size: 16,
                      color: selectedDate.value != null
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.primary),
                  label: Text(selectedDate.value == null
                      ? 'No Date'
                      : DateFormat('MMM d').format(selectedDate.value!)),
                  selected: selectedDate.value != null,
                  onSelected: (_) => showSmartDateMenu(), 
                  backgroundColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  selectedColor: colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                      color: selectedDate.value != null
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurface),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),

                const Gap(8),

                // Time Chip
                FilterChip(
                  showCheckmark: false,
                  avatar: Icon(Icons.access_time,
                      size: 16,
                      color: hasTime.value
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.primary),
                  label: Text((hasTime.value && selectedDate.value != null)
                      ? DateFormat('HH:mm').format(selectedDate.value!)
                      : 'No Time'),
                  selected: hasTime.value,
                  onSelected: (_) => showSmartTimeMenu(), 
                  backgroundColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  selectedColor: colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                      color: hasTime.value
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurface),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ],
            ),
          ),

          const Gap(12),

          // Tags Area (保持不变)
          Wrap(
            spacing: 8,
            runSpacing: 0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...tags.value.map((tag) => InputChip(
                    label: Text(tag),
                    labelStyle: TextStyle(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12),
                    backgroundColor:
                        colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    deleteIcon: Icon(Icons.close,
                        size: 14, color: colorScheme.secondary),
                    onDeleted: () => removeTag(tag),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  )),
              ActionChip(
                label: const Text("Add Tag"),
                avatar: const Icon(Icons.add, size: 16),
                onPressed: showAddTagDialog,
                backgroundColor: Colors.transparent,
                side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.all(0),
              ),
            ],
          ),

          const Gap(16),

          // Notes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: descController,
              style: theme.textTheme.bodyMedium,
              decoration: const InputDecoration(
                  hintText: "Add notes...",
                  border: InputBorder.none,
                  isDense: true),
              maxLines: 5,
              minLines: 3,
            ),
          ),

          const Gap(24),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  ref.read(taskControllerProvider).deleteTask(task);
                  Navigator.pop(context);
                },
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                label:
                    Text("Delete", style: TextStyle(color: colorScheme.error)),
              ),
              FilledButton(
                  onPressed: handleSave, child: const Text("Save Changes")),
            ],
          ),
        ],
      ),
    );
  }
}
