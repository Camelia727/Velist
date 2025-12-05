import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitleBar extends StatelessWidget {
  final Color? backgroundColor;

  const WindowTitleBar({super.key, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    // 1. 如果是 Web 或 移动端，不需要标题栏，直接隐藏
    if (kIsWeb || (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    // 2. 这里的 AppTheme 颜色适配
    final brightness = Theme.of(context).brightness;

    // 3. macOS 布局：只有拖拽区域，没有按钮（系统红绿灯在左上角）
    if (Platform.isMacOS) {
      return Container(
        height: 28, // macOS 标准标题栏高度
        color: backgroundColor ?? Colors.transparent,
        child: const DragToMoveArea(
          child: SizedBox.expand(),
        ),
      );
    }

    // 4. Windows/Linux 布局：使用 window_manager 自带的 WindowCaption
    // 它包含了 最小化/最大化/关闭 按钮，并且支持拖拽
    return Container(
      height: 32, // Windows 标准高度
      color: backgroundColor ?? Colors.transparent,
      child: WindowCaption(
        brightness: brightness,
        backgroundColor: Colors.transparent,
        title: const SizedBox.shrink(), // 不显示文字标题
        // 自定义按钮图标颜色 (可选)
        // iconColor: Theme.of(context).iconTheme.color,
      ),
    );
  }
}