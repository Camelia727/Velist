import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:uuid/uuid.dart';
import 'package:gap/gap.dart';
import '../../../data/services/database_service.dart';
import '../../../data/models/hive_models.dart';
import '../../task/providers/task_providers.dart'; // 引入 aiServiceProvider

class SuperInputBox extends HookConsumerWidget {
  const SuperInputBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Hooks 管理状态
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    // 新增：管理 AI 解析的加载状态
    final isProcessing = useState(false);

    // 平台判断
    final platform = Theme.of(context).platform;
    final isMac = platform == TargetPlatform.macOS;
    final isDesktop = isMac ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;

    // 自动聚焦
    useEffect(() {
      focusNode.requestFocus();
      return null;
    }, []);

    // 2. 核心提交逻辑 (接入 AI)
    Future<void> handleSubmit({bool keepOpen = false}) async {
      final text = controller.text.trim();
      if (text.isEmpty) {
        if (!keepOpen) Navigator.of(context).pop();
        return;
      }

      // 锁定 UI，防止重复提交
      isProcessing.value = true;

      try {
        // --- 核心变化：调用 AI 解析 ---
        // 调用 Provider 获取解析结果
        final parsedData = await ref.read(aiServiceProvider).parseTask(text);
        
        // ---------------------------

        // 3. 构建 Task 对象 (使用解析后的数据)
        final newTask = Task(
          uuid: const Uuid().v4(),
          title: parsedData.title,     // 使用 AI 提取的标题
          description: null,           // 暂时为空，后续可扩展
          dueDate: parsedData.dueDate, // 使用 AI 提取的日期
          hasTime: parsedData.hasTime, // 使用 AI 判断的时间标记
          tags: parsedData.tags,       // 使用 AI 提取的标签
          createdAt: DateTime.now(),
          isCompleted: false,
          priority: 0,
        );

        // 4. 持久化
        await ref.read(databaseServiceProvider).addTask(newTask);

        // 5. 交互反馈
        if (keepOpen) {
          controller.clear();
          // 如果想给用户一点反馈，可以在这里加个微小的震动 HapticFeedback.lightImpact();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        // 错误处理：如果 AI 挂了或者网络不通，至少不要闪退，可以考虑降级为普通保存
        debugPrint("Error creating task: $e");
      } finally {
        // 解锁 UI
        isProcessing.value = false;
        // 保持焦点 (如果是 keepOpen)
        if (keepOpen) focusNode.requestFocus();
      }
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: CallbackShortcuts(
          bindings: {
            // 只有在非处理状态下才响应快捷键
            if (!isProcessing.value) ...{
              const SingleActivator(LogicalKeyboardKey.enter, meta: true): () =>
                  handleSubmit(keepOpen: true),
              const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
                  handleSubmit(keepOpen: true),
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  Navigator.of(context).pop(),
            }
          },
          child: Container(
            width: MediaQuery.of(context).size.width > 700
                ? 600
                : MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 输入框
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  // 当正在处理时，禁止输入，变成只读
                  enabled: !isProcessing.value, 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(
                      color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => handleSubmit(keepOpen: false),
                  textInputAction: TextInputAction.done,
                ),
                
                const Gap(16),

                // 底部状态栏：正常提示 vs Loading 动画
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isProcessing.value
                      ? _buildProcessingState(context) // Loading 态
                      : _buildIdleState(context, isDesktop, isMac), // 正常态
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Loading 状态的 UI
  Widget _buildProcessingState(BuildContext context) {
    return Row(
      key: const ValueKey('processing'),
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const Gap(8),
        Text(
          "AI is thinking...", // 这里体现 Invisible AI 的存在感
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 之前的正常 UI 抽离出来
  Widget _buildIdleState(BuildContext context, bool isDesktop, bool isMac) {
    return Row(
      key: const ValueKey('idle'),
      children: [
        const _KeyHint(label: 'Enter', description: 'save'),
        const SizedBox(width: 12),
        if (isDesktop) ...[
          _KeyHint(
            label: isMac ? '⌘ Enter' : 'Ctrl Enter',
            description: 'save & keep open',
          ),
          const Spacer(),
          const _KeyHint(label: 'ESC', description: 'close'),
        ] else ...[
          const Spacer(),
        ]
      ],
    );
  }
}

class _KeyHint extends StatelessWidget {
  final String label;
  final String description;

  const _KeyHint({required this.label, required this.description});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          description,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      ],
    );
  }
}