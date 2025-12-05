import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/services/sync_service.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);

    return Tooltip(
      message: _getTooltipMessage(status),
      child: InkWell(
        // 只有在 Idle 或 Error 状态下才允许点击
        onTap: (status == SyncStatus.syncing || status == SyncStatus.success)
            ? null
            : () {
                // 触发同步
                ref.read(syncServiceProvider).sync();
              },
        borderRadius: BorderRadius.circular(20), // 圆形点击反馈
        child: Padding(
          padding: const EdgeInsets.all(8.0), // 增加一点点击热区
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildIcon(context, status),
          ),
        ),
      ),
    );
  }

  String _getTooltipMessage(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return "Click to Sync";
      case SyncStatus.error:
        return "Sync Failed. Click to Retry";
      case SyncStatus.syncing:
        return "Syncing...";
      case SyncStatus.success:
        return "Up to date";
    }
  }

  Widget _buildIcon(BuildContext context, SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const Icon(
          Icons.sync,
          key: ValueKey('syncing'),
          size: 20,
          color: Colors.grey,
        )
            .animate(onPlay: (controller) => controller.repeat()) // 循环动画
            .rotate(duration: 1.seconds); // 旋转 1秒一圈

      case SyncStatus.success:
        return const Icon(
          Icons.check_circle_outline,
          key: ValueKey('success'),
          size: 20,
          color: Colors.green,
        ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack); // 弹跳出现

      case SyncStatus.error:
        return const Icon(
          Icons.error_outline,
          key: ValueKey('error'),
          size: 20,
          color: Colors.red,
        );

      case SyncStatus.idle:
        return const Icon(
          Icons.cloud_done_outlined,
          key: ValueKey('idle'),
          size: 20,
          color: Colors.grey, // 或者 Colors.transparent 如果你想平时隐藏它
        );
    }
  }
}
