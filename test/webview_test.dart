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
  },
      // WebPlayerDialog embeds a webview_flutter WebViewWidget, whose platform
      // implementation is not registered in the headless flutter_test VM. This
      // needs an integration_test (real device/emulator) to run.
      skip: true);
}
