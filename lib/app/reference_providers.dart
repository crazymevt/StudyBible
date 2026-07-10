import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reference/covenant.dart';
import '../domain/reference/covenants_data.dart';
import '../domain/reference/king_reign.dart';
import '../domain/reference/kings_data.dart';
import '../domain/reference/measure.dart';
import '../domain/reference/measures_data.dart';
import '../domain/reference/reference_index.dart';

/// The curated Kings & Reigns dataset, consumed by the reader's Reference
/// tool.
final kingReignsProvider = Provider<List<KingReign>>((ref) => kingReigns);

/// The curated Measures & Money dataset, consumed by the reader's Reference
/// tool.
final measuresProvider = Provider<List<Measure>>((ref) => measures);

/// The curated Covenants dataset, consumed by the reader's Reference tool.
final covenantsProvider = Provider<List<Covenant>>((ref) => covenants);

/// The chapter → Reference-entry reverse index (see
/// [buildReferenceChapterIndex]), built once and cached so the Explorer
/// passage page can look up the entries touching a chapter without
/// rescanning all four datasets each open.
final referenceChapterIndexProvider =
    Provider<Map<String, List<ReferenceChapterHit>>>(
      (ref) => buildReferenceChapterIndex(),
    );
