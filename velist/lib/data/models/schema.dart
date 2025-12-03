import 'package:drift/drift.dart';
import '../converters/string_list_converter.dart';

// 定义 Tasks 表
class Tasks extends Table {
  // 自增主键 (内部使用)
  IntColumn get id => integer().autoIncrement()();
  
  // 业务 ID
  TextColumn get uuid => text().unique()();
  
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get hasTime => boolean().withDefault(const Constant(false))();
  
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  
  // 默认创建时间
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  TextColumn get parentUuid => text().nullable()();
  
  // 使用转换器存储 List<String>
  TextColumn get tags => text().map(const StringListConverter())();
  
  IntColumn get priority => integer().withDefault(const Constant(0))();
}

// 定义 Settings 表
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get isDarkMode => boolean().withDefault(const Constant(false))();
  BoolColumn get enableSmartParsing => boolean().withDefault(const Constant(true))();
}