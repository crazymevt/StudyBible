import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/home_widgets/widget_deep_link.dart';
import 'package:study_bible/domain/home_widgets/widget_payload.dart';

void main() {
  group('parseVerseDayReference', () {
    test('parses a simple reference', () {
      final r = parseVerseDayReference('John 3:16');
      expect(r, (bookName: 'John', chapter: 3, verse: 16));
    });

    test('keeps the start of a verse range', () {
      final r = parseVerseDayReference('Proverbs 3:5-6');
      expect(r, (bookName: 'Proverbs', chapter: 3, verse: 5));
    });

    test('handles numbered book names', () {
      final r = parseVerseDayReference('1 John 4:19');
      expect(r, (bookName: '1 John', chapter: 4, verse: 19));
    });

    test('rejects malformed references', () {
      expect(parseVerseDayReference('John'), isNull);
      expect(parseVerseDayReference('John 3'), isNull);
      expect(parseVerseDayReference('John x:y'), isNull);
      expect(parseVerseDayReference(''), isNull);
    });
  });

  group('buildVerseOfTheDayPayload', () {
    test('emits every verse with a deep link', () {
      final payload = buildVerseOfTheDayPayload([
        (reference: 'John 3:16', text: 'For God so loved the world…'),
        (reference: 'Psalm 23:1', text: 'The Lord is my shepherd…'),
      ]);
      final verses = payload['verses'] as List;
      expect(verses, hasLength(2));
      final first = verses.first as Map;
      expect(first['reference'], 'John 3:16');
      expect(first['uri'], 'studybible://read?book=John&chapter=3&verse=16');
    });

    test('omits uri when the reference cannot be parsed', () {
      final payload = buildVerseOfTheDayPayload([
        (reference: 'not a reference', text: 'text'),
      ]);
      final first = (payload['verses'] as List).first as Map;
      expect(first.containsKey('uri'), isFalse);
      expect(first['text'], 'text');
    });
  });

  group('buildUpcomingActionsPayload', () {
    ActionSource action(
      String id, {
      int? dueAt,
      int? completedAt,
      bool deleted = false,
    }) =>
        (
          id: id,
          title: 'Action $id',
          dueAt: dueAt,
          completedAt: completedAt,
          deleted: deleted,
        );

    test('filters to open items with a due time, soonest first, capped', () {
      final now = DateTime(2026, 7, 8, 12).millisecondsSinceEpoch;
      final hour = Duration.millisecondsPerHour;
      final payload = buildUpcomingActionsPayload([
        action('completed', dueAt: now + hour, completedAt: now),
        action('deleted', dueAt: now + hour, deleted: true),
        action('no-due'),
        for (var i = 7; i >= 1; i--) action('a$i', dueAt: now + i * hour),
      ], nowMs: now);

      final items = payload['items'] as List;
      expect(items, hasLength(kWidgetListCap));
      expect(
        items.map((it) => (it as Map)['id']),
        ['a1', 'a2', 'a3', 'a4', 'a5'],
      );
      expect(payload['uri'], 'studybible://actions');
    });

    test('flags overdue items and formats the due label', () {
      final due = DateTime(2026, 7, 8, 15, 30).millisecondsSinceEpoch;
      final payload = buildUpcomingActionsPayload(
        [action('late', dueAt: due)],
        nowMs: due + 1,
      );
      final item = (payload['items'] as List).single as Map;
      expect(item['overdue'], isTrue);
      expect(item['dueLabel'], 'Jul 8, 2026 · 3:30 PM');
    });

    test('empty input produces an empty items list', () {
      final payload = buildUpcomingActionsPayload([], nowMs: 0);
      expect(payload['items'], isEmpty);
    });
  });

  group('buildRibbonsPayload', () {
    RibbonSource ribbon(
      String book,
      int chapter,
      int verse, {
      String label = '',
      int updatedAt = 0,
    }) =>
        (
          bookName: book,
          chapter: chapter,
          verse: verse,
          label: label,
          updatedAt: updatedAt,
        );

    test('sorts newest first, caps, and builds references and links', () {
      final payload = buildRibbonsPayload([
        for (var i = 1; i <= 7; i++) ribbon('Genesis', i, 1, updatedAt: i),
      ]);
      final items = payload['items'] as List;
      expect(items, hasLength(kWidgetListCap));
      final first = items.first as Map;
      expect(first['reference'], 'Genesis 7:1');
      expect(first['uri'], 'studybible://read?book=Genesis&chapter=7&verse=1');
    });

    test('url-encodes book names with spaces', () {
      final payload = buildRibbonsPayload([ribbon('1 Kings', 2, 3)]);
      final first = (payload['items'] as List).first as Map;
      // Uri(queryParameters:) form-encodes spaces as '+'; parseWidgetDeepLink
      // decodes them back (covered by the round-trip test above).
      expect(first['uri'], 'studybible://read?book=1+Kings&chapter=2&verse=3');
    });
  });

  group('parseWidgetDeepLink', () {
    test('round-trips a read link with a spaced book name', () {
      final uri = buildReadVerseUri(bookName: '1 Kings', chapter: 2, verse: 3);
      final link = parseWidgetDeepLink(uri);
      expect(
        link,
        isA<ReadVerseDeepLink>()
            .having((l) => l.bookName, 'bookName', '1 Kings')
            .having((l) => l.chapter, 'chapter', 2)
            .having((l) => l.verse, 'verse', 3),
      );
    });

    test('parses a chapter-only read link', () {
      final link =
          parseWidgetDeepLink(Uri.parse('studybible://read?book=John&chapter=3'));
      expect(
        link,
        isA<ReadVerseDeepLink>().having((l) => l.verse, 'verse', isNull),
      );
    });

    test('parses the actions link', () {
      expect(
        parseWidgetDeepLink(buildActionsUri()),
        isA<OpenActionsDeepLink>(),
      );
    });

    test('rejects foreign schemes, unknown hosts, and bad params', () {
      expect(parseWidgetDeepLink(Uri.parse('https://read?book=John&chapter=3')),
          isNull);
      expect(parseWidgetDeepLink(Uri.parse('studybible://nope')), isNull);
      expect(parseWidgetDeepLink(Uri.parse('studybible://read?book=John')),
          isNull);
      expect(
          parseWidgetDeepLink(
              Uri.parse('studybible://read?book=&chapter=3&verse=16')),
          isNull);
      expect(
          parseWidgetDeepLink(
              Uri.parse('studybible://read?book=John&chapter=0')),
          isNull);
    });
  });
}
