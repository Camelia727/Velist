import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = Isar.autoIncrement;

  bool isDarkMode;
  bool enableSmartParsing;

  Settings({
    this.isDarkMode = false,
    this.enableSmartParsing = true,
  });
}