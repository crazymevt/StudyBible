part of 'explorer_providers.dart';

// --- Dictionary lookup (place & topic pages) ---

/// Dictionary entries whose headword matches an Explorer entity's name, across
/// every installed dictionary (Easton's, or any user-imported lexicon). Powers
/// the "Dictionary" facet card on place and topic pages, so a place like
/// "Jerusalem" or a topic like "AARON" surfaces its dictionary definition.
/// Empty when no dictionary is installed or nothing matches.
///
/// Person pages deliberately don't use this — their biography card already
/// shows the Easton entry (baked into the Theographic data), so a dictionary
/// card would duplicate it.
final explorerEntryDictionaryProvider =
    FutureProvider.family<List<DictionaryEntryWithDict>, String>((
      ref,
      name,
    ) async {
      final dictionaries = await ref.watch(dictionariesProvider.future);
      if (dictionaries.isEmpty) return const [];
      final store = ref.watch(contentStoreProvider);

      // Candidate headwords: the name as-is, plus the name with any trailing
      // parenthetical qualifier stripped ("Ramah (1)" -> "Ramah"). LIKE with no
      // wildcards is a case-insensitive exact match, so a topic's upper-case
      // "AARON" still resolves Easton's "Aaron" without over-matching substrings.
      final terms = <String>{};
      final trimmed = name.trim();
      if (trimmed.isNotEmpty) terms.add(trimmed);
      final withoutQualifier = trimmed
          .replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '')
          .trim();
      if (withoutQualifier.isNotEmpty) terms.add(withoutQualifier);
      if (terms.isEmpty) return const [];

      final word = store.dictionaryEntries.word;
      final predicate = terms.map((t) => word.like(t)).reduce((a, b) => a | b);

      final rows = await (store.select(store.dictionaryEntries).join([
        innerJoin(
          store.dictionaries,
          store.dictionaries.id.equalsExp(store.dictionaryEntries.dictionaryId),
        ),
      ])..where(predicate)).get();

      return [
        for (final row in rows)
          DictionaryEntryWithDict(
            entry: row.readTable(store.dictionaryEntries),
            dictionary: row.readTable(store.dictionaries),
          ),
      ];
    });
