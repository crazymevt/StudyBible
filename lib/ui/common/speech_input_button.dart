import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../data/logging.dart';

/// Whether the `speech_to_text` plugin has an implementation on this platform.
/// It ships Android, iOS, macOS, web and (community) Windows backends, but
/// **not Linux** — the mic button hides itself there (per the TODO note).
bool get speechToTextSupported {
  if (kIsWeb) return true;
  return Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows;
}

/// A mic button that dictates OS speech-to-text into a field. On tap it starts
/// listening; recognized text is delivered to [onResult] (final phrases). Tap
/// again (or pause) to stop. Renders nothing on unsupported platforms so callers
/// can drop it into any toolbar unconditionally.
///
/// The widget owns its own [SpeechToText] session and initializes lazily on the
/// first tap, so fields that are never dictated into pay no init/permission
/// cost.
class SpeechInputButton extends StatefulWidget {
  /// Called with each recognized (final) phrase. Callers insert it into their
  /// controller with whatever spacing/formatting they need.
  final ValueChanged<String> onResult;

  /// Optional live partial transcript while listening (not yet finalized).
  final ValueChanged<String>? onPartial;

  final double? iconSize;
  final String idleTooltip;
  final String listeningTooltip;

  const SpeechInputButton({
    super.key,
    required this.onResult,
    this.onPartial,
    this.iconSize,
    this.idleTooltip = 'Dictate',
    this.listeningTooltip = 'Stop dictation',
  });

  @override
  State<SpeechInputButton> createState() => _SpeechInputButtonState();
}

class _SpeechInputButtonState extends State<SpeechInputButton> {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _listening = false;

  @override
  void dispose() {
    // Best-effort: stop any active session so the mic is released.
    if (_listening) {
      _speech.cancel();
    }
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    if (!_initialized) {
      try {
        _initialized = await _speech.initialize(
          onStatus: _onStatus,
          onError: (e) => _onError(e.errorMsg),
        );
      } catch (e, stack) {
        logError(e, stack, context: 'SpeechInputButton.initialize');
        _initialized = false;
      }
      if (!_initialized) {
        _showUnavailable();
        return;
      }
    }

    try {
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          if (text.isEmpty) return;
          if (result.finalResult) {
            widget.onResult(text);
          } else {
            widget.onPartial?.call(text);
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: widget.onPartial != null,
          cancelOnError: true,
          // Auto-stop after a short silence / a generous ceiling so a forgotten
          // session doesn't hold the mic open.
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 60),
        ),
      );
      if (mounted) setState(() => _listening = true);
    } catch (e, stack) {
      logError(e, stack, context: 'SpeechInputButton.listen');
      _showUnavailable();
    }
  }

  void _onStatus(String status) {
    // 'done' / 'notListening' mark the end of a session (pause auto-stop or an
    // explicit stop); reflect that in the icon.
    final ended = status == 'done' || status == 'notListening';
    if (ended && mounted && _listening) {
      setState(() => _listening = false);
    }
  }

  void _onError(String message) {
    if (mounted && _listening) setState(() => _listening = false);
  }

  void _showUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Dictation is unavailable. Check microphone permission and that '
          'on-device speech recognition is enabled.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!speechToTextSupported) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(_listening ? Icons.mic : Icons.mic_none),
      iconSize: widget.iconSize,
      color: _listening ? scheme.error : null,
      tooltip: _listening ? widget.listeningTooltip : widget.idleTooltip,
      onPressed: _toggle,
    );
  }
}
