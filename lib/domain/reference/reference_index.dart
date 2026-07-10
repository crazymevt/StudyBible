import 'covenant.dart';
import 'covenants_data.dart';
import 'king_reign.dart';
import 'kings_data.dart';
import 'measure.dart';
import 'measures_data.dart';
import 'named_group.dart';
import 'named_groups_data.dart';

/// Which of the four Reference tabs a [ReferenceChapterHit] came from.
enum ReferenceKind {
  kingReign('Kings & Reigns'),
  measure('Measures & Money'),
  covenant('Covenants'),
  namedGroup('Named Groups');

  const ReferenceKind(this.label);

  final String label;
}

/// One Reference entry that cites a particular chapter. [explorerPersonId]
/// is only non-null for the small hand-verified subset (see
/// [KingReign.explorerPersonId]/[NamedGroupEntry.explorerPersonId]) — the
/// Explorer passage page uses it to decide whether the hit is tappable.
class ReferenceChapterHit {
  final ReferenceKind kind;
  final String title;
  final int? explorerPersonId;
  final List<int> verses;

  const ReferenceChapterHit({
    required this.kind,
    required this.title,
    this.explorerPersonId,
    required this.verses,
  });
}

/// Map key for a chapter, e.g. `2 Kings|18`.
String referenceChapterKey(String book, int chapter) => '$book|$chapter';

final RegExp _passageExp = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

class _MutableHit {
  final ReferenceKind kind;
  final String title;
  final int? explorerPersonId;
  final Set<int> verses = {};
  _MutableHit(this.kind, this.title, this.explorerPersonId);
}

/// Builds the chapter → Reference-entry reverse index once from the four
/// curated datasets, so the Explorer passage page can show which Reference
/// entries touch a chapter with an O(1) lookup instead of scanning every
/// dataset on each page open. Keyed by [referenceChapterKey]. Mirrors
/// `buildProphecyChapterIndex` in `lib/domain/prophecy/prophecy_index.dart`;
/// an entry cited more than once within the same chapter (e.g. a king with
/// two citations landing in the same chapter) appears once with all its
/// verses merged.
Map<String, List<ReferenceChapterHit>> buildReferenceChapterIndex({
  List<KingReign> kings = kingReigns,
  List<Measure> measureList = measures,
  List<Covenant> covenantList = covenants,
  List<NamedGroupEntry> namedGroupList = namedGroups,
}) {
  final byKey = <String, Map<String, _MutableHit>>{};

  void record(
    String entryKey,
    ReferenceKind kind,
    String title,
    int? explorerPersonId,
    String passage,
  ) {
    final m = _passageExp.firstMatch(passage.trim());
    if (m == null) return;
    final book = m.group(1)!.trim();
    final chapter = int.parse(m.group(2)!);
    final verse = int.tryParse(m.group(3) ?? '') ?? 1;
    final hit = byKey
        .putIfAbsent(referenceChapterKey(book, chapter), () => {})
        .putIfAbsent(
          entryKey,
          () => _MutableHit(kind, title, explorerPersonId),
        );
    hit.verses.add(verse);
  }

  for (final k in kings) {
    for (final r in k.citations) {
      record(
        'kingReign|${k.id}',
        ReferenceKind.kingReign,
        k.name,
        k.explorerPersonId,
        r,
      );
    }
  }
  for (final m in measureList) {
    for (final r in m.citations) {
      record('measure|${m.id}', ReferenceKind.measure, m.name, null, r);
    }
  }
  for (final c in covenantList) {
    for (final r in c.citations) {
      record('covenant|${c.id}', ReferenceKind.covenant, c.name, null, r);
    }
  }
  for (final e in namedGroupList) {
    for (final r in e.citations) {
      record(
        'namedGroup|${e.id}',
        ReferenceKind.namedGroup,
        e.name,
        e.explorerPersonId,
        r,
      );
    }
  }

  return {
    for (final entry in byKey.entries)
      entry.key: [
        for (final h in entry.value.values)
          ReferenceChapterHit(
            kind: h.kind,
            title: h.title,
            explorerPersonId: h.explorerPersonId,
            verses: h.verses.toList()..sort(),
          ),
      ]..sort((a, b) => a.title.compareTo(b.title)),
  };
}
