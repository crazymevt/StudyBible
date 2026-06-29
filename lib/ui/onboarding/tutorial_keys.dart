import 'package:flutter/widgets.dart';

/// Stable [GlobalKey]s marking the real shell widgets the interactive tutorial
/// spotlights. Attached in `main_shell.dart`; read by the coach-mark overlay in
/// `tutorial_overlay.dart`. A key may resolve to nothing on a given layout
/// (e.g. the tools rail does not exist on the compact/mobile layout) — the
/// overlay then falls back to a centered showcase card for that step.
final GlobalKey tutorialReaderKey = GlobalKey(debugLabel: 'tutorialReader');
final GlobalKey tutorialToolsRailKey = GlobalKey(debugLabel: 'tutorialToolsRail');
final GlobalKey tutorialSearchKey = GlobalKey(debugLabel: 'tutorialSearch');
final GlobalKey tutorialMenuKey = GlobalKey(debugLabel: 'tutorialMenu');
