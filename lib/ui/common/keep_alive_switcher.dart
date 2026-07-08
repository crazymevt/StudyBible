import 'package:flutter/widgets.dart';

/// Shows one child at a time (chosen by [active]) while keeping the most
/// recently used children alive offstage, so their widget state — scroll
/// positions, expanded sections, in-progress text — survives switching away
/// and back.
///
/// Hidden children are wrapped in [Offstage] + [TickerMode] (disabled) +
/// [ExcludeFocus]: they aren't painted, hit-tested, focusable, or animating,
/// and riverpod pauses their provider subscriptions until they're shown
/// again. At most [maxAlive] children are kept; beyond that the least
/// recently shown one is disposed (its state resets on next open).
class KeepAliveSwitcher<T extends Object> extends StatefulWidget {
  const KeepAliveSwitcher({
    super.key,
    required this.active,
    required this.builder,
    this.maxAlive = 4,
  });

  /// The child to show. When null, previously alive children stay mounted
  /// (offstage) so their state survives a temporary "nothing selected".
  final T? active;

  final Widget Function(BuildContext context, T value) builder;

  /// Upper bound on children kept alive, including the active one.
  final int maxAlive;

  @override
  State<KeepAliveSwitcher<T>> createState() => _KeepAliveSwitcherState<T>();
}

class _KeepAliveSwitcherState<T extends Object>
    extends State<KeepAliveSwitcher<T>> {
  /// Value → recency stamp. Insertion order is kept stable so Stack children
  /// don't reorder between builds; recency lives in the stamp values.
  final Map<T, int> _lastShown = {};
  int _stamp = 0;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    if (active != null) {
      _lastShown[active] = ++_stamp;
      while (_lastShown.length > widget.maxAlive) {
        T? oldest;
        var oldestStamp = _stamp;
        _lastShown.forEach((value, stamp) {
          if (value != active && stamp <= oldestStamp) {
            oldest = value;
            oldestStamp = stamp;
          }
        });
        if (oldest == null) break;
        _lastShown.remove(oldest);
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        for (final value in _lastShown.keys)
          KeyedSubtree(
            key: ValueKey(value),
            child: Offstage(
              offstage: value != active,
              child: TickerMode(
                enabled: value == active,
                child: ExcludeFocus(
                  excluding: value != active,
                  child: widget.builder(context, value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
