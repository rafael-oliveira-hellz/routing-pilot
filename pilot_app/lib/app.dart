import 'package:flutter/material.dart';
import 'package:pilot_app/core/config/theme_mode_notifier.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/theme/app_theme.dart';
import 'package:pilot_app/core/router/app_router.dart';
import 'package:pilot_app/l10n/app_localizations.dart';

/// Root widget do Pilot App. Navegação via go_router (APP-1001). APP-1008: tema, i18n.
class PilotApp extends StatefulWidget {
  const PilotApp({super.key});

  @override
  State<PilotApp> createState() => _PilotAppState();
}

class _PilotAppState extends State<PilotApp> {
  late final ThemeModeNotifier _themeNotifier;

  @override
  void initState() {
    super.initState();
    _themeNotifier = serviceLocator<ThemeModeNotifier>();
    _themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() => setState(() {});

  @override
  void dispose() {
    _themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pilot',
      debugShowCheckedModeBanner: true,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeNotifier.themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: AppRouter.router,
    );
  }
}
