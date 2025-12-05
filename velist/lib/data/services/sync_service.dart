import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import 'auth_service.dart';

enum SyncStatus { idle, syncing, error, success }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final auth = ref.watch(authServiceProvider);
  return SyncService(db, auth, ref);
});

class SyncService {
  final DatabaseService _db;
  final AuthService _auth;
  final Ref _ref;
  final SupabaseClient _supabase = Supabase.instance.client;

  SyncService(this._db, this._auth, this._ref);

  /// 执行完整同步 (Push + Pull)
  Future<void> sync() async {
    final user = _auth.currentUser;
    if (user == null) return; // 未登录不需同步

    final currentStatus = _ref.read(syncStatusProvider);
    if (currentStatus == SyncStatus.syncing) return;   // 防止重复触发

    _updateSyncStatus(SyncStatus.syncing);
    debugPrint("🔄 Sync Started...");

    try {
      // 1. PUSH: 上传本地未同步的修改
      await _pushLocalChanges(user.id);

      // 2. PULL: 下载云端的新修改
      await _pullRemoteChanges(user.id);
      
      // 3. 更新同步时间戳
      await _db.updateLastSyncTime(DateTime.now().toUtc());
      
      debugPrint("✅ Sync Completed.");

      _updateSyncStatus(SyncStatus.success);

      Future.delayed(const Duration(seconds: 2), () {
        _updateSyncStatus(SyncStatus.idle);
      });
    } catch (e) {
      debugPrint("❌ Sync Failed: $e");
      _updateSyncStatus(SyncStatus.error);
    }
  }

  void _updateSyncStatus(SyncStatus status) {
    _ref.read(syncStatusProvider.notifier).state = status;
  }

  Future<void> _pushLocalChanges(String userId) async {
    final unsyncedTasks = _db.getUnsyncedTasks();
    if (unsyncedTasks.isEmpty) return;

    debugPrint("⬆️ Pushing ${unsyncedTasks.length} local tasks...");

    // 转换为 Supabase 需要的 JSON List
    final updates = unsyncedTasks.map((t) => t.toJson(userId: userId)).toList();

    // 执行 Upsert (存在则更新，不存在则插入)
    // onConflict: 如果 uuid 相同就更新
    await _supabase.from('tasks').upsert(updates, onConflict: 'uuid');

    // 标记本地为已同步
    await _db.markTasksAsSynced(unsyncedTasks.map((t) => t.uuid).toList());
  }

  Future<void> _pullRemoteChanges(String userId) async {
    final lastSync = _db.getLastSyncTime();
    
    // 构建查询
    var query = _supabase.from('tasks').select();
    
    // 如果有上次同步时间，只拉取该时间之后更新的数据 (增量同步)
    // 否则拉取所有数据 (首次同步)
    if (lastSync != null) {
      // 使用 toIso8601String 确保格式正确，Supabase 需要 UTC 时间
      query = query.gt('updated_at', lastSync.toIso8601String());
    }

    // 执行查询
    final List<dynamic> remoteData = await query;
    
    if (remoteData.isEmpty) return;
    debugPrint("⬇️ Pulling ${remoteData.length} remote tasks...");

    // 逐条保存到本地
    for (var data in remoteData) {
      await _db.saveRemoteTask(data);
    }
  }
}