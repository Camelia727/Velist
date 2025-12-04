import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../data/models/hive_models.dart';

final taskControllerProvider = Provider<TaskController>((ref) {
  return TaskController();
});

class TaskController {
  // 切换完成状态
  Future<void> toggleTaskCompletion(Task task) async {
    // 乐观更新：先修改内存对象，UI 会立即响应
    final wasCompleted = task.isCompleted;
    task.isCompleted = !wasCompleted;
    task.completedAt = task.isCompleted ? DateTime.now() : null;

    await task.save();
  }

  // 删除任务
  Future<void> deleteTask(Task task) async {
    await task.delete();
  }

  // 更新任务
  Future<void> updateTask(
    Task task, {
    String? title,
    String? description,
    DateTime? dueDate,
    bool? hasTime,
    List<String>? tags,
  }) async {
    bool hasChanges = false;

    if (title != null && title != task.title) {
      task.title = title;
      hasChanges = true;
    }
    if (description != null && description != task.description) {
      task.description = description;
      hasChanges = true;
    }
    // 日期处理比较特殊，允许传入 null 来清除日期
    if (dueDate != task.dueDate) {
      // 如果传入了值（哪怕是null，如果能区分的话），就更新
      if (dueDate != null) {
        task.dueDate = dueDate;
        hasChanges = true;
      }
    }

    if (hasTime != null && hasTime != task.hasTime) {
      task.hasTime = hasTime;
      hasChanges = true;
    }

    if (tags != null) {
      task.tags = tags;
      hasChanges = true;
    }

    if (hasChanges) {
      await task.save();
    }
  }
}
