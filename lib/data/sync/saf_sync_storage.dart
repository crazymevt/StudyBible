import 'dart:convert';
import 'dart:typed_data';

import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

import 'sync_storage.dart';

/// A [SyncStorage] over an Android Storage Access Framework (SAF) document tree.
///
/// [treeUri] is a persisted tree URI obtained from the system folder picker
/// (`SafUtil.pickDirectory(persistablePermission: true)`). Going through SAF
/// lets the user sync to any folder — including a cloud-synced one — without
/// the `MANAGE_EXTERNAL_STORAGE` permission, which Google Play disallows for
/// an app like this.
///
/// Android-only: only construct this when `Platform.isAndroid`.
class SafSyncStorage implements SyncStorage {
  final String treeUri;
  final SafUtil _util;
  final SafStream _stream;

  SafSyncStorage(this.treeUri, {SafUtil? util, SafStream? stream})
      : _util = util ?? SafUtil(),
        _stream = stream ?? SafStream();

  @override
  String get id => treeUri;

  @override
  Future<void> writeDocument(String name, String contents) async {
    await _stream.writeFileBytes(
      treeUri,
      name,
      'application/octet-stream',
      Uint8List.fromList(utf8.encode(contents)),
      overwrite: true,
    );
  }

  @override
  Future<List<String>> listDocuments(String suffix) async {
    final entries = await _util.list(treeUri);
    return entries
        .where((e) => !e.isDir && e.name.endsWith(suffix))
        .map((e) => e.name)
        .toList();
  }

  @override
  Future<List<String>> readLines(String name) async {
    final doc = await _util.child(treeUri, [name]);
    if (doc == null) return [];
    final bytes = await _stream.readFileBytes(doc.uri);
    return const LineSplitter().convert(utf8.decode(bytes));
  }
}
