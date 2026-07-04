import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/journal_providers.dart';
import '../../app/shared_prefs.dart';
import '../tags/tag_editor_dialog.dart';
import '../common/breakpoints.dart';
import '../common/empty_state.dart';
import '../common/skeleton.dart';

class HideAnsweredPrayersNotifier extends Notifier<bool> {
  static const _prefsKey = 'hideAnsweredPrayers';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_prefsKey) ?? false;
  }

  void setHide(bool val) {
    state = val;
    ref.read(sharedPreferencesProvider).setBool(_prefsKey, val);
  }
}

final hideAnsweredPrayersProvider =
    NotifierProvider<HideAnsweredPrayersNotifier, bool>(
      () => HideAnsweredPrayersNotifier(),
    );

class PrayerTrackerPanel extends ConsumerWidget {
  const PrayerTrackerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayersAsync = ref.watch(prayersProvider);
    final hideAnswered = ref.watch(hideAnsweredPrayersProvider);
    final isPhone = MediaQuery.sizeOf(context).width <= Breakpoints.phone;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Prayer Tracker',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isPhone) const Text('Hide Answered'),
                  Tooltip(
                    message: 'Hide Answered',
                    child: Switch(
                      value: hideAnswered,
                      onChanged: (val) => ref
                          .read(hideAnsweredPrayersProvider.notifier)
                          .setHide(val),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Prayer',
                    onPressed: () => _showAddPrayerDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: prayersAsync.when(
            data: (prayers) {
              final visiblePrayers = hideAnswered
                  ? prayers.where((p) => p.answeredAt == null).toList()
                  : prayers;

              if (visiblePrayers.isEmpty) {
                return EmptyState(
                  icon: hideAnswered
                      ? Icons.volunteer_activism
                      : Icons.favorite_outline,
                  title: hideAnswered ? 'No open prayers' : 'No prayers yet',
                  message: hideAnswered
                      ? 'Every prayer here has been answered.'
                      : 'Tap + to add someone or something to pray for.',
                );
              }

              return ListView.separated(
                itemCount: visiblePrayers.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final prayer = visiblePrayers[index];
                  final isAnswered = prayer.answeredAt != null;

                  return ExpansionTile(
                    leading: Checkbox(
                      value: isAnswered,
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(prayerActionProvider)
                              .toggleAnswered(prayer.id, val);
                        }
                      },
                    ),
                    title: Text(
                      prayer.name,
                      style: TextStyle(
                        decoration: isAnswered
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      'Created: ${DateTime.fromMillisecondsSinceEpoch(prayer.createdAt).toLocal().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            prayer.description.isEmpty
                                ? 'No description'
                                : prayer.description,
                          ),
                        ),
                      ),
                      if (isAnswered)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Answered on: ${DateTime.fromMillisecondsSinceEpoch(prayer.answeredAt!).toLocal().toString().split(' ')[0]}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            onPressed: () => _showAddPrayerDialog(
                              context,
                              ref,
                              prayerId: prayer.id,
                              initialName: prayer.name,
                              initialDesc: prayer.description,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.label, size: 18),
                            label: const Text('Tags'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => TagEditorDialog(
                                  entityId: prayer.id,
                                  entityType: 'prayer',
                                ),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete Prayer'),
                                  content: const Text(
                                    'Are you sure you want to delete this prayer?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref
                                    .read(prayerActionProvider)
                                    .deletePrayer(prayer.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const SkeletonList(),
            error: (err, stack) => const EmptyState(
              icon: Icons.error_outline,
              title: 'Couldn\'t load prayers',
            ),
          ),
          ),
        ),
      ],
    );
  }

  void _showAddPrayerDialog(
    BuildContext context,
    WidgetRef ref, {
    String? prayerId,
    String? initialName,
    String? initialDesc,
  }) {
    showDialog(
      context: context,
      builder: (_) => _PrayerDialog(
        prayerId: prayerId,
        initialName: initialName,
        initialDesc: initialDesc,
      ),
    );
  }
}

/// Add/edit dialog. A [ConsumerStatefulWidget] so its controllers are disposed
/// in [State.dispose] (after the route is fully removed) rather than the
/// instant `showDialog` returns, which races the dismiss animation.
class _PrayerDialog extends ConsumerStatefulWidget {
  final String? prayerId;
  final String? initialName;
  final String? initialDesc;

  const _PrayerDialog({this.prayerId, this.initialName, this.initialDesc});

  @override
  ConsumerState<_PrayerDialog> createState() => _PrayerDialogState();
}

class _PrayerDialogState extends ConsumerState<_PrayerDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDesc);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty) return;
    await ref.read(prayerActionProvider).savePrayer(
          widget.prayerId,
          name,
          desc,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth <= Breakpoints.phone;
    return AlertDialog(
      insetPadding: isPhone
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      title: Text(widget.prayerId == null ? 'Add Prayer' : 'Edit Prayer'),
      content: SizedBox(
        width: isPhone ? screenWidth - 32 : 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
                minLines: 5,
                maxLines: 10,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
