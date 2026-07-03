import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_selector/file_selector.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../app/media_providers.dart';
import '../../app/app_state.dart';
import '../../app/sync_service.dart';
import '../../app/tag_providers.dart';
import '../tags/tag_palette.dart';
import '../../app/user_providers.dart';
import '../../data/user_store.dart';
import '../../data/app_paths.dart';
import 'dart:io';
import 'media_player_dialog.dart';
import 'web_player_dialog.dart';
import 'pdf_viewer_dialog.dart';
import 'image_viewer_dialog.dart';
import 'attachment_config_dialog.dart';
import 'package:drift/drift.dart' as drift;

class MediaPanel extends ConsumerWidget {
  final String bookName;
  final int chapter;

  const MediaPanel({super.key, required this.bookName, required this.chapter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaList = ref.watch(
      chapterMediaProvider((book: bookName, chapter: chapter)),
    );
    final attachmentsAsync = ref.watch(
      chapterAttachmentsProvider((book: bookName, chapter: chapter)),
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Media',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      tooltip: 'Add Attachment',
                      onPressed: () => _pickAndSaveAttachment(context, ref),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                      onPressed: () {
                        ref.read(activeToolProvider.notifier).close();
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: (mediaList.isEmpty && (attachmentsAsync.value?.isEmpty ?? true))
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No media available for this chapter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      attachmentsAsync.when(
                        data: (attachments) {
                          if (attachments.isEmpty) return const SizedBox.shrink();
                          return FutureBuilder<Directory>(
                            future: appDataDir(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox.shrink();
                              final docsDir = snapshot.data!;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      'Your Attachments',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  ...attachments.map((a) {
                                    final isImage = a.mimeType.startsWith('image/');
                                    final file = File(p.join(docsDir.path, 'media_attachments', a.filename));
                                    
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      leading: Container(
                                        width: 45,
                                        height: 45,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: isImage
                                            ? Image.file(
                                                file,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) => Icon(Icons.image, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                              )
                                            : Icon(Icons.picture_as_pdf, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      ),
                                      title: Text(a.title ?? a.filename),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${(a.sizeBytes / 1024).toStringAsFixed(1)} KB'),
                                          Consumer(
                                            builder: (context, ref, _) {
                                              final tagsAsync = ref.watch(tagsForEntityProvider(a.id));
                                          return tagsAsync.maybeWhen(
                                            data: (tags) {
                                              if (tags.isEmpty) return const SizedBox.shrink();
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Wrap(
                                                  spacing: 4,
                                                  children: tags.map((et) {
                                                    final style = tagChipStyle(context, et.tag.colorHex);
                                                    return Chip(
                                                      label: Text('#${et.tag.name}', style: TextStyle(color: style.foreground, fontSize: 10)),
                                                      backgroundColor: style.background,
                                                      side: BorderSide(color: style.border),
                                                      padding: EdgeInsets.zero,
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    );
                                                  }).toList(),
                                                ),
                                              );
                                            },
                                            orElse: () => const SizedBox.shrink(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () async {
                                          final store = ref.read(userStoreProvider);
                                          final refs = await (store.select(store.attachmentReferences)..where((t) => t.attachmentId.equals(a.id))).get();
                                          if (!context.mounted) return;
                                          final result = await showDialog<Map<String, dynamic>>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (_) => AttachmentConfigDialog(
                                              attachment: a,
                                              existingReferences: refs,
                                            ),
                                          );
                                          if (result == null) return;
                                          
                                          final finalTitle = result['title'] as String?;
                                          final finalReferences = result['references'] as List<AttachmentReference>;
                                          
                                          await store.transaction(() async {
                                            await store.update(store.mediaAttachments).replace(a.copyWith(
                                              title: drift.Value(finalTitle),
                                              updatedAt: DateTime.now().millisecondsSinceEpoch,
                                            ));
                                            
                                            await (store.delete(store.attachmentReferences)..where((t) => t.attachmentId.equals(a.id))).go();
                                            for (final refItem in finalReferences) {
                                              await store.into(store.attachmentReferences).insert(refItem);
                                            }
                                          });
                                          ref.invalidate(chapterAttachmentsProvider);
                                        },
                                      ),
                                      onTap: () async {
                                        if (!await file.exists()) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found locally. It may still be syncing.')));
                                          }
                                          return;
                                        }
                                        if (context.mounted) {
                                          if (isImage) {
                                            showDialog(context: context, builder: (_) => ImageViewerDialog(title: a.title ?? a.filename, file: file));
                                          } else if (a.mimeType == 'application/pdf') {
                                            showDialog(context: context, builder: (_) => PdfViewerDialog(title: a.title ?? a.filename, file: file));
                                          } else {
                                            launchUrl(file.uri, mode: LaunchMode.externalApplication);
                                          }
                                        }
                                      },
                                    );
                                  }),
                                  const Divider(height: 32),
                                ],
                              );
                            }
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, st) => Text('Error loading attachments: $e'),
                      ),
                      ...mediaList.map((group) {
                        final collection = group.collection;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Collection Header
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              bottom: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  collection.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                                if (collection.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    collection.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                                if (collection.copyright.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    collection.copyright,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ],
                                if (collection.url.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      launchUrl(
                                        Uri.parse(collection.url),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    child: Text(
                                      'Learn More',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Collection Items
                          ...group.items.map((item) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 80,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(4),
                                  image: item.id != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            'https://img.youtube.com/vi/${item.id}/hqdefault.jpg',
                                          ),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) {
                                            // Ignore image loading errors
                                          },
                                        )
                                      : null,
                                ),
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(item.title),
                              subtitle: item.description != null
                                  ? Text(
                                      item.description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: Text(
                                item.duration ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              onTap: () {
                                if (item.id != null) {
                                  if (Platform.isWindows || Platform.isLinux) {
                                    launchUrl(
                                      Uri.parse('https://www.youtube.com/watch?v=${item.id}'),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          MediaPlayerDialog(videoId: item.id!),
                                    );
                                  }
                                } else if (item.url != null) {
                                  if (Platform.isWindows || Platform.isLinux) {
                                    launchUrl(
                                      Uri.parse(item.url!),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          WebPlayerDialog(url: item.url!),
                                    );
                                  }
                                }
                              },
                            );
                          }),
                          const Divider(height: 32),
                        ],
                      );
                    }),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSaveAttachment(BuildContext context, WidgetRef ref) async {
    const typeGroup = XTypeGroup(
      label: 'Images and PDFs',
      extensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final store = ref.read(userStoreProvider);
    final deviceId = await ref.read(deviceIdProvider.future);
    
    final docsDir = await appDataDir();
    final attachmentsDir = Directory(p.join(docsDir.path, 'media_attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final ext = p.extension(file.path);
    final attachmentId = const Uuid().v4();
    final filename = '$attachmentId$ext';
    final destFile = File(p.join(attachmentsDir.path, filename));
    
    final bytes = await file.readAsBytes();
    await destFile.writeAsBytes(bytes);

    final now = DateTime.now().millisecondsSinceEpoch;
    var mimeType = 'application/octet-stream';
    if (ext.toLowerCase() == '.pdf') {
      mimeType = 'application/pdf';
    } else if (ext.toLowerCase() == '.jpg' || ext.toLowerCase() == '.jpeg') {
      mimeType = 'image/jpeg';
    } else if (ext.toLowerCase() == '.png') {
      mimeType = 'image/png';
    }

    final attachment = MediaAttachment(
      id: attachmentId,
      updatedAt: now,
      deviceId: deviceId,
      deleted: false,
      title: p.basename(file.path),
      filename: filename,
      mimeType: mimeType,
      sizeBytes: bytes.length,
      createdAt: now,
    );

    final reference = AttachmentReference(
      id: const Uuid().v4(),
      updatedAt: now,
      deviceId: deviceId,
      deleted: false,
      attachmentId: attachmentId,
      bookName: bookName,
      chapter: chapter,
      verse: null,
      createdAt: now,
    );

    await store.transaction(() async {
      await store.into(store.mediaAttachments).insert(attachment);
      await store.into(store.attachmentReferences).insert(reference);
    });

    if (!context.mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AttachmentConfigDialog(
        attachment: attachment,
        existingReferences: [reference],
      ),
    );

    if (result == null) {
      if (await destFile.exists()) {
        await destFile.delete();
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.transaction(() async {
        await store.into(store.mediaAttachments).insert(
          attachment.copyWith(deleted: true, updatedAt: now),
          mode: drift.InsertMode.replace,
        );
        // Tombstone the reference too so it doesn't dangle (and syncs the
        // deletion if the row already reached another device).
        await (store.update(store.attachmentReferences)
              ..where((t) => t.attachmentId.equals(attachmentId)))
            .write(
          AttachmentReferencesCompanion(
            deleted: const drift.Value(true),
            updatedAt: drift.Value(now),
          ),
        );
      });
      ref.invalidate(chapterAttachmentsProvider);
      return;
    }

    final finalTitle = result['title'] as String?;
    final finalReferences = result['references'] as List<AttachmentReference>;

    final finalAttachment = attachment.copyWith(
      title: drift.Value(finalTitle),
    );

    await store.transaction(() async {
      await store.update(store.mediaAttachments).replace(finalAttachment);
      await (store.delete(store.attachmentReferences)..where((t) => t.attachmentId.equals(attachmentId))).go();
      for (final refItem in finalReferences) {
        await store.into(store.attachmentReferences).insert(refItem.copyWith(deviceId: deviceId));
      }
    });
    
    ref.invalidate(chapterAttachmentsProvider);
  }
}
