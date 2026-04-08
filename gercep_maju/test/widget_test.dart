import 'package:flutter_test/flutter_test.dart';
import 'package:gercep_maju/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GerCepMajuApp());
    await tester.pump();
  });
}
