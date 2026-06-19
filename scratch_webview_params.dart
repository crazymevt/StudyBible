import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  final params = WebKitWebViewControllerCreationParams(
    allowsInlineMediaPlayback: true,
  );
  print(params);
}
