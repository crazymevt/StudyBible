import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reference/covenant.dart';
import '../domain/reference/covenants_data.dart';
import '../domain/reference/king_reign.dart';
import '../domain/reference/kings_data.dart';
import '../domain/reference/measure.dart';
import '../domain/reference/measures_data.dart';
import '../domain/reference/named_group.dart';
import '../domain/reference/named_groups_data.dart';

/// The curated Kings & Reigns dataset, consumed by the reader's Reference
/// tool.
final kingReignsProvider = Provider<List<KingReign>>((ref) => kingReigns);

/// The curated Measures & Money dataset, consumed by the reader's Reference
/// tool.
final measuresProvider = Provider<List<Measure>>((ref) => measures);

/// The curated Covenants dataset, consumed by the reader's Reference tool.
final covenantsProvider = Provider<List<Covenant>>((ref) => covenants);

/// The curated Named Groups dataset (tribes/apostles/judges/prophets),
/// consumed by the reader's Reference tool.
final namedGroupsProvider =
    Provider<List<NamedGroupEntry>>((ref) => namedGroups);
