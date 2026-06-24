import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/sword/sword_config.dart';
import 'package:study_bible/data/importer/sword/sword_versification.dart';
import 'package:study_bible/data/importer/sword/sword_ztext_reader.dart';
import 'package:study_bible/data/importer/sword/sword_bible_importer.dart';
import 'package:study_bible/data/models/verse_segment.dart';

Uint8List _le32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();
Uint8List _le16(int v) =>
    (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List();
Uint8List _concat(List<List<int>> parts) {
  final b = BytesBuilder();
  for (final p in parts) {
    b.add(p);
  }
  return b.toBytes();
}

/// Build a single-block zText reader whose entries are [fragments] laid out at
/// the given testament-relative [slots] (every other slot is zero-length).
SwordZTextReader _reader(Map<int, String> slotToFragment) {
  // One compressed block holding all fragments concatenated.
  final order = slotToFragment.keys.toList()..sort();
  final buffer = StringBuffer();
  final offsets = <int, ({int offset, int len})>{};
  for (final slot in order) {
    final bytes = utf8.encode(slotToFragment[slot]!);
    offsets[slot] = (offset: utf8.encode(buffer.toString()).length, len: bytes.length);
    buffer.write(slotToFragment[slot]!);
  }
  final block = utf8.encode(buffer.toString());
  final comp = zlib.encode(block);

  final maxSlot = order.last;
  final verseRecords = <List<int>>[];
  for (var i = 0; i <= maxSlot; i++) {
    final e = offsets[i];
    verseRecords.add(e == null
        ? _concat([_le32(0), _le32(0), _le16(0)])
        : _concat([_le32(0), _le32(e.offset), _le16(e.len)]));
  }

  return SwordZTextReader(
    verseIndex: _concat(verseRecords),
    blockIndex: _concat([_le32(0), _le32(comp.length), _le32(block.length)]),
    textData: Uint8List.fromList(comp),
    compressType: SwordCompressType.zip,
  );
}

void main() {
  late ContentStore store;

  setUp(() => store = ContentStore(NativeDatabase.memory()));
  tearDown(() => store.close());

  final config = SwordConfig.parse('''
[KJV]
ModDrv=zText
SourceType=OSIS
CompressType=ZIP
BlockType=BOOK
Encoding=UTF-8
Lang=en
Versification=KJV
Description=Test King James
About=A test module.
''');

  final kjv = kjvVersification;

  // Genesis 1:1, 1:2 (OT) and Matthew 1:1 (NT) at their KJV index slots.
  SwordZTextReader otReader() => _reader({
        kjv.indexOf('OT', 0, 1, 1)!:
            'In the <w lemma="strong:H7225">beginning</w> God '
                '<transChange type="added">created</transChange> the heaven.'
                '<note>cf. John 1:1</note>',
        kjv.indexOf('OT', 0, 1, 2)!: 'And the earth was without form.',
      });
  SwordZTextReader ntReader() => _reader({
        kjv.indexOf('NT', 0, 1, 1)!:
            'The book of the genealogy of Jesus Christ.',
      });

  Future<List<Verse>> versesFor(String bookName) async {
    final book = await (store.select(store.books)
          ..where((b) => b.name.equals(bookName)))
        .getSingle();
    return (store.select(store.verses)
          ..where((v) => v.bookId.equals(book.id))
          ..orderBy([(v) => OrderingTerm(expression: v.verse)]))
        .get();
  }

  test('imports version metadata from the conf', () async {
    await SwordBibleImporter(store)
        .importBible(config, ot: otReader(), nt: ntReader());

    final version = await store.select(store.versions).getSingle();
    expect(version.id, 'KJV');
    expect(version.abbreviation, 'KJV');
    expect(version.name, 'Test King James');
    expect(version.language, 'en');
    expect(version.about, 'A test module.');
  });

  test('inserts only the books the module actually contains', () async {
    await SwordBibleImporter(store)
        .importBible(config, ot: otReader(), nt: ntReader());

    final books = await (store.select(store.books)
          ..orderBy([(b) => OrderingTerm(expression: b.bookOrder)]))
        .get();
    expect(books.map((b) => b.name), ['Genesis', 'Matthew']);
    expect(books.map((b) => b.testament), ['OT', 'NT']);
    expect(books.map((b) => b.bookOrder), [1, 2]);
  });

  test('decodes verse text, flattening markup and dropping notes', () async {
    await SwordBibleImporter(store)
        .importBible(config, ot: otReader(), nt: ntReader());

    final gen = await versesFor('Genesis');
    expect(gen.map((v) => v.verse), [1, 2]);
    expect(gen.first.textContent, 'In the beginning God created the heaven.');
    expect(gen.first.textContent, isNot(contains('John 1:1')));
  });

  test('stores Strong\'s, italic, and footnote segments', () async {
    await SwordBibleImporter(store)
        .importBible(config, ot: otReader(), nt: ntReader());

    final gen = await versesFor('Genesis');
    final segs = (jsonDecode(gen.first.segments) as List)
        .map((e) => VerseSegment.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(segs.firstWhere((s) => s.text == 'beginning').strongs, 'H7225');
    expect(segs.firstWhere((s) => s.text.trim() == 'created').isItalic, isTrue);
    final notes = segs.where((s) => s.isFootnote).toList();
    expect(notes.single.footnoteText, 'cf. John 1:1');
  });

  test('populates the FTS index', () async {
    await SwordBibleImporter(store)
        .importBible(config, ot: otReader(), nt: ntReader());

    final rows = await store.customSelect(
      "SELECT reference_id FROM content_search "
      "WHERE type = 'verse' AND content_search MATCH 'genealogy'",
    ).get();
    expect(rows, hasLength(1));
  });

  test('handles an NT-only module (null OT reader)', () async {
    await SwordBibleImporter(store).importBible(config, ot: null, nt: ntReader());

    final books = await store.select(store.books).get();
    expect(books.map((b) => b.name), ['Matthew']);
  });

  test('rejects unsupported versification', () async {
    final synodal = SwordConfig.parse(
        '[X]\nModDrv=zText\nSourceType=OSIS\nVersification=Synodal');
    expect(
      () => SwordBibleImporter(store).importBible(synodal, ot: otReader()),
      throwsUnsupportedError,
    );
  });

  test('throws when no verses are present, leaving no version shell', () async {
    final empty = _reader({kjv.indexOf('OT', 0, 1, 1)!: '   '});
    await expectLater(
      SwordBibleImporter(store).importBible(config, ot: empty),
      throwsA(isException),
    );
    expect(await store.select(store.versions).get(), isEmpty);
  });

  test('re-importing replaces prior rows', () async {
    final importer = SwordBibleImporter(store);
    await importer.importBible(config, ot: otReader(), nt: ntReader());
    await importer.importBible(config, ot: otReader(), nt: ntReader());

    expect(await store.select(store.versions).get(), hasLength(1));
    expect(await versesFor('Genesis'), hasLength(2));
  });
}
