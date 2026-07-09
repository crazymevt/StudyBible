import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/prophecy/prophecy.dart';
import '../domain/prophecy/prophecy_data.dart';
import '../domain/prophecy/prophecy_index.dart';

/// All curated Old Testament prophecies with their New Testament fulfillments,
/// consumed by the reader's Prophecies tool.
final propheciesProvider = Provider<List<Prophecy>>((ref) => prophecies);

/// The chapter → prophecies reverse index (see [buildProphecyChapterIndex]),
/// built once and cached so the Explorer passage page can look up the
/// prophecies touching a chapter without rescanning the dataset each open.
final prophecyChapterIndexProvider =
    Provider<Map<String, List<ProphecyChapterHit>>>(
  (ref) => buildProphecyChapterIndex(),
);
