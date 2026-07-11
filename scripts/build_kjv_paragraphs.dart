// Build-time extractor: ph4.org's "AV" MyBible module -> paragraph-break
// verse positions for the bundled CrossWire KJV module.
//
// CrossWire's KJV SWORD module (assets/data/kjv_sword.zip) has no paragraph
// markup at all — its own mods.d/kjv.conf declares `Feature=NoParagraphs`,
// true of every KJV edition CrossWire hosts. ph4.org's "AV" MyBible module
// (King James Version w/ cross-references, 1914, A. J. Holman Company's Holman
// Home Bible — public domain) uses the same KJV versification and does carry
// real `<pb/>` paragraph markers. This script reads AV's paragraph positions
// and writes them out as a small (book, chapter, verse) coordinate list; only
// the positions are used; no text from AV is bundled or distributed.
// SwordBibleImporter applies the list to CrossWire's KJV text at import time
// (see its `paragraphBreaksAt` parameter), so the bundled KJV keeps its
// Strong's/morphology tagging and gets working paragraph view.
//
// Usage:
//   dart run scripts/build_kjv_paragraphs.dart              # downloads AV
//   dart run scripts/build_kjv_paragraphs.dart --src FILE   # use a local AV.SQLite3
//   dart run scripts/build_kjv_paragraphs.dart --out FILE   # default assets/data/kjv_paragraph_breaks.json
//
// Downloads are cached in scratch/kjv_paragraphs/ so re-runs are cheap;
// delete that directory to force a fresh download.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:study_bible/data/importer/sword/sword_versification.dart';
import 'package:study_bible/data/mybible_book_map.dart';

const String kAvDownloadUrl =
    'https://www.ph4.org/_dl.php?back=bbl&a=AV&b=mybible&c';

Future<void> main(List<String> args) async {
  String? srcFile;
  var outputPath = 'assets/data/kjv_paragraph_breaks.json';
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--src':
        srcFile = args[++i];
      case '--out':
        outputPath = args[++i];
      default:
        stderr.writeln('Unknown argument: ${args[i]}');
        stderr.writeln(
            'Usage: dart run scripts/build_kjv_paragraphs.dart [--src FILE] [--out FILE]');
        exit(64);
    }
  }

  final avPath = srcFile ?? await _downloadAv(Directory('scratch/kjv_paragraphs'));
  final db = sqlite3.open(avPath);

  final Map<int, String> bookNumberToOsisName = {};
  for (final entry in mybibleBookMap.entries) {
    bookNumberToOsisName[entry.key] = entry.value;
  }

  // Sanity check: AV's own per-book verse totals must match the KJV
  // versification's, so a book-numbering mismatch fails the build loudly
  // instead of silently shipping paragraph breaks at the wrong verses.
  final avCounts = <String, int>{};
  for (final row in db.select(
      'SELECT book_number, COUNT(*) AS c FROM verses GROUP BY book_number')) {
    final name = bookNumberToOsisName[row['book_number'] as int];
    if (name != null) avCounts[name] = row['c'] as int;
  }
  final expectedCounts = <String, int>{
    for (final b in [...kjvVersification.ot, ...kjvVersification.nt])
      b.name: b.verseCount,
  };
  // AV (an independent 1914 digitization) and the KJV versification we use
  // for CrossWire's module can genuinely disagree on a handful of verse
  // divisions in a given book (seen: Esther, a book with well-documented
  // verse-numbering variance across print traditions). Applying AV's
  // paragraph positions to such a book risks landing a break on the wrong
  // verse, so those books are excluded from the output entirely — the bundled
  // KJV simply has no paragraph breaks there — rather than guessing.
  final mismatchedBooks = <String>{};
  for (final entry in expectedCounts.entries) {
    final avCount = avCounts[entry.key];
    if (avCount != entry.value) {
      mismatchedBooks.add(entry.key);
      stderr.writeln(
          'Excluding ${entry.key} from paragraph breaks: KJV versification '
          'has ${entry.value} verses, AV has ${avCount ?? 0}.');
    }
  }

  final breaks = <String>[];
  for (final row in db.select(
      "SELECT book_number, chapter, verse FROM verses WHERE text LIKE '<pb/>%' "
      'ORDER BY book_number, chapter, verse')) {
    final name = bookNumberToOsisName[row['book_number'] as int];
    if (name == null || mismatchedBooks.contains(name)) continue;
    breaks.add('$name|${row['chapter']}|${row['verse']}');
  }
  db.close();

  final out = File(outputPath);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(jsonEncode(breaks));

  stdout.writeln(
      'Wrote $outputPath (${out.lengthSync()} bytes): ${breaks.length} paragraph breaks '
      'across ${expectedCounts.length - mismatchedBooks.length} of '
      '${expectedCounts.length} books '
      '(${mismatchedBooks.length} excluded: ${mismatchedBooks.join(', ')}).');
}

Future<String> _downloadAv(Directory cache) async {
  cache.createSync(recursive: true);
  final target = File('${cache.path}/AV.SQLite3');
  if (target.existsSync() && target.lengthSync() > 0) {
    stdout.writeln('Using cached ${target.path}');
    return target.path;
  }

  final zipPath = File('${cache.path}/av_download.zip');
  stdout.writeln('Downloading AV module …');
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(kAvDownloadUrl));
    final response = await request.close();
    if (response.statusCode != 200) {
      stderr.writeln('Failed to download AV module: HTTP ${response.statusCode}');
      exit(1);
    }
    await response.pipe(zipPath.openWrite());
  } finally {
    client.close();
  }

  // The download is a zip containing AV.SQLite3 (and AV.commentaries.SQLite3,
  // discarded). Extract just the Bible module.
  final bytes = zipPath.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final entry = archive.files.firstWhere(
    (f) => f.isFile && f.name.toLowerCase() == 'av.sqlite3',
    orElse: () => throw StateError(
        'AV.SQLite3 not found inside the downloaded archive.'),
  );
  target.writeAsBytesSync(entry.content as List<int>);
  zipPath.deleteSync();
  return target.path;
}
