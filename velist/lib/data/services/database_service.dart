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
  List<Task> getInboxTasks() {
    final tasks = _taskBox.values.where((t) => !t.isCompleted).toList();

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

    // 统一计算时间基准点，避免在循环中重复计算
    final now = DateTime.now();
    // 今天凌晨 00:00:00
    final todayStart = DateTime(now.year, now.month, now.day);
    // 明天凌晨 00:00:00 (界碑)
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    switch (filterType) {
      case 'inbox':
        // Inbox 定义：显示所有未完成任务 (也可以修改为只显示没有日期的任务，取决于你的设计哲学)
        // 目前保持原逻辑：所有未完成
        result = allTasks.where((t) => !t.isCompleted).toList();
        // 排序：新创建的在上面
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;

      case 'today':
        // Today 定义：
        // 1. 未完成
        // 2. 有截止日期
        // 3. 截止日期在“明天之前” (即：包含今天 + 所有过期任务)
        result = allTasks.where((t) {
          if (t.isCompleted || t.dueDate == null) return false;
          return t.dueDate!.isBefore(tomorrowStart);
        }).toList();
        
        // 排序：日期越早越靠前 (优先处理过期的)
        result.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
        break;

      case 'upcoming':
        // Upcoming 定义：
        // 1. 未完成
        // 2. 有截止日期
        // 3. 截止日期在“明天及以后” (不包含今天)
        result = allTasks.where((t) {
          if (t.isCompleted || t.dueDate == null) return false;
          // 逻辑：日期 >= 明天凌晨
          return t.dueDate!.isAtSameMomentAs(tomorrowStart) || t.dueDate!.isAfter(tomorrowStart);
        }).toList();
        
        // 排序：日期越近越靠前
        result.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
        break;

      case 'completed':
        result = allTasks.where((t) => t.isCompleted).toList();
        // 排序：最近完成的在最上面
        result.sort((a, b) => (b.completedAt ?? b.createdAt)
            .compareTo(a.completedAt ?? a.createdAt));
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
