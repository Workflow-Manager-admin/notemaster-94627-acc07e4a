import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_frontend/main.dart';

void main() {
  testWidgets('App builds and shows a title', (WidgetTester tester) async {
    await tester.pumpWidget(NoteMasterApp());

    // Verify that our app bar has the expected title.
    expect(find.text('Notemaster'), findsOneWidget);
    // Ensure the FAB ("add" button) is present.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
