import 'package:go_router/go_router.dart';
import 'package:manus/presentation/auth/email_login_screen.dart';
import 'package:manus/presentation/auth/login_screen.dart';
import 'package:manus/presentation/chat/chat_screen.dart';
import 'package:manus/presentation/conversations/conversations_screen.dart';
import 'package:manus/presentation/profile/profile_screen.dart';
import 'package:manus/presentation/splash/splash_screen.dart';
import 'package:manus/presentation/subscription/subscription_screen.dart';
import 'package:manus/router/app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter goRouter = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailLogin,
        builder: (_, _) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.conversations,
        builder: (_, _) => const ConversationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatPattern,
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return ChatScreen(conversationId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, _) => const SubscriptionScreen(),
      ),
    ],
  );
}
