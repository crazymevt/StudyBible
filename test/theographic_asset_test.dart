import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sanity checks over the real bundled theographic dataset, so a bad ETL run
/// (scripts/build_theographic.dart) fails CI instead of surfacing as broken
/// family links or out-of-range verse references in the People panel.
void main() {
  late Map<String, dynamic> data;
  late List books;
  late List people;
  late List events;

  setUpAll(() {
    final raw = File('assets/data/theographic.json').readAsStringSync();
    data = jsonDecode(raw) as Map<String, dynamic>;
    books = data['books'] as List;
    people = data['people'] as List;
    events = data['events'] as List;
  });

  test('has the full canon and a substantial dataset', () {
    expect(books.length, 66);
    expect(books.first, 'Genesis');
    expect(books.last, 'Revelation');
    expect(people.length, greaterThan(3000));
    expect(events.length, greaterThan(400));
    expect((data['groups'] as List), isNotEmpty);
  });

  test('every person link and verse ref is in range', () {
    void expectValidRef(dynamic r, String context) {
      final ref = r as List;
      expect(ref.length, 3, reason: context);
      expect(ref[0], inInclusiveRange(0, 65), reason: context);
      expect(ref[1], greaterThan(0), reason: context);
      expect(ref[2], greaterThan(0), reason: context);
    }

    for (final p in people.cast<Map<String, dynamic>>()) {
      final who = p['s'];
      expect(p['n'], isNotEmpty, reason: 'person $who');
      for (final key in ['f', 'm']) {
        if (p[key] != null) {
          expect(
            p[key],
            inInclusiveRange(0, people.length - 1),
            reason: 'person $who $key',
          );
        }
      }
      for (final partner in (p['pa'] as List? ?? const [])) {
        expect(
          partner,
          inInclusiveRange(0, people.length - 1),
          reason: 'person $who partner',
        );
      }
      for (final r in p['v'] as List) {
        expectValidRef(r, 'person $who verse');
      }
    }
    for (final e in events.cast<Map<String, dynamic>>()) {
      for (final pt in e['pt'] as List) {
        expect(
          pt,
          inInclusiveRange(0, people.length - 1),
          reason: 'event "${e['t']}" participant',
        );
      }
      for (final r in e['v'] as List) {
        expectValidRef(r, 'event "${e['t']}" verse');
      }
    }
  });

  test('Aaron is intact: family, bio, and Exodus references', () {
    final aaron = people.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['s'] == 'aaron_1',
    );
    expect(aaron['n'], 'Aaron');
    expect(aaron['f'], isNotNull);
    expect(people[aaron['f'] as int]['n'], 'Amram');
    expect(aaron['pa'], isNotEmpty);
    expect(aaron['b'], contains('eldest son of Amram'));
    // Markdown links must be reduced to their display text.
    expect(aaron['b'], isNot(contains('](')));
    // Exodus 4:14 is Aaron's first mention.
    expect((aaron['v'] as List).first, [1, 4, 14]);
  });

  test("Death of Moses' first verse is Deuteronomy 34:1, not Genesis 34:1", () {
    // Regression: an upstream book/verse-ID collision (both "34:1") once
    // linked this event to Dinah's story instead of Moses viewing the
    // promised land — corrected in build_theographic.dart's
    // _knownBadVerseLinks.
    final deathOfMoses = events.cast<Map<String, dynamic>>().firstWhere(
      (e) => e['t'] == 'Death of Moses',
    );
    expect((deathOfMoses['v'] as List).first, [4, 34, 1]);
  });

  test('Seth lived 912 years, per Genesis 5:8, not 1182', () {
    // Regression: upstream had Seth's deathYear 1182 years after his
    // birthYear instead of the 912 Genesis 5:8 states (his birthYear is
    // correct: Adam's -4004 + 130 per Gen. 5:3) — corrected in
    // build_theographic.dart's _knownBadDeathYears. Left in, this made Seth
    // outlive Methuselah on the People Timeline.
    final seth = people.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['s'] == 'seth_2504',
    );
    expect(seth['by'], -3874);
    expect(seth['dy'], -2962);
  });

  test('no person has a deathYear before their birthYear', () {
    for (final p in people.cast<Map<String, dynamic>>()) {
      final by = p['by'] as int?, dy = p['dy'] as int?;
      if (by == null || dy == null) continue;
      expect(
        by,
        lessThanOrEqualTo(dy),
        reason: 'person ${p['s']} (${p['n']}): by=$by dy=$dy',
      );
    }
  });

  test(
    "Samson, Ahaziah, and Jehoram's contradictory years are dropped, not guessed",
    () {
      // Regression: upstream had deathYear before birthYear for all three —
      // an impossible negative lifespan (Samson: -1090/-1101, an 11-year
      // span for a Nazarite judge who judged Israel for 20 years alone).
      // Unlike Seth, none has an explicit stated age to correct against, so
      // build_theographic.dart's _unreliableLifespans drops both fields
      // instead of asserting a guessed value.
      for (final slug in ['samson_2468', 'ahaziah_121', 'jehoram_803']) {
        final p = people.cast<Map<String, dynamic>>().firstWhere(
          (p) => p['s'] == slug,
        );
        expect(p['by'], isNull, reason: slug);
        expect(p['dy'], isNull, reason: slug);
      }
    },
  );

  test('Joshua lived 110 years, per Joshua 24:29, not 97', () {
    // Regression: upstream had Joshua's deathYear 97 years after his
    // birthYear instead of the 110 Josh. 24:29 states — corrected in
    // build_theographic.dart's _knownBadDeathYears.
    final joshua = people.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['s'] == 'joshua_1727',
    );
    expect(joshua['by'], -1521);
    expect(joshua['dy'], -1411);
  });

  test("Rachel's implausible birthYear is dropped, her deathYear kept", () {
    // Regression: upstream had Rachel's birthYear only 16 years before her
    // deathYear — impossible for a woman Jacob married as an adult who bore
    // two sons years apart before dying in Benjamin's birth (Gen. 35:16-19).
    // Her deathYear checks out (matches Benjamin's birthYear elsewhere in
    // this dataset), so only the birthYear is dropped — see
    // build_theographic.dart's _unreliableBirthYears.
    final rachel = people.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['s'] == 'rachel_2386',
    );
    expect(rachel['by'], isNull);
    expect(rachel['dy'], -1739);
  });

  test(
    "Manasseh (son of Hezekiah) and Ahaz's implausible years are dropped",
    () {
      // Regression: upstream gave Manasseh a 35-year lifespan, but 2 Kings
      // 21:1 says he began reigning at 12 and reigned 55 years — at least
      // 67. Ahaz's 47-year lifespan doesn't match any standard reading of 2
      // Kings 16:2 either. Neither has a single defensible replacement
      // value, so build_theographic.dart's _unreliableLifespans drops both
      // fields for each instead of guessing.
      for (final slug in ['manasseh_1930', 'ahaz_118']) {
        final p = people.cast<Map<String, dynamic>>().firstWhere(
          (p) => p['s'] == slug,
        );
        expect(p['by'], isNull, reason: slug);
        expect(p['dy'], isNull, reason: slug);
      }
    },
  );

  test('events are in chronological order and start at creation', () {
    final first = events.first as Map<String, dynamic>;
    expect(first['t'], contains('Creation'));
    num? last;
    for (final e in events.cast<Map<String, dynamic>>()) {
      final k = e['k'] as num?;
      if (k == null) continue;
      if (last != null) {
        expect(
          k,
          greaterThanOrEqualTo(last),
          reason: 'event "${e['t']}" out of order',
        );
      }
      last = k;
    }
  });
}
