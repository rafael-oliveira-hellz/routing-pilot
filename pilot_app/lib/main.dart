import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/config/theme_mode_notifier.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/error/global_error_handler.dart';
import 'package:pilot_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AppConfig.ensureInitialized();
  setupGlobalErrorHandler();
  await configureDependencies();
  await serviceLocator<ThemeModeNotifier>().load();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const PilotApp());
}
