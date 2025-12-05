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

  // --- 多端同步 ---
  @HiveField(11)
  late DateTime updatedAt; // 用于解决冲突 (Last Write Wins)

  @HiveField(12, defaultValue: false)
  bool isSynced; // 标记：true=已同步到云端; false=本地有修改需上传

  @HiveField(13, defaultValue: false)
  bool isDeleted; // 标记：软删除。如果为 true，UI 应该隐藏它，同步引擎应通知服务器删除。

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
    DateTime? updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  }) {
    this.updatedAt = updatedAt ?? createdAt;
  }

  Map<String, dynamic> toJson({required String userId}) {
    return {
      'uuid': uuid,
      'user_id': userId,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'has_time': hasTime,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'parent_uuid': parentUuid,
      'tags': tags,
      'priority': priority,
      'is_deleted': isDeleted,
    };
  }
}

@HiveType(typeId: 1)
class Settings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  bool enableSmartParsing;

  @HiveField(2)
  DateTime? lastSyncTime;

  Settings({
    this.isDarkMode = false,
    this.enableSmartParsing = true,
    this.lastSyncTime,
  });

  Settings copyWith({
    bool? isDarkMode,
    bool? enableSmartParsing,
    DateTime? lastSyncTime,
  }) {
    return Settings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      enableSmartParsing: enableSmartParsing ?? this.enableSmartParsing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}
