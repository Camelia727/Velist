import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:velist/data/services/ai_service.dart';
import '../../../data/services/database_service.dart';

enum TaskFilter {
  inbox,
  today,
  upcoming,
  completed,
}

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.inbox);

final tasksStreamProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final filter = ref.watch(taskFilterProvider);

  // 将枚举转换为字符串标识，传给 Service
  String filterKey;
  switch (filter) {
    case TaskFilter.inbox: filterKey = 'inbox'; break;
    case TaskFilter.today: filterKey = 'today'; break;
    case TaskFilter.upcoming: filterKey = 'upcoming'; break;
    case TaskFilter.completed: filterKey = 'completed'; break;
  }

  return db.watchTasks(filterKey);
});

class TaskGroup {
  final String label;
  final List<Task> tasks;
  final bool isOverdue;

  TaskGroup(this.label, this.tasks, {this.isOverdue = false});
}

// 它的作用是监听 tasksStreamProvider，并根据日期将任务归类
final groupedTasksProvider = Provider.autoDispose<List<TaskGroup>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final filter = ref.watch(taskFilterProvider);

  // 如果数据还没加载，或者 filter 不是 inbox (比如是 completed)，则不进行复杂分组
  if (filter != TaskFilter.inbox) {
    return []; // 返回空列表表示不需要分组渲染，直接用 Flat List
  }

  return tasksAsync.when(
    data: (tasks) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final overdue = <Task>[];
      final todayTasks = <Task>[];
      final upcoming = <Task>[];
      final noDate = <Task>[];

      for (var task in tasks) {
        if (task.isCompleted) continue; // 理论上 Inbox 不包含已完成，双重保险

        if (task.dueDate == null) {
          noDate.add(task);
        } else {
          // 处理日期比较 (忽略时间部分，除非非常严格)
          final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
          
          if (taskDate.isBefore(today)) {
            overdue.add(task);
          } else if (taskDate.isAtSameMomentAs(today)) {
            todayTasks.add(task);
          } else {
            upcoming.add(task);
          }
        }
      }

      // 组装结果
      final groups = <TaskGroup>[];
      if (overdue.isNotEmpty) groups.add(TaskGroup("Overdue", overdue, isOverdue: true));
      if (todayTasks.isNotEmpty) groups.add(TaskGroup("Today", todayTasks));
      if (upcoming.isNotEmpty) groups.add(TaskGroup("Upcoming", upcoming));
      if (noDate.isNotEmpty) groups.add(TaskGroup("No Date", noDate));

      return groups;
    },
    error: (_, __) => [],
    loading: () => [],
  );
});

final aiServiceProvider = Provider<AIService>((ref) => AIService());