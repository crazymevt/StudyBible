import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reference/king_reign.dart';
import '../domain/reference/kings_data.dart';

/// The curated Kings & Reigns dataset, consumed by the reader's Reference
/// tool.
final kingReignsProvider = Provider<List<KingReign>>((ref) => kingReigns);
