import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../content_store.dart';
import 'archive_extractor.dart';
import 'sword/sword_bible_importer.dart';
import 'sword/sword_config.dart';

/// Loads the bundled King James Version (a CrossWire SWORD module — the same
/// KJV2003-project text, with Strong's numbers and morphology, that the
/// app's "Quick Install KJV" onboarding flow already fetches) into the
/// content store on first use.
///
/// CrossWire's module has no paragraph markup at all (its own conf declares
/// `Feature=NoParagraphs`); [_paragraphBreaksAssetPath] supplies paragraph
/// break positions sourced separately (see scripts/build_kjv_paragraphs.dart)
/// and applied via [SwordBibleImporter]'s `paragraphBreaksAt`.
class BundledKjvImporter {
  BundledKjvImporter(this.store);

  final ContentStore store;

  static const String assetPath = 'assets/data/kjv_sword.zip';
  static const String _paragraphBreaksAssetPath =
      'assets/data/kjv_paragraph_breaks.json';
  static const String _abbreviation = 'KJV';

  Future<bool> _alreadyInstalled() async {
    final rows = await (store.select(
      store.versions,
    )..where((v) => v.abbreviation.equals(_abbreviation))).get();
    return rows.isNotEmpty;
  }

  /// Idempotent: extracts and imports the bundled module once.
  Future<void> ensureLoaded() async {
    if (await _alreadyInstalled()) return;

    final breaksRaw = await rootBundle.loadString(_paragraphBreaksAssetPath);
    final paragraphBreaksAt = (jsonDecode(breaksRaw) as List).cast<String>().toSet();

    final tempDir = await getTemporaryDirectory();
    final zipFile = File(
      p.join(tempDir.path, 'kjv_sword_${const Uuid().v4()}.zip'),
    );
    final extractDir = Directory(
      p.join(tempDir.path, 'kjv_sword_extract_${const Uuid().v4()}'),
    );
    try {
      final byteData = await rootBundle.load(assetPath);
      await zipFile.writeAsBytes(byteData.buffer.asUint8List());

      final extractedFiles = await ArchiveExtractor.extractArchive(
        zipFile,
        extractDir,
      );
      final confFile = extractedFiles.firstWhere(
        (f) => f.path.toLowerCase().endsWith('.conf'),
        orElse: () =>
            throw Exception('No .conf file found in bundled KJV module.'),
      );
      final config = SwordConfig.parse(
        utf8.decode(await confFile.readAsBytes(), allowMalformed: true),
      );

      await store.transaction(() async {
        await SwordBibleImporter(store).importFromDirectory(
          extractDir,
          config,
          paragraphBreaksAt: paragraphBreaksAt,
        );
      });
    } finally {
      if (await zipFile.exists()) await zipFile.delete();
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }
}
