import 'package:flutter_riverpod/flutter_riverpod.dart';
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