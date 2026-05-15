import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/core/providers/core_providers.dart';
import 'package:manus/data/data_sources/local/hive_service.dart';
import 'package:manus/presentation/theme/notifier/theme_notifier.dart';
import 'package:manus/router/app_router.dart';
import 'package:manus/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Attach logger to Riverpod observer so provider errors are logged
    ref.watch(loggerProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) {
        return MaterialApp.router(
          title: 'Manus',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: AppRouter.goRouter,
          // MaterialApp uses AnimatedTheme internally with
          // kThemeAnimationDuration (200ms) — cross-fade is automatic.
        );
      },
    );
  }
}
