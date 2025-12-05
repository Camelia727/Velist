import 'package:hive/hive.dart';

part 'hive_models.g.dart';

// Hive Type ID 必须唯一
// 0: Task
// 1: Settings

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String uuid;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  bool hasTime;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  DateTime? completedAt;

  @HiveField(7)
  late DateTime createdAt;

  @HiveField(8)
  String? parentUuid;

  @HiveField(9)
  List<String> tags;

  @HiveField(10)
  int priority;

  // 默认构造函数
  Task({
    required this.uuid,
    required this.title,
    this.description,
    this.dueDate,
    this.hasTime = false,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.parentUuid,
    this.tags = const [],
    this.priority = 0,
  });
}

@HiveType(typeId: 1)
class Settings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  bool enableSmartParsing;

  Settings({
    this.isDarkMode = false,
    this.enableSmartParsing = true,
  });

  Settings copyWith({
    bool? isDarkMode,
    bool? enableSmartParsing,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      enableSmartParsing: enableSmartParsing ?? this.enableSmartParsing,
    );
  }
}