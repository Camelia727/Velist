import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/settings/presentation/settings_page.dart'; 

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      // Phase 3.5: Settings Route
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage()
      ),
    ],
  );
});