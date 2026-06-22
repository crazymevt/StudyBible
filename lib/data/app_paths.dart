import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Files that live in the app data directory and should be carried over from
/// the legacy location on first run.
const _migratableFiles = ['content.db', 'user.db', 'device_id.txt'];

bool _migrationDone = false;

/// Directory for app-internal data: the content and user databases, the device
/// id, and the default sync folder.
///
/// Uses [getApplicationSupportDirectory] (backed by `XDG_DATA_HOME` on Linux),
/// which is persistent and works inside sandboxes such as Flatpak. The previous
/// location, [getApplicationDocumentsDirectory], depends on the optional
/// `xdg-user-dir` tool and the user's Documents folder, which is unreliable in
/// the Flatpak sandbox and caused data to vanish on restart.
///
/// On first run this migrates the databases and device id from the old
/// Documents location so existing installs keep their data.
Future<Directory> appDataDir() async {
  final dir = await getApplicationSupportDirectory();
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  await _migrateLegacyData(dir);
  return dir;
}

Future<void> _migrateLegacyData(Directory target) async {
  if (_migrationDone) return;
  _migrationDone = true;
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
