import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../data/models/hive_models.dart';
import '../../../data/services/sync_service.dart';

final taskControllerProvider = Provider<TaskController>((ref) {
  return TaskController(ref);
});

class TaskController {
  final Ref ref;

  TaskController(this.ref);

  // 标记脏数据
  void _markDirty(Task task) {
    task.isSynced = false;
    task.updatedAt = DateTime.now();
  }

  // 同步触发器
  void _triggerAutoSync() {
    // 稍微延迟一点点，让 UI 动画先跑完，避免卡顿
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(syncServiceProvider).sync();
    });
  }

  // 切换完成状态
  Future<void> toggleTaskCompletion(Task task) async {
    // 乐观更新：先修改内存对象，UI 会立即响应
    final wasCompleted = task.isCompleted;
    task.isCompleted = !wasCompleted;
    task.completedAt = task.isCompleted ? DateTime.now() : null;

    _markDirty(task);

    await task.save();

    _triggerAutoSync();
  }

  // 删除任务
  Future<void> deleteTask(Task task) async {
    task.isDeleted = true;
    _markDirty(task);
    await task.save();
    _triggerAutoSync();
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
    // 允许传入 null 来清除日期
    if (dueDate != task.dueDate) {
      // 如果传入了值（哪怕是null，如果能区分的话），就更新
      task.dueDate = dueDate;
      hasChanges = true;
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
      _markDirty(task);
      await task.save();
      _triggerAutoSync();
    }
  }
}

