import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pilot_app/core/theme/app_theme.dart';
import 'package:pilot_app/core/router/app_router.dart';

/// Root widget do Pilot App. Navegação via go_router (APP-1001). APP-1008: tema, i18n.
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
      ],
      routerConfig: AppRouter.router,
    );
  }
}
