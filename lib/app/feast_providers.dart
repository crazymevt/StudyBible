import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feasts/feast.dart';
import '../domain/feasts/feast_data.dart';
import 'shared_prefs.dart';

final feastsProvider = Provider<List<Feast>>((ref) => feasts);

/// The feasts (if any) whose occurrence spans [date], each paired with the
/// specific [FeastOccurrence] for the year in question.
final feastsOnDateProvider =
    Provider.family<List<(Feast, FeastOccurrence)>, DateTime>((ref, date) {
  final byId = {for (final f in feasts) f.id: f};
  return [
    for (final occurrence in feastOccurrences)
      if (occurrence.includes(date))
        (byId[occurrence.feastId]!, occurrence),
  ];
});

const _showFeastOnJournalKey = 'showFeastOnJournal';

class ShowFeastOnJournalNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_showFeastOnJournalKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_showFeastOnJournalKey, enabled);
    state = enabled;
  }
}

final showFeastOnJournalProvider =
    NotifierProvider<ShowFeastOnJournalNotifier, bool>(() {
  return ShowFeastOnJournalNotifier();
});
