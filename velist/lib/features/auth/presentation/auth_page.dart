import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/widgets/window_title_bar.dart'; // [New] 引入标题栏
import '../../../data/services/auth_service.dart';

class AuthPage extends HookConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 状态管理
    final isRegistering = useState(false); // 默认为登录模式
    final isLoading = useState(false);

    // 输入控制器
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    // 提交逻辑 (保持不变)
    Future<void> submit() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入邮箱和密码')),
        );
        return;
      }

      isLoading.value = true;
      final authService = ref.read(authServiceProvider);

      try {
        if (isRegistering.value) {
          await authService.signUp(email, password);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('注册成功！请检查邮箱确认链接')),
            );
          }
        } else {
          await authService.signIn(email, password);
        }

        if (context.mounted) {
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    // 界面构建
    return Scaffold(
      body: Column(
        children: [
          // 1. 顶部拖拽区域 (Desktop)
          const WindowTitleBar(),
          
          // 2. 自定义导航栏 (与 SettingsPage 保持一致)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Gap(8),
                Text(
                  isRegistering.value ? "Create Account" : "Sign In", // 动态标题
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),

          // 3. 主要内容区域
          Expanded(
            child: Center(
              // 允许滚动以适应移动端键盘弹出
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  // 限制最大宽度，桌面端更美观
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Icon(
                        Icons.cloud_queue_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const Gap(32),

                      // 邮箱输入
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const Gap(16),

                      // 密码输入
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        onSubmitted: (_) => submit(),
                      ),
                      const Gap(24),

                      // 主按钮
                      FilledButton(
                        onPressed: isLoading.value ? null : submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isRegistering.value ? 'Sign Up & Login' : 'Login'),
                      ),
                      const Gap(16),

                      // 切换模式按钮
                      TextButton(
                        onPressed: isLoading.value
                            ? null
                            : () => isRegistering.value = !isRegistering.value,
                        child: Text(
                          isRegistering.value
                              ? 'Already have an account? Sign In'
                              : 'Don\'t have an account? Sign Up',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}