import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// 引入表定义
import '../models/schema.dart';
import '../converters/string_list_converter.dart';

// 生成文件名
part 'database_service.g.dart';

@DriftDatabase(tables: [Tasks, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'velist_db'));

  @override
  int get schemaVersion => 1;
  
  // --- 确保设置存在 ---
  Future<void> ensureSettingsCreated() async {
    // ✅ 修复 1: 正确使用 await 获取列表长度
    final allSettings = await select(settings).get();
    if (allSettings.isEmpty) {
      await into(settings).insert(SettingsCompanion.insert());
    }
  }

  // --- CRUD API ---

  Future<List<Task>> getInboxTasks() {
    return (select(tasks)
      ..where((t) => t.isCompleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();
  }

  Stream<List<Task>> watchTodayTasks() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return (select(tasks)
      ..where((t) => t.isCompleted.equals(false) & t.dueDate.isSmallerThanValue(tomorrowStart))
      ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
      .watch();
  }

  Future<int> insertTask(String title, {String? description}) {
    return into(tasks).insert(TasksCompanion.insert(
      uuid: const Uuid().v4(),
      title: title,
      description: Value(description),
      tags: [], 
    ));
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final newStatus = !task.isCompleted;
    await (update(tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        isCompleted: Value(newStatus),
        completedAt: Value(newStatus ? DateTime.now() : null),
      ),
    );
  }
  
  Future<void> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }
}

final databaseServiceProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  db.ensureSettingsCreated(); 
  return db;
});