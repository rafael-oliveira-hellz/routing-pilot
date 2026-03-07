import 'package:flutter/material.dart';
import 'package:pilot_app/core/theme/app_theme.dart';
import 'package:pilot_app/core/router/app_router.dart';

/// Root widget do Pilot App. Navegação via go_router (APP-1001).
class PilotApp extends StatelessWidget {
  const PilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pilot',
      debugShowCheckedModeBanner: true,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
