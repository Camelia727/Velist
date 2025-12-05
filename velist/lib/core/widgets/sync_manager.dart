import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../data/services/sync_service.dart';

class SyncManager extends ConsumerStatefulWidget {
  final Widget child;
  const SyncManager({super.key, required this.child});

  @override
  ConsumerState<SyncManager> createState() => _SyncManagerState();
}

class _SyncManagerState extends ConsumerState<SyncManager> with WidgetsBindingObserver {
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 1. App 启动时，立即触发一次同步
    // 使用 addPostFrameCallback 确保在构建完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 2. 监听 App 生命周期 (前后台切换)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 当 App 从后台切回前台时，立即同步 (拉取最新数据)
      debugPrint("📱 App Resumed - Triggering Sync");
      _triggerSync();
    }
  }

  Future<void> _triggerSync() async {
    await ref.read(syncServiceProvider).sync();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}