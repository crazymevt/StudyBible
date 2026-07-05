import 'package:study_bible/data/content_store.dart' show Book;
import 'package:study_bible/domain/scripture/bible_reference_scanner.dart';

import 'entity_link.dart';
import 'explorer_ref.dart';

/// One scripture citation extracted from a document, normalized to the
/// chapter span it touches. "Rom 8:28-30" and "Rom 8" both become
/// Romans 8..8; "Gen 1:1-2:3" becomes Genesis 1..2 — matching the predicate
/// the Explorer's passage backlink cards have always used (a citation counts
/// for a chapter if its span covers it).
class ExtractedPassageReference {
  final String bookName;
  final int chapterStart;
  final int chapterEnd;
  const ExtractedPassageReference(
    this.bookName,
    this.chapterStart,
    this.chapterEnd,
  );

  @override
  bool operator ==(Object other) =>
      other is ExtractedPassageReference &&
      other.bookName == bookName &&
      other.chapterStart == chapterStart &&
      other.chapterEnd == chapterEnd;

  @override
  int get hashCode => Object.hash(bookName, chapterStart, chapterEnd);
}

/// Everything a document references, extracted once at index time: scripture
/// citations scanned from its plain text, and `sbent:` entity links read from
/// its Delta JSON. Both lists are deduplicated.
class ExtractedDocumentReferences {
  final List<ExtractedPassageReference> passages;
  final List<ParsedEntityLink> entities;
  const ExtractedDocumentReferences({
    required this.passages,
    required this.entities,
  });

  bool get isEmpty => passages.isEmpty && entities.isEmpty;
}

/// Extracts the references a sermon or notebook page makes, for the persisted
/// `document_references` index (see DocumentReferenceIndexer). [content] is
/// the stored Quill Delta JSON; [plainText] its plain-text projection
/// (`contentPlain`, or `deltaToPlainText(content)` for legacy rows) — the
/// caller supplies both because it already has them.
///
/// Passage citations are resolved against [books] (the primary active
/// version's book list — the same list the old live scan used); with an empty
/// book list no passages are extracted, only entity links.
ExtractedDocumentReferences extractDocumentReferences({
  required String content,
  required String plainText,
  required List<Book> books,
}) {
  final passages = <ExtractedPassageReference>{};
  if (books.isNotEmpty && plainText.isNotEmpty) {
    for (final m in BibleReferenceScanner.scan(plainText, books)) {
      passages.add(
        ExtractedPassageReference(
          m.book.name,
          m.chapter,
          m.endChapter ?? m.chapter,
        ),
      );
    }
  }

  final entities = <ParsedEntityLink>{};
  for (final l in extractEntityLinksFromDelta(content)) {
    // Passage links can't appear as sbent: links (they're not id-addressed —
    // see buildEntityLinkUrl), but guard anyway so a malformed link can't
    // store a meaningless row.
    if (l.type == ExplorerEntityType.passage) continue;
    entities.add(l);
  }

  return ExtractedDocumentReferences(
    passages: passages.toList(),
    entities: entities.toList(),
  );
}
