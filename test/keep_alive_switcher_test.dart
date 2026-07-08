import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/ui/common/keep_alive_switcher.dart';

/// Stateful child whose counter reveals whether its State survived.
class _Counter extends StatefulWidget {
  const _Counter({required this.label});
  final String label;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => count++),
      child: Text('${widget.label}:$count'),
    );
  }
}

Widget _harness(String? active, {int maxAlive = 4}) {
  return MaterialApp(
    home: Scaffold(
      body: KeepAliveSwitcher<String>(
        active: active,
        maxAlive: maxAlive,
        builder: (context, value) => _Counter(label: value),
      ),
    ),
  );
}

void main() {
  testWidgets('preserves child state across switches', (tester) async {
    await tester.pumpWidget(_harness('a'));
    await tester.tap(find.text('a:0'));
    await tester.pump();
    expect(find.text('a:1'), findsOneWidget);

    // Switch away: 'a' stays mounted but offstage; 'b' becomes visible.
    await tester.pumpWidget(_harness('b'));
    expect(find.text('a:1', skipOffstage: false), findsOneWidget);
    expect(find.text('a:1'), findsNothing);
    expect(find.text('b:0'), findsOneWidget);

    // Switch back: 'a' kept its counter.
    await tester.pumpWidget(_harness('a'));
    expect(find.text('a:1'), findsOneWidget);
  });

  testWidgets('hidden children are not hit-testable', (tester) async {
    await tester.pumpWidget(_harness('a'));
    await tester.pumpWidget(_harness('b'));

    // Tapping where 'a' sits must not reach its offstage button.
    await tester.tap(find.text('b:0'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('a:1', skipOffstage: false), findsNothing);
    expect(find.text('b:1'), findsOneWidget);
  });

  testWidgets('evicts least recently shown beyond maxAlive', (tester) async {
    await tester.pumpWidget(_harness('a', maxAlive: 2));
    await tester.tap(find.text('a:0'));
    await tester.pump();

    await tester.pumpWidget(_harness('b', maxAlive: 2));
    await tester.pumpWidget(_harness('c', maxAlive: 2)); // evicts 'a'
    expect(find.text('a:1', skipOffstage: false), findsNothing);
    expect(find.text('b:0', skipOffstage: false), findsOneWidget);

    // Reopening 'a' starts fresh.
    await tester.pumpWidget(_harness('a', maxAlive: 2));
    expect(find.text('a:0'), findsOneWidget);
  });

  testWidgets('re-showing a child refreshes its recency', (tester) async {
    await tester.pumpWidget(_harness('a', maxAlive: 2));
    await tester.pumpWidget(_harness('b', maxAlive: 2));
    await tester.pumpWidget(_harness('a', maxAlive: 2)); // 'a' now newest
    await tester.pumpWidget(_harness('c', maxAlive: 2)); // evicts 'b'
    expect(find.text('a:0', skipOffstage: false), findsOneWidget);
    expect(find.text('b:0', skipOffstage: false), findsNothing);
  });

  testWidgets('null active keeps children alive offstage', (tester) async {
    await tester.pumpWidget(_harness('a'));
    await tester.tap(find.text('a:0'));
    await tester.pump();

    await tester.pumpWidget(_harness(null));
    expect(find.text('a:1', skipOffstage: false), findsOneWidget);
    expect(find.text('a:1'), findsNothing);

    await tester.pumpWidget(_harness('a'));
    expect(find.text('a:1'), findsOneWidget);
  });
}
