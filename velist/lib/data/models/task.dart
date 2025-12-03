import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  // 1. UUID：直接初始化，不在构造函数中传参
  @Index(unique: true, replace: true)
  String uuid = const Uuid().v4();

  @Index(type: IndexType.value, caseSensitive: false)
  String title;

  String? description;

  @Index()
  DateTime? dueDate;

  bool hasTime;

  @Index()
  bool isCompleted;

  DateTime? completedAt;

  DateTime createdAt = DateTime.now(); 

  @Index()
  String? parentUuid;

  List<String> tags;

  byte priority;

  // 构造函数
  Task({
    required this.title,
    this.description,
    this.dueDate,
    this.hasTime = false,
    this.isCompleted = false,
    this.completedAt,
    this.parentUuid,
    this.tags = const [],
    this.priority = 0,
  });
}