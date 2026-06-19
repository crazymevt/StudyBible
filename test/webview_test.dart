import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/ui/reader/web_player_dialog.dart';

void main() {
  testWidgets('WebPlayer loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WebPlayerDialog(url: 'https://google.com'),
        ),
      ),
    );
  });
}
