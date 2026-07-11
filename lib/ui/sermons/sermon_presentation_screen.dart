import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/app_state.dart';
import '../../app/scripture_nav_providers.dart';
import '../../data/user_store.dart';
import '../../data/logging.dart';
import '../common/reference_autolink.dart';

class SermonPresentationScreen extends ConsumerStatefulWidget {
  final Sermon sermon;

  const SermonPresentationScreen({super.key, required this.sermon});

  @override
  ConsumerState<SermonPresentationScreen> createState() => _SermonPresentationScreenState();
}

class _SermonPresentationScreenState extends ConsumerState<SermonPresentationScreen> {
  late QuillController _controller;

  /// Passed explicitly to QuillEditor.basic below. Without it, the factory
  /// mints a brand-new default FocusNode on every call — i.e. every rebuild.
  /// This screen rebuilds whenever the presentation timer/clock toggles are
  /// watched providers change, so an implicit FocusNode churns on every such
  /// toggle. See the identical fix (and crash history) in
  /// sermon_editor_screen.dart.
  final _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Document document;
    try {
      final decoded = jsonDecode(widget.sermon.content);
      document = Document.fromJson(decoded);
    } catch (e, stack) {
      logError(e, stack, context: 'SermonPresentation: parse content');
      document = Document()..insert(0, widget.sermon.content);
    }
    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  /// Builds the scripture route from the presented document's references and
  /// starts navigation mode, returning to the reader.
  void _startScriptureNavigation() {
    final stops = scanSermonRoute(
      _controller.document.toPlainText(),
      autolinkBooks(ref),
    );
    if (stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No scripture references found in this sermon.'),
        ),
      );
      return;
    }
    final title =
        widget.sermon.title.isEmpty ? 'Untitled Sermon' : widget.sermon.title;
    ref
        .read(scriptureNavProvider.notifier)
        .start(sermonTitle: title, stops: stops);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.sermon.title),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ref.watch(showPresentationTimerProvider)
            ? Align(
                alignment: Alignment.center,
                child: _PresentationTimer(
                  size: ref.watch(presentationClockSizeProvider),
                ),
              )
            : null,
        actions: [
          if (ref.watch(showPresentationClockProvider))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(
                child: _PresentationClock(
                  size: ref.watch(presentationClockSizeProvider),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.route_outlined),
            tooltip: 'Navigate Scriptures',
            onPressed: _startScriptureNavigation,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
              ),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _editorFocusNode,
                config: QuillEditorConfig(
                  customLinkPrefixes: referenceLinkPrefixes,
                  customRecognizerBuilder:
                      referenceRecognizerBuilder(ref, context),
                  onLaunchUrl: (url) =>
                      handleReferenceLaunch(ref, context, url),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text style for presentation-mode overlays (clock, elapsed timer) per the
/// user's configured size: 'small', 'medium' (default), or 'large'.
TextStyle? _presentationOverlayStyle(BuildContext context, String size) {
  final textTheme = Theme.of(context).textTheme;
  final style = switch (size) {
    'small' => textTheme.titleMedium,
    'large' => textTheme.headlineMedium,
    _ => textTheme.headlineSmall,
  };
  return style?.copyWith(fontWeight: FontWeight.w600);
}

class _PresentationClock extends StatefulWidget {
  final String size;

  const _PresentationClock({required this.size});

  @override
  State<_PresentationClock> createState() => _PresentationClockState();
}

class _PresentationClockState extends State<_PresentationClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat.jm().format(_now),
      style: _presentationOverlayStyle(context, widget.size),
    );
  }
}

class _PresentationTimer extends StatefulWidget {
  final String size;

  const _PresentationTimer({required this.size});

  @override
  State<_PresentationTimer> createState() => _PresentationTimerState();
}

class _PresentationTimerState extends State<_PresentationTimer> {
  final DateTime _startedAt = DateTime.now();
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = DateTime.now().difference(_startedAt));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(_elapsed),
      style: _presentationOverlayStyle(context, widget.size),
    );
  }
}
