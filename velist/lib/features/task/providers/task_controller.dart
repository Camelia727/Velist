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

  // 更新任务 (预留给 Phase 3.3 编辑详情使用)
  Future<void> updateTask(Task task, {
    String? title,
    String? description,
    DateTime? dueDate,
  }) async {
    if (title != null) task.title = title;
    if (description != null) task.description = description;
    if (dueDate != null) task.dueDate = dueDate;
    
    await task.save();
  }
}