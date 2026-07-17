import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/sermon_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/sermons/sermons_panel.dart';

String _delta(String text) => jsonEncode([
  {'insert': '$text\n'},
]);

Sermon _sermon(String id, String title, String? series, {int createdAt = 0}) =>
    Sermon(
      id: id,
      createdAt: createdAt,
      updatedAt: createdAt,
      deviceId: 'A',
      deleted: false,
      title: title,
      series: series,
      content: _delta(title),
      contentPlain: title,
      pinned: false,
    );

void main() {
  group('groupSermonsBySeries', () {
    test('groups case-insensitively and keeps first-seen spelling', () {
      final groups = groupSermonsBySeries([
        _sermon('1', 'A', 'Advent'),
        _sermon('2', 'B', 'advent '),
        _sermon('3', 'C', 'Romans'),
      ]);
      expect(groups, hasLength(2));
      expect(groups[0].name, 'Advent');
      expect(groups[0].sermons.map((s) => s.id), ['1', '2']);
      expect(groups[1].name, 'Romans');
    });

    test('sermons without a series go last under the No Series label', () {
      final groups = groupSermonsBySeries([
        _sermon('1', 'A', null),
        _sermon('2', 'B', '  '),
        _sermon('3', 'C', 'Romans'),
      ]);
      expect(groups.map((g) => g.name), ['Romans', kNoSeriesLabel]);
      expect(groups.last.sermons.map((s) => s.id), ['1', '2']);
    });

    test('groups follow the order of their best-ranked sermon', () {
      // Input is already sorted (as _visibleSermons guarantees); the group of
      // the earliest-appearing sermon must come first.
      final groups = groupSermonsBySeries([
        _sermon('1', 'A', 'Romans'),
        _sermon('2', 'B', 'Advent'),
        _sermon('3', 'C', 'Romans'),
      ]);
      expect(groups.map((g) => g.name), ['Romans', 'Advent']);
      expect(groups[0].sermons.map((s) => s.id), ['1', '3']);
    });

    test('empty input yields no groups', () {
      expect(groupSermonsBySeries(const []), isEmpty);
    });
  });

  group('sermonSeriesNamesProvider', () {
    test('dedupes case-insensitively, trims, drops blanks, sorts', () async {
      final container = ProviderContainer(
        overrides: [
          allSermonsProvider.overrideWith(
            (ref) => Stream.value([
              _sermon('1', 'A', 'Romans'),
              _sermon('2', 'B', 'advent'),
              _sermon('3', 'C', 'Advent '),
              _sermon('4', 'D', null),
              _sermon('5', 'E', '  '),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Listen before awaiting: reading a stream provider's .future without a
      // listener can hang under Riverpod 3.
      container.listen(allSermonsProvider, (_, _) {});
      await container.read(allSermonsProvider.future);

      expect(container.read(sermonSeriesNamesProvider), ['advent', 'Romans']);
    });
  });
}
