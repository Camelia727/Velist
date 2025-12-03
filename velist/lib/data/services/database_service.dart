import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 导入生成的模型文件
import '../models/task.dart';
import '../models/settings.dart';

/// 全局数据库服务 Provider
/// 使用 FutureProvider 确保数据库初始化完成后再被 UI 调用
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be initialized in main.dart');
});

class DatabaseService {
  late final Isar _isar;

  Isar get isar => _isar;

  /// 初始化数据库
  Future<void> init() async {
    // 1. 确定存储路径
    String dirPath = "";
    if (!kIsWeb) {
      // 桌面端和移动端需要指定路径
      final dir = await getApplicationDocumentsDirectory();
      dirPath = dir.path;
    }

    // 2. 打开 Isar 实例
    // 注意：Web 端不需要 directory，Isar 会自动使用 IndexedDB
    _isar = await Isar.open(
      [TaskSchema, SettingsSchema], // 传入所有 Schema
      directory: dirPath, 
      inspector: true, // 开发模式下开启检查器 (DevTools)
    );
    
    // 3. 确保默认设置存在
    await _ensureSettingsCreated();
  }

  /// 确保设置表里至少有一条数据
  Future<void> _ensureSettingsCreated() async {
    final count = await _isar.settings.count();
    if (count == 0) {
      await _isar.writeTxn(() async {
        await _isar.settings.put(Settings());
      });
    }
  }

  /// ---------------------------------------------------------
  /// 基础 CRUD 封装 (也可以后续放到 Repository 层，MVP 阶段先放这里)
  /// ---------------------------------------------------------

  // 获取所有未完成任务流
  Future<List<Task>> getInboxTasks() async {
    return _isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
  }
  
  // 获取今日任务 (Due Date 是今天，或者 overdue 的)
  // 注意：日期比较需要精确处理时区，这里暂做简化处理
  Future<List<Task>> getTodayTasks() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _isar.tasks
        .filter()
        .isCompletedEqualTo(false)
        .and()
        .dueDateLessThan(endOfDay) // 截止日期在明天之前
        .sortByDueDate()
        .findAll();
  }

  // 保存/更新任务
  Future<void> saveTask(Task task) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });
  }

  // 删除任务
  Future<void> deleteTask(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.tasks.delete(id);
    });
  }
  
  // 切换完成状态
  Future<void> toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    task.completedAt = task.isCompleted ? DateTime.now() : null;
    await saveTask(task);
  }
}