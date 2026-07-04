import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/explorer/entity_link.dart';
import 'package:study_bible/domain/explorer/explorer_ref.dart';

void main() {
  group('buildEntityLinkUrl / parseEntityLinkUrl', () {
    test('round-trips a person ref', () {
      final url = buildEntityLinkUrl(const ExplorerRef.person(42, 'Moses'));
      expect(url, 'sbent:person|42');
      final parsed = parseEntityLinkUrl(url);
      expect(parsed, isNotNull);
      expect(parsed!.type, ExplorerEntityType.person);
      expect(parsed.id, 42);
    });

    test('round-trips place/event/topic', () {
      expect(parseEntityLinkUrl(buildEntityLinkUrl(const ExplorerRef.place(1, 'En Gedi')))!.type,
          ExplorerEntityType.place);
      expect(parseEntityLinkUrl(buildEntityLinkUrl(const ExplorerRef.event(2, 'Exodus')))!.type,
          ExplorerEntityType.event);
      expect(parseEntityLinkUrl(buildEntityLinkUrl(const ExplorerRef.topic(3, 'Faith')))!.type,
          ExplorerEntityType.topic);
    });

    test('rejects a non-sbent URL', () {
      expect(parseEntityLinkUrl('sbref:Genesis|1|1'), isNull);
      expect(parseEntityLinkUrl('https://example.com'), isNull);
    });

    test('rejects a malformed sbent URL', () {
      expect(parseEntityLinkUrl('sbent:person'), isNull);
      expect(parseEntityLinkUrl('sbent:person|notanumber'), isNull);
      expect(parseEntityLinkUrl('sbent:notatype|1'), isNull);
    });
  });

  group('extractEntityLinksFromDelta', () {
    String delta(List<Map<String, dynamic>> ops) => jsonEncode(ops);

    test('finds sbent links among ordinary text and other links', () {
      final json = delta([
        {'insert': 'See '},
        {
          'insert': 'Moses',
          'attributes': {'link': 'sbent:person|42'},
        },
        {'insert': ' and '},
        {
          'insert': 'Genesis 1:1',
          'attributes': {'link': 'sbref:Genesis|1|1'},
        },
        {
          'insert': 'En Gedi',
          'attributes': {'link': 'sbent:place|7'},
        },
        {'insert': '\n'},
      ]);

      final links = extractEntityLinksFromDelta(json);
      expect(links, [
        const ParsedEntityLink(ExplorerEntityType.person, 42),
        const ParsedEntityLink(ExplorerEntityType.place, 7),
      ]);
    });

    test('returns empty for plain text with no links', () {
      final json = delta([
        {'insert': 'Just some notes.\n'},
      ]);
      expect(extractEntityLinksFromDelta(json), isEmpty);
    });

    test('returns empty for empty or malformed content', () {
      expect(extractEntityLinksFromDelta(''), isEmpty);
      expect(extractEntityLinksFromDelta('not json'), isEmpty);
      expect(extractEntityLinksFromDelta('{"not": "a list"}'), isEmpty);
    });
  });
}
