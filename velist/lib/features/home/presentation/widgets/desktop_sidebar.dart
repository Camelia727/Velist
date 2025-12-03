import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        NavigationRail(
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          
          // 图标与文字设置
          labelType: NavigationRailLabelType.all,
          groupAlignment: -0.9, // 靠上对齐
          
          // 样式微调
          minWidth: 72,
          indicatorColor: Colors.transparent, // 去掉默认的胶囊背景，做极简风格
          
          // 选中状态：Teal 色，加粗
          selectedIconTheme: IconThemeData(color: theme.colorScheme.primary, size: 26),
          selectedLabelTextStyle: TextStyle(
            color: theme.colorScheme.primary, 
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.5,
          ),
          
          // 未选中状态：灰色
          unselectedIconTheme: IconThemeData(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 24),
          unselectedLabelTextStyle: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4), 
            fontSize: 12,
            height: 1.5,
          ),

          // 头部 Logo
          leading: Column(
            children: [
              const Gap(20),
              Icon(Icons.flash_on_rounded, size: 28, color: theme.colorScheme.primary),
              const Gap(30),
            ],
          ),

          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.inbox_rounded),
              label: Text('Inbox'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.wb_sunny_rounded),
              label: Text('Today'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.calendar_month_rounded),
              label: Text('Upcoming'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.done_all_rounded),
              label: Text('Done'),
            ),
          ],
        ),
        // 极细的分隔线
        VerticalDivider(
          thickness: 1, 
          width: 1, 
          color: theme.dividerTheme.color
        ),
      ],
    );
  }
}