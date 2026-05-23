import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:govgate/common/role_selection_page.dart';

void main() {
  testWidgets('RoleSelectionPage renders all three role cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RoleSelectionPage(),
      ),
    );

    // Allow async initState work to settle
    await tester.pump();

    expect(find.text('Welcome to GovGate'), findsOneWidget);
    expect(find.text('Citizen'), findsOneWidget);
    expect(find.text('Government'), findsOneWidget);
    expect(find.text('Advertiser'), findsOneWidget);
  });
}
