import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../content_store.dart';
import 'archive_extractor.dart';
import 'sword/sword_config.dart';
import 'sword/sword_dictionary_importer.dart';

/// Loads the bundled Easton's Bible Dictionary (a CrossWire SWORD module,
/// public domain — M.G. Easton, "Illustrated Bible Dictionary", 3rd ed.,
/// Thomas Nelson, 1897) into the content store on first use.
class BundledEastonImporter {
  BundledEastonImporter(this.store);

  final ContentStore store;

  static const String assetPath = 'assets/data/easton_sword.zip';
  static const String _abbreviation = 'EASTON';

  Future<bool> _alreadyInstalled() async {
    final rows = await (store.select(
      store.dictionaries,
    )..where((d) => d.abbreviation.equals(_abbreviation))).get();
    return rows.isNotEmpty;
  }

  /// Idempotent: extracts and imports the bundled module once.
  Future<void> ensureLoaded() async {
    if (await _alreadyInstalled()) return;

    final tempDir = await getTemporaryDirectory();
    final zipFile = File(
      p.join(tempDir.path, 'easton_sword_${const Uuid().v4()}.zip'),
    );
    final extractDir = Directory(
      p.join(tempDir.path, 'easton_sword_extract_${const Uuid().v4()}'),
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
        orElse: () => throw Exception(
          'No .conf file found in bundled Easton\'s module.',
        ),
      );
      final config = SwordConfig.parse(
        utf8.decode(await confFile.readAsBytes(), allowMalformed: true),
      );

      await store.transaction(() async {
        await SwordDictionaryImporter(
          store,
        ).importFromDirectory(extractDir, config);
      });
    } finally {
      if (await zipFile.exists()) await zipFile.delete();
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }
}
