import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Files that live in the app data directory and should be carried over from
/// the legacy location on first run (Linux only).
const _migratableFiles = ['content.db', 'user.db', 'device_id.txt'];

Future<void>? _migration;

/// Directory for app-internal data: the content and user databases, the device
/// id, and the default sync folder.
///
/// **Linux only** uses [getApplicationSupportDirectory] (backed by
/// `XDG_DATA_HOME`), which is persistent and works inside the Flatpak sandbox.
/// The Documents dir relies on the optional `xdg-user-dir` tool and is not a
/// stable, persistent location under Flatpak, so a downloaded bible vanished on
/// restart. Existing Linux installs are migrated from the old location.
///
/// Every other platform keeps [getApplicationDocumentsDirectory] — it persists
/// fine there and is where existing installs already store their data, so no
/// migration is needed and nothing moves.
Future<Directory> appDataDir() async {
  if (!Platform.isLinux) {
    return getApplicationDocumentsDirectory();
  }
  final dir = await getApplicationSupportDirectory();
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  await _migrateLegacyData(dir);
  return dir;
}

// Cache the migration as a single Future so concurrent callers (the content
// store and user store both open at startup) await the *same* completion rather
// than the second caller seeing a "done" flag and racing ahead before the
// files have actually been copied.
Future<void> _migrateLegacyData(Directory target) =>
    _migration ??= _doMigrateLegacyData(target);

Future<void> _doMigrateLegacyData(Directory target) async {
  try {
    final legacy = await getApplicationDocumentsDirectory();
    if (legacy.path == target.path) return;
    for (final name in _migratableFiles) {
      // Copy the db plus its WAL/SHM sidecars so the migrated copy is consistent.
      for (final suffix in ['', '-wal', '-shm']) {
        final src = File(p.join(legacy.path, '$name$suffix'));
        final dst = File(p.join(target.path, '$name$suffix'));
        if (await src.exists() && !await dst.exists()) {
          await src.copy(dst.path);
        }
      }
    }
  } catch (_) {
    // getApplicationDocumentsDirectory can be unavailable (e.g. in the Flatpak
    // sandbox). A fresh install there has nothing to migrate.
  }
}
