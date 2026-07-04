import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../data/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/media_collection.dart';
import '../data/user_store.dart';
import 'package:drift/drift.dart';
import 'user_providers.dart';

// Provider that holds all loaded MediaCollections
final mediaCollectionsProvider = FutureProvider<List<MediaCollection>>((
  ref,
) async {
  final fileNames = [
    'bibleproject.json',
    'bibleproject-extended.json',
    'jesus-film.json',
    'lumo.json',
  ];

  final List<MediaCollection> collections = [];

  for (final file in fileNames) {
    try {
      final jsonString = await rootBundle.loadString('assets/media/$file');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      collections.add(MediaCollection.fromJson(jsonData));
    } catch (e, stack) {
      // Keep loading other collections; log so a broken asset is diagnosable.
      logError(e, stack, context: 'loadMediaCollections: $file');
    }
  }

  return collections;
});

class MediaGroup {
  final MediaCollection collection;
  final List<MediaItem> items;

  MediaGroup({required this.collection, required this.items});
}

// A provider that filters media for a specific book and chapter
final chapterMediaProvider =
    Provider.family<List<MediaGroup>, ({String book, int chapter})>((
      ref,
      args,
    ) {
      final collectionsAsync = ref.watch(mediaCollectionsProvider);

      return collectionsAsync.maybeWhen(
        data: (collections) {
          final List<MediaGroup> groups = [];

          for (final collection in collections) {
            final bookItems = collection.mediaByBook[args.book] ?? [];
            final List<MediaItem> relevantItems = [];

            for (final item in bookItems) {
              // If chapters array exists, check if our chapter falls within it [start, end]
              if (item.chapters != null && item.chapters!.length >= 2) {
                final start = item.chapters![0];
                final end = item.chapters![1];
                if (args.chapter >= start && args.chapter <= end) {
                  relevantItems.add(item);
                }
              }
            }

            if (relevantItems.isNotEmpty) {
              groups.add(
                MediaGroup(collection: collection, items: relevantItems),
              );
            }
          }
          return groups;
        },
        orElse: () => [],
      );
    });

// Provider for user-uploaded media attachments for a specific book and chapter.
// A live stream so title/reference edits (e.g. from the reader's Media panel)
// reflect immediately wherever attachments are shown — the reader and the
// Explorer passage page.
final chapterAttachmentsProvider = StreamProvider.family<
  List<MediaAttachment>,
  ({String book, int chapter})
>((ref, args) {
  final store = ref.watch(userStoreProvider);

  final query = store.select(store.attachmentReferences).join([
    innerJoin(
      store.mediaAttachments,
      store.mediaAttachments.id.equalsExp(store.attachmentReferences.attachmentId),
    )
  ])..where(
      store.attachmentReferences.bookName.equals(args.book) &
      store.attachmentReferences.chapter.equals(args.chapter) &
      store.attachmentReferences.deleted.equals(false) &
      store.mediaAttachments.deleted.equals(false),
    );

  return query.watch().map((results) {
    // Deduplicate attachments referenced multiple times (e.g. verse ranges) in
    // the same chapter.
    return results
        .map((row) => row.readTable(store.mediaAttachments))
        .toSet()
        .toList();
  });
});

// Provider for all user-uploaded media attachments
final allAttachmentsProvider = FutureProvider<List<MediaAttachment>>((ref) async {
  final store = ref.watch(userStoreProvider);
  return (store.select(store.mediaAttachments)..where((t) => t.deleted.equals(false))).get();
});
