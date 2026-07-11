// Build-time converter: Theographic Bible Metadata -> assets/data/theographic.json
//
// Source data: https://github.com/robertrouse/theographic-bible-metadata
// (json/people.json, json/events.json, json/peopleGroups.json,
// json/verses.json), CC BY-SA 4.0 by Robert Rouse / Viz.Bible.
// The generated asset is a derived dataset and remains CC BY-SA 4.0
// (see NOTICE); the app code around it is unaffected.
//
// Usage:
//   dart run scripts/build_theographic.dart            # downloads sources
//   dart run scripts/build_theographic.dart --src DIR  # use local json files
//   dart run scripts/build_theographic.dart --out FILE # default assets/data/theographic.json
//
// Downloads are cached in scratch/theographic/ so re-runs are cheap; delete
// that directory to force fresh data. (Sibling asset builders live in tool/:
// build_places.dart, build_naves_topical.dart.)
//
// Output shape (indexes into `people` are 0-based array positions):
//   { "books": [ "Genesis", ... 66 ... ],
//     "people": [ { "s": slug, "n": name, "dt": displayTitle, "g": gender,
//                   "a": "Also, Called", "by": birthYear, "dy": deathYear,
//                   "mn": minYear, "mx": maxYear, "f": fatherIdx, "m": motherIdx,
//                   "pa": [partnerIdx...], "b": "bio text",
//                   "v": [[bookIndex0Based, chapter, verse], ...] }, ... ],
//     "groups": [ { "n": name, "me": [personIdx...] }, ... ],
//     "events": [ { "t": title, "k": sortKey, "y": startYear,
//                   "pt": [personIdx...], "v": [[b, c, v], ...] }, ... ] }
//
// Years are ISO years (negative = BC). Fields are omitted when absent.

import 'dart:convert';
import 'dart:io';

const String kRawBase =
    'https://raw.githubusercontent.com/robertrouse/theographic-bible-metadata/master/json';

const List<String> kSourceFiles = [
  'people.json',
  'events.json',
  'peopleGroups.json',
  'verses.json',
];

const List<String> kBooks = [
  'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua',
  'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings',
  '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job',
  'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon', 'Isaiah',
  'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
  'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai',
  'Zechariah', 'Malachi', 'Matthew', 'Mark', 'Luke', 'John', 'Acts',
  'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
  'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
  '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
  '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation',
];

/// Known-bad verse links in the upstream dataset, corrected here so
/// re-running this script doesn't silently reintroduce them. Keyed by
/// (event title, 0-based book index, chapter, verse) since events don't
/// have stable ids across re-imports.
///
/// - 'Death of Moses' -> Genesis 34:1 (Dinah's story, unrelated) instead of
///   Deuteronomy 34:1 (Moses viewing the promised land before he dies) —
///   almost certainly a book/verse-ID collision upstream, since both verses
///   share the same chapter:verse "34:1". Left in, this sends "Read
///   passage" to the wrong book entirely.
const Set<(String, int, int, int)> _knownBadVerseLinks = {
  ('Death of Moses', 0, 34, 1),
};

/// Known-bad birth/death years in the upstream dataset, corrected here so
/// re-running this script doesn't silently reintroduce them. Keyed by
/// personLookup slug (stable across re-imports, unlike record ids).
///
/// - Seth's deathYear is -2692 upstream, 1182 years after his -3874
///   birthYear — but Genesis 5:8 states Seth lived 912 years, and his
///   birthYear checks out (Adam's -4004 + the 130 years of Gen. 5:3). The
///   correct deathYear is -3874 + 912 = -2962.
/// - Joshua's deathYear is -1424 upstream, 97 years after his -1521
///   birthYear — but Josh. 24:29 states he lived 110 years. His birthYear
///   checks out against Moses's (Moses born -1571, Exodus at Moses's age 80
///   puts it at -1491, when Joshua — a "young man" per Ex. 33:11 — would be
///   30, matching the traditional Exodus dating this dataset uses
///   elsewhere). The correct deathYear is -1521 + 110 = -1411.
const Map<String, int> _knownBadDeathYears = {
  'seth_2504': -2962,
  'joshua_1727': -1411,
};

/// Upstream birthYears with no reliable value, dropped (leaving deathYear
/// standing) rather than guessed at. Keyed by personLookup slug.
///
/// - Rachel's birthYear is -1755 upstream, only 16 years before her -1739
///   deathYear — implausible on its face for a woman Jacob married as an
///   adult (after 7 years' service, Gen. 29) and who bore two sons years
///   apart before dying in Benjamin's birth (Gen. 35:16-19). Her deathYear
///   checks out — it exactly matches Benjamin's birthYear elsewhere in this
///   dataset — so it's the birthYear that's wrong, and Genesis gives no
///   figure to correct it with.
const Set<String> _unreliableBirthYears = {'rachel_2386'};

/// Upstream birth/death year pairs with no reliable values at all, dropped
/// entirely rather than guessed at, so the People Timeline doesn't render an
/// impossible or contradicted lifespan. Keyed by personLookup slug.
///
/// - Samson (samson_2468): -1090/-1101, deathYear before birthYear. Judges
///   never states his age, so there's no anchor for a correction the way
///   Genesis gives one for Seth — and 11 years is implausible on its face
///   for a Nazarite who married, avenged his wife's death, and judged Israel
///   for 20 years (Judg. 13-16).
/// - Ahaziah of Judah (ahaziah_121) and his father Jehoram (jehoram_803):
///   -822/-844 and -802/-844, both deathYear before birthYear. 2 Kings 8:26
///   says Ahaziah was 22 when he began his one-year reign, and his successor
///   Joash's birthYear (-844, matching Ahaziah's dy here) hints the
///   deathYear may be right and the birthYear wrong — but that's a lead, not
///   a citable figure, so both are dropped.
/// - Manasseh, son of Hezekiah (manasseh_1930): -677/-642, a 35-year span.
///   2 Kings 21:1 says he began reigning at 12 and reigned 55 years, so he
///   lived at least 67 years — the data is missing over half his life.
/// - Ahaz (ahaz_118): -763/-716, a 47-year span. 2 Kings 16:2 gives 20 + 16
///   = 36 (this rests on a well-known textual crux in Kings — Ahaz's stated
///   age there would make him father Hezekiah at 11 — so the true figure is
///   disputed among scholars, but 47 doesn't match any standard reading).
const Set<String> _unreliableLifespans = {
  'samson_2468',
  'ahaziah_121',
  'jehoram_803',
  'manasseh_1930',
  'ahaz_118',
};

Future<void> main(List<String> args) async {
  String? srcDir;
  var outputPath = 'assets/data/theographic.json';
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--src':
        srcDir = args[++i];
      case '--out':
        outputPath = args[++i];
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        stderr.writeln(
            'Usage: dart run scripts/build_theographic.dart [--src DIR] [--out FILE]');
        exit(64);
    }
  }

  final sources = srcDir != null
      ? Directory(srcDir)
      : await _downloadSources(Directory('scratch/theographic'));

  Map<String, dynamic> readJsonFields(String name) {
    final raw = jsonDecode(
        File('${sources.path}/$name').readAsStringSync()) as List;
    // Airtable export shape: [{id, createdTime, fields: {...}}, ...]
    return {
      for (final rec in raw)
        (rec as Map<String, dynamic>)['id'] as String:
            rec['fields'] as Map<String, dynamic>,
    };
  }

  // Verse record id -> [bookIndex0Based, chapter, verse], decoded from the
  // zero-padded verseID ("01001001" = book 01, chapter 001, verse 001).
  final verseRef = <String, List<int>>{};
  for (final entry in readJsonFields('verses.json').entries) {
    final vid = entry.value['verseID'] as String?;
    if (vid == null || vid.length != 8) continue;
    final book = int.parse(vid.substring(0, 2)) - 1;
    if (book < 0 || book >= kBooks.length) continue;
    verseRef[entry.key] = [
      book,
      int.parse(vid.substring(2, 5)),
      int.parse(vid.substring(5, 8)),
    ];
  }

  List<List<int>> resolveVerses(dynamic recIds) {
    if (recIds is! List) return const [];
    final refs = [
      for (final id in recIds)
        if (verseRef[id] != null) verseRef[id]!,
    ];
    refs.sort((a, b) {
      for (var i = 0; i < 3; i++) {
        final c = a[i].compareTo(b[i]);
        if (c != 0) return c;
      }
      return 0;
    });
    return refs;
  }

  final peopleById = readJsonFields('people.json');
  // Stable output order: the dataset's own personID.
  final personIds = peopleById.keys.toList()
    ..sort((a, b) => (peopleById[a]!['personID'] as num)
        .compareTo(peopleById[b]!['personID'] as num));
  final personIndex = {
    for (var i = 0; i < personIds.length; i++) personIds[i]: i,
  };

  int? indexOfLink(dynamic link) {
    // Single-valued link fields are still exported as one-element arrays.
    if (link is! List || link.isEmpty) return null;
    return personIndex[link.first];
  }

  List<int> indexesOfLinks(dynamic links) {
    if (links is! List) return const [];
    return [
      for (final id in links)
        if (personIndex[id] != null) personIndex[id]!,
    ];
  }

  final people = <Map<String, dynamic>>[];
  for (final recId in personIds) {
    final f = peopleById[recId]!;
    // Every record must be emitted — `personIndex` positions are baked into
    // the family/participant links, so skipping one would shift the rest.
    var name = (f['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) name = (f['personLookup'] as String?) ?? recId;
    final displayTitle = (f['displayTitle'] as String?)?.trim() ?? name;
    final alsoCalled = (f['alsoCalled'] as String?)
        ?.split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(', ');
    final bio = _cleanBio(f['dictText']);
    final slug = f['personLookup'] as String? ?? recId;
    final isUnreliable = _unreliableLifespans.contains(slug);
    final birthYear = (isUnreliable || _unreliableBirthYears.contains(slug))
        ? null
        : _year(f['birthYear']);
    final deathYear = isUnreliable
        ? null
        : (_knownBadDeathYears[slug] ?? _year(f['deathYear']));
    final person = <String, dynamic>{
      's': slug,
      'n': name,
      if (displayTitle != name) 'dt': displayTitle,
      if (f['gender'] case final String gender) 'g': gender,
      if (alsoCalled != null && alsoCalled.isNotEmpty) 'a': alsoCalled,
      'by': ?birthYear,
      'dy': ?deathYear,
      'mn': ?_year(f['minYear']),
      'mx': ?_year(f['maxYear']),
      'f': ?indexOfLink(f['father']),
      'm': ?indexOfLink(f['mother']),
      if (indexesOfLinks(f['partners']).isNotEmpty)
        'pa': indexesOfLinks(f['partners']),
      'b': ?bio,
      'v': resolveVerses(f['verses']),
    };
    people.add(person);
  }

  final groups = <Map<String, dynamic>>[];
  for (final f in readJsonFields('peopleGroups.json').values) {
    final name = (f['groupName'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;
    final members = indexesOfLinks(f['members']);
    if (members.isEmpty) continue;
    groups.add({'n': name, 'me': members});
  }
  groups.sort((a, b) => (a['n'] as String).compareTo(b['n'] as String));

  final events = <Map<String, dynamic>>[];
  for (final f in readJsonFields('events.json').values) {
    final title = (f['title'] as String?)?.trim();
    if (title == null || title.isEmpty) continue;
    final verses = resolveVerses(f['verses'])
        .where((v) => !_knownBadVerseLinks
            .contains((title, v[0], v[1], v[2])))
        .toList();
    events.add({
      't': title,
      if (f['sortKey'] is num) 'k': f['sortKey'],
      if (_year(f['startDate']) != null) 'y': _year(f['startDate']),
      'pt': indexesOfLinks(f['participants']),
      'v': verses,
    });
  }
  events.sort((a, b) => ((a['k'] as num?) ?? double.maxFinite)
      .compareTo((b['k'] as num?) ?? double.maxFinite));

  final out = File(outputPath);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(jsonEncode({
    'books': kBooks,
    'people': people,
    'groups': groups,
    'events': events,
  }));

  final verseLinks =
      people.fold<int>(0, (sum, p) => sum + (p['v'] as List).length);
  stdout.writeln('Wrote $outputPath (${out.lengthSync()} bytes): '
      '${people.length} people ($verseLinks verse links), '
      '${groups.length} groups, ${events.length} events.');
}

/// Parses an ISO year that the dataset stores as a string ("-1574") or number.
int? _year(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

/// Joins the Easton paragraph array and reduces its markdown links
/// ("[Ex. 6:20](/exod#Exod.6.20)") to their display text — the app autolinks
/// plain references itself.
String? _cleanBio(dynamic dictText) {
  if (dictText is! List || dictText.isEmpty) return null;
  final joined = dictText.whereType<String>().join('\n\n').trim();
  if (joined.isEmpty) return null;
  return joined
      .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1)!)
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
}

Future<Directory> _downloadSources(Directory cache) async {
  cache.createSync(recursive: true);
  final client = HttpClient();
  try {
    for (final name in kSourceFiles) {
      final target = File('${cache.path}/$name');
      if (target.existsSync() && target.lengthSync() > 0) {
        stdout.writeln('Using cached ${target.path}');
        continue;
      }
      stdout.writeln('Downloading $name …');
      final request = await client.getUrl(Uri.parse('$kRawBase/$name'));
      final response = await request.close();
      if (response.statusCode != 200) {
        stderr.writeln('Failed to download $name: HTTP ${response.statusCode}');
        exit(1);
      }
      await response.pipe(target.openWrite());
    }
  } finally {
    client.close();
  }
  return cache;
}
