import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 提供全局 Auth 实例
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 提供当前用户状态的 Stream (用于监听登录/登出变化)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// 提供当前用户对象 (可能为 null)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user;
});

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  // 获取当前用户
  User? get currentUser => _auth.currentUser;

  // 注册
  Future<void> signUp(String email, String password) async {
    try {
      await _auth.signUp(email: email, password: password);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 登录
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // 登出
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 错误处理辅助方法
  Exception _handleAuthException(dynamic error) {
    if (error is AuthException) {
      // Supabase 返回的具体错误信息
      return Exception(error.message);
    } else {
      return Exception('未知错误: $error');
    }
  }
}