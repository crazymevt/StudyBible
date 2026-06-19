import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter/material.dart';

void main() {
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }
  
  try {
    final controller = WebViewController()
      ..setBackgroundColor(Colors.black);
    print("Success");
  } catch (e) {
    print("Exception: $e");
  }
}
