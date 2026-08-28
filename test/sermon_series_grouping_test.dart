import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/achievement_service.dart';
import 'package:study_bible/app/sermon_providers.dart';
import 'package:study_bible/app/sync_service.dart';
import 'package:study_bible/app/user_providers.dart';
import 'package:study_bible/data/user_store.dart';
import 'package:study_bible/ui/sermons/sermons_panel.dart';

class _NoopAchievementService extends AchievementService {
  _NoopAchievementService(super.ref);
  @override
  Future<void> evaluateAchievements() async {}
}

String _delta(String text) => jsonEncode([
  {'insert': '$text\n'},
]);

Sermon _sermon(
  String id,
  String title,
  String? series, {
  int createdAt = 0,
  bool pinned = false,
}) => Sermon(
  id: id,
  createdAt: createdAt,
  updatedAt: createdAt,
  deviceId: 'A',
  deleted: false,
  title: title,
  series: series,
  content: _delta(title),
  contentPlain: title,
  pinned: pinned,
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

  group('sortSeriesGroupsByName', () {
    test('orders groups naturally by name, keeping No Series last', () {
      final groups = groupSermonsBySeries([
        _sermon('1', 'Zeal for Your House', 'Week 10'),
        _sermon('2', 'B', null),
        _sermon('3', 'Abide', 'Week 2'),
        _sermon('4', 'C', 'Advent'),
      ]);
      expect(sortSeriesGroupsByName(groups).map((g) => g.name), [
        'Advent',
        'Week 2',
        'Week 10',
        kNoSeriesLabel,
      ]);
      expect(
        sortSeriesGroupsByName(groups, descending: true).map((g) => g.name),
        ['Week 10', 'Week 2', 'Advent', kNoSeriesLabel],
      );
    });

    test('a section holding a pinned sermon sorts ahead of the rest', () {
      // Regression: section order is the only place pinning can show in the
      // grouped list, so sorting sections purely by name buried a pinned
      // sermon at the bottom whenever its series sorted late.
      final groups = groupSermonsBySeries([
        _sermon('1', 'Beta', 'Zeal', pinned: true),
        _sermon('2', 'Alpha', 'Advent'),
        _sermon('3', 'Gamma', 'Romans'),
      ]);
      expect(sortSeriesGroupsByName(groups).map((g) => g.name), [
        'Zeal',
        'Advent',
        'Romans',
      ]);
      // Still true sorting the other way.
      expect(
        sortSeriesGroupsByName(groups, descending: true).map((g) => g.name),
        ['Zeal', 'Romans', 'Advent'],
      );
    });

    test('pinned sections sort among themselves by name', () {
      final groups = groupSermonsBySeries([
        _sermon('1', 'Beta', 'Zeal', pinned: true),
        _sermon('2', 'Alpha', 'Advent', pinned: true),
        _sermon('3', 'Gamma', 'Romans'),
      ]);
      expect(sortSeriesGroupsByName(groups).map((g) => g.name), [
        'Advent',
        'Zeal',
        'Romans',
      ]);
    });

    test('a pinned sermon with no series stays in the trailing section', () {
      final groups = groupSermonsBySeries([
        _sermon('1', 'Beta', null, pinned: true),
        _sermon('2', 'Alpha', 'Zeal'),
      ]);
      expect(sortSeriesGroupsByName(groups).map((g) => g.name), [
        'Zeal',
        kNoSeriesLabel,
      ]);
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

    test('sorts naturally, so "Week 2" precedes "Week 10"', () async {
      final container = ProviderContainer(
        overrides: [
          allSermonsProvider.overrideWith(
            (ref) => Stream.value([
              _sermon('1', 'A', 'Week 10'),
              _sermon('2', 'B', 'Week 2'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(allSermonsProvider, (_, _) {});
      await container.read(allSermonsProvider.future);

      expect(container.read(sermonSeriesNamesProvider), ['Week 2', 'Week 10']);
    });
  });

  group('SermonActionNotifier series writes', () {
    late UserStore store;
    late ProviderContainer container;

    setUp(() {
      store = UserStore(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          userStoreProvider.overrideWithValue(store),
          deviceIdProvider.overrideWith((ref) async => 'A'),
          achievementServiceProvider.overrideWith(
            (ref) => _NoopAchievementService(ref),
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await store.close();
    });

    Future<Sermon> fetch(String id) => (store.select(
      store.sermons,
    )..where((t) => t.id.equals(id))).getSingle();

    test('createSermon and updateSermon store the series trimmed', () async {
      final actions = container.read(sermonActionProvider);
      final sermon = await actions.createSermon('A', series: ' Grace ');
      expect(sermon.series, 'Grace');

      await actions.updateSermon(sermon.id, series: ' Hope ');
      expect((await fetch(sermon.id)).series, 'Hope');
    });

    test('updateSermon clears the series on blank text', () async {
      // Regression: blank used to be mapped to null by the editor, which
      // updateSermon takes as "leave untouched" — clearing the field in the
      // editor never persisted.
      final actions = container.read(sermonActionProvider);
      final sermon = await actions.createSermon('A', series: 'Grace');

      await actions.updateSermon(sermon.id, series: '  ');
      expect((await fetch(sermon.id)).series, isNull);

      // And null still means "leave untouched".
      await actions.updateSermon(sermon.id, series: 'Grace');
      await actions.updateSermon(sermon.id, title: 'B');
      expect((await fetch(sermon.id)).series, 'Grace');
    });

    test(
      'renameSeries renames all spellings of the series and syncs',
      () async {
        final actions = container.read(sermonActionProvider);
        final a = await actions.createSermon('A', series: 'Advent');
        final b = await actions.createSermon('B', series: 'advent ');
        final c = await actions.createSermon('C', series: 'Romans');
        final d = await actions.createSermon('D');

        final count = await actions.renameSeries('Advent', ' Christmas ');
        expect(count, 2);

        final renamedA = await fetch(a.id);
        expect(renamedA.series, 'Christmas');
        expect((await fetch(b.id)).series, 'Christmas');
        // updatedAt must advance so the rename wins under sync LWW (>= because
        // both writes can land in the same millisecond).
        expect(renamedA.updatedAt, greaterThanOrEqualTo(a.updatedAt));
        // Other series and no-series sermons are untouched.
        expect((await fetch(c.id)).series, 'Romans');
        expect((await fetch(d.id)).series, isNull);
      },
    );

    test('renameSeries ignores deleted sermons and blank input', () async {
      final actions = container.read(sermonActionProvider);
      final a = await actions.createSermon('A', series: 'Advent');
      await actions.deleteSermon(a.id);

      expect(await actions.renameSeries('Advent', 'Christmas'), 0);
      expect((await fetch(a.id)).series, 'Advent');
      expect(await actions.renameSeries('', 'Christmas'), 0);
      expect(await actions.renameSeries('Advent', '   '), 0);
    });
  });

  group('sermonRowDiffersFromEditor', () {
    // The editor's remote-change watcher: true means "flag a conflict".
    test('a row matching the editor is not a conflict', () {
      expect(
        sermonRowDiffersFromEditor(
          row: _sermon('1', 'A', 'Advent'),
          contentJson: _delta('A'),
          titleText: 'A',
          seriesText: 'Advent',
        ),
        isFalse,
      );
    });

    test('an un-normalized stored series is not a conflict', () {
      // Regression: write-normalization arrived without a backfill, so rows
      // written by an older build (or an older peer) still hold ' Advent '
      // or ''. Comparing those raw against the editor's normalized text made
      // any unrelated remote update — a pin toggle, say — look like a remote
      // series edit and raised a spurious conflict banner.
      expect(
        sermonRowDiffersFromEditor(
          row: _sermon('1', 'A', ' Advent '),
          contentJson: _delta('A'),
          titleText: 'A',
          seriesText: ' Advent ',
        ),
        isFalse,
      );
      expect(
        sermonRowDiffersFromEditor(
          row: _sermon('1', 'A', ''),
          contentJson: _delta('A'),
          titleText: 'A',
          seriesText: '',
        ),
        isFalse,
      );
    });

    test('the editor trimming its own save is not a conflict', () {
      // The other direction: our write stored 'Advent' while the field still
      // holds the untrimmed text the user typed.
      expect(
        sermonRowDiffersFromEditor(
          row: _sermon('1', 'A', 'Advent'),
          contentJson: _delta('A'),
          titleText: 'A',
          seriesText: 'Advent ',
        ),
        isFalse,
      );
    });

    test('a genuine series change is still a conflict', () {
      expect(
        sermonRowDiffersFromEditor(
          row: _sermon('1', 'A', 'Christmas'),
          contentJson: _delta('A'),
          titleText: 'A',
          seriesText: 'Advent',
        ),
        isTrue,
      );
      // Clearing the series remotely, and setting one, both still register.
      expect(
        sermonRowDiffersFromEditor(
          row: _sermon('1', 'A', null),
          contentJson: _delta('A'),
          titleText: 'A',
          seriesText: 'Advent',
        ),
        isTrue,
      );
      expect(
        sermonRowDiffersFromEditor(
          row: _sermon('1', 'A', 'Advent'),
          contentJson: _delta('A'),
          titleText: 'A',
          seriesText: '  ',
        ),
        isTrue,
      );
    });

    test('content and title changes are still conflicts', () {
      expect(
        sermonRowDiffersFromEditor(
          row: _sermon('1', 'A', 'Advent'),
          contentJson: _delta('rewritten'),
          titleText: 'A',
          seriesText: 'Advent',
        ),
        isTrue,
      );
      expect(
        sermonRowDiffersFromEditor(
          row: _sermon('1', 'A', 'Advent'),
          contentJson: _delta('A'),
          titleText: 'B',
          seriesText: 'Advent',
        ),
        isTrue,
      );
    });
  });
}
