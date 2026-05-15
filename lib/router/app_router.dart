import 'package:go_router/go_router.dart';
import 'package:manus/presentation/home/home_screen.dart';
import 'package:manus/router/app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter goRouter = GoRouter(
    initialLocation: AppRoutes.homeScreen,
    routes: [
      GoRoute(
        path: AppRoutes.homeScreen,
        builder: (context, state) {
          return const HomeScreen();
        },
      ),
    ],
  );
}
