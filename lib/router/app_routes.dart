class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const emailLogin = '/email-login';
  static const conversations = '/chats';
  static const profile = '/profile';
  static const subscription = '/subscription';

  static const _chatBase = '/chat';
  static String chat(String id) => '$_chatBase/$id';

  // For GoRouter path pattern
  static const chatPattern = '/chat/:id';
}
