import 'package:flutter_test/flutter_test.dart';

import 'package:tuazon_advmobprog/main.dart';

void main() {
  testWidgets('app displays the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TuazonAdvMobProg());

    expect(find.byType(TuazonAdvMobProg), findsOneWidget);
  });
}