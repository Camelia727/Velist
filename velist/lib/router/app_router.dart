import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:velist/features/auth/presentation/auth_page.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../core/widgets/sync_manager.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
          builder: (context, state, child) {
            return SyncManager(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            // Phase 3.5: Settings Route
            GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage()),
            GoRoute(
              path: '/auth',
              builder: (context, state) => const AuthPage(),
            )
          ])
    ],
  );
});
