import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

// 引入模型
import '../models/hive_models.dart';
// 导出模型供 UI 使用
export '../models/hive_models.dart';

/// 全局数据库服务
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be initialized in main.dart');
});

class DatabaseService {
  late Box<Task> _taskBox;
  late Box<Settings> _settingsBox;

  // 初始化 Hive (Web/Native 通用)
  Future<void> init() async {
    // 1. 初始化 Flutter 绑定 (自动处理 Web IndexedDB 和 本地路径)
    await Hive.initFlutter();

    // 2. 注册适配器
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(SettingsAdapter());

    // 3. 打开盒子 (Box)
    _taskBox = await Hive.openBox<Task>('tasks');
    _settingsBox = await Hive.openBox<Settings>('settings');

    // 4. 确保设置存在
    if (_settingsBox.isEmpty) {
      await _settingsBox.put('config', Settings());
    }
  }

  // --- CRUD API ---

  // 获取 Inbox (未完成，按时间倒序)
  // Hive 没有 SQL，我们需要在内存中 filter/sort
  // 对于 Todo App 的数据量（几千条），这在客户端完全没问题。
  List<Task> getInboxTasks() {
    final tasks = _taskBox.values
        .where((t) => !t.isCompleted)
        .toList();
    
    // 排序: 创建时间倒序
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  // 监听数据变化 (Stream)
  // 根据 Filter 类型返回不同的流
  Stream<List<Task>> watchTasks(String filterType) {
    // 监听 Box 变化事件，每次变化重新计算列表
    return _taskBox.watch().map((_) {
      return _getTasksByFilter(filterType);
    }).startWith(_getTasksByFilter(filterType)); // 初始发出一次数据
  }

  // 内部辅助方法：根据条件筛选
  List<Task> _getTasksByFilter(String filterType) {
    final allTasks = _taskBox.values;
    List<Task> result = [];

    switch (filterType) {
      case 'inbox':
        result = allTasks.where((t) => !t.isCompleted).toList();
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      
      case 'today':
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        
        result = allTasks.where((t) {
          if (t.isCompleted) return false;
          if (t.dueDate == null) return false;
          return t.dueDate!.isBefore(endOfDay);
        }).toList();
        result.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
        break;
        
      case 'upcoming':
         result = allTasks.where((t) => !t.isCompleted && t.dueDate != null).toList();
         result.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
         break;

      case 'completed':
        result = allTasks.where((t) => t.isCompleted).toList();
        // 完成时间倒序，如果没有完成时间则用创建时间
        result.sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
        break;
    }
    return result;
  }

  // 添加任务
  Future<void> insertTask(String title, {String? description}) async {
    final newTask = Task(
      uuid: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      tags: [],
    );
    // 使用 uuid 作为 key，或者让 Hive 自动生成 int key
    // 这里我们直接 add，让 Hive 管理 key
    await _taskBox.add(newTask);
  }

  // 直接添加任务对象
  Future<void> addTask(Task task) async {
    await _taskBox.add(task);
  }

  // 切换完成状态
  Future<void> toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    task.completedAt = task.isCompleted ? DateTime.now() : null;
    await task.save(); // HiveObject 自带 save 方法
  }

  // 删除任务
  Future<void> deleteTask(Task task) async {
    await task.delete(); // HiveObject 自带 delete 方法
  }
}

// RxDart 扩展，用于让 Stream 在监听时立即发出当前值 (Polyfill)
extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initial) async* {
    yield initial;
    yield* this;
  }
}