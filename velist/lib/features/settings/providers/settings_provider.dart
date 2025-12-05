import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../data/services/database_service.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
    final dbService = ref.watch(databaseServiceProvider);
    return SettingsNotifier(dbService);
});

class SettingsNotifier extends StateNotifier<Settings> {
    final DatabaseService _dbService;

    SettingsNotifier(this._dbService) : super(_dbService.getSettings());

    void toggleTheme(bool isDark) {
        // 1. 更新内存状态 (UI 立即响应)
        state = state.copyWith(isDarkMode: isDark);
        // 2. 持久化到数据库
        _dbService.updateTheme(isDark);
    }

    void toggleSmartParsing(bool isEnabled) {
        state = state.copyWith(enableSmartParsing: isEnabled);
        _dbService.updateSmartParsing(isEnabled);
    }
}
