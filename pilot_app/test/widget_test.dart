import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilot_app/app.dart';
import 'package:pilot_app/core/config/app_config.dart';
import 'package:pilot_app/core/di/injection.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppConfig.ensureInitialized();
    await configureDependencies();
  });

  testWidgets('PilotApp builds and shows initial screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PilotApp());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
