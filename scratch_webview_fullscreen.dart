import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  final params = WebKitWebViewControllerCreationParams(
    mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    allowsInlineMediaPlayback: true,
  );
  
  final WebKitWebViewController controller = WebKitWebViewController(params);
  // print(controller.setAllowsBackForwardNavigationGestures);
}
