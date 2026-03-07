import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.ensureInitialized();
  await configureDependencies();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const PilotApp());
}
