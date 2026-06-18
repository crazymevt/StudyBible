import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:study_bible/data/content_store.dart';

final contentStoreProvider = Provider<ContentStore>((ref) {
  return ContentStore();
});

final versionsProvider = FutureProvider<List<Version>>((ref) {
  final store = ref.watch(contentStoreProvider);
  return store.select(store.versions).get();
});

final booksForVersionProvider = FutureProvider.family<List<Book>, String>((ref, versionId) {
  final store = ref.watch(contentStoreProvider);
  return (store.select(store.books)..where((b) => b.versionId.equals(versionId))).get();
});

final versesForChapterProvider = FutureProvider.family<List<Verse>, ({int bookId, int chapter})>((ref, args) {
  final store = ref.watch(contentStoreProvider);
  return (store.select(store.verses)..where((v) => v.bookId.equals(args.bookId) & v.chapter.equals(args.chapter))).get();
});
