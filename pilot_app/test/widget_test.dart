import 'package:flutter_test/flutter_test.dart';
import 'package:pilot_app/app.dart';

void main() {
  testWidgets('PilotApp loads and shows home placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const PilotApp());
    expect(find.text('Pilot App'), findsOneWidget);
    expect(find.text('Roteamento · ETA · Incidentes'), findsOneWidget);
  });
}
