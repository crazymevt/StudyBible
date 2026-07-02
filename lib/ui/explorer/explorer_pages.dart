import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/explorer_providers.dart';
import '../../app/people_providers.dart';
import '../../app/topic_providers.dart';
import '../../data/content_store.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../common/skeleton.dart';
import 'explorer_common.dart';

/// The page body for one trail entry — dispatches on the entity type.
class ExplorerEntityPage extends StatelessWidget {
  const ExplorerEntityPage({super.key, required this.entry});

  final ExplorerRef entry;

  @override
  Widget build(BuildContext context) {
    return switch (entry.type) {
      ExplorerEntityType.person => _PersonPage(personId: entry.id!),
      ExplorerEntityType.place => _PlacePage(placeId: entry.id!),
      ExplorerEntityType.event => _EventPage(eventId: entry.id!),
      ExplorerEntityType.topic => _TopicPage(topicId: entry.id!),
      ExplorerEntityType.passage =>
        _PassagePage(book: entry.book!, chapter: entry.chapter!),
    };
  }
}

/// Scroll frame shared by all entity pages: centered, width-capped card list.
class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Long prose (e.g. Easton's bios) shown clamped with a Read more toggle.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Rough clamp threshold; short bios never need the toggle.
    final needsToggle = widget.text.length > 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded || !needsToggle ? null : 8,
          overflow: _expanded || !needsToggle
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (needsToggle)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Show less' : 'Read more'),
          ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

// --- Person ---

class _PersonPage extends ConsumerWidget {
  const _PersonPage({required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(personDetailProvider(personId));
    final placesAsync = ref.watch(explorerPersonPlacesProvider(personId));
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this person: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Person not found.');
        final p = d.person;
        final years = <String>[
          if (p.birthYear != null && p.deathYear != null)
            '${explorerYearLabel(p.birthYear!)} – ${explorerYearLabel(p.deathYear!)}'
          else if (p.birthYear != null)
            'born ${explorerYearLabel(p.birthYear!)}'
          else if (p.deathYear != null)
            'died ${explorerYearLabel(p.deathYear!)}',
        ];
        final subtitle = [
          if (p.gender != null) p.gender!,
          ...years,
          if (d.groups.isNotEmpty) d.groups.join(', '),
          if (p.alsoCalled != null) 'also called ${p.alsoCalled}',
        ].join(' · ');

        final family = <(String, List<BiblePerson>)>[
          if (d.father != null) ('Father', [d.father!]),
          if (d.mother != null) ('Mother', [d.mother!]),
          if (d.partners.isNotEmpty)
            (d.partners.length == 1 ? 'Spouse' : 'Spouses', d.partners),
          if (d.siblings.isNotEmpty) ('Siblings', d.siblings),
          if (d.children.isNotEmpty) ('Children', d.children),
        ];

        final places = placesAsync.asData?.value ?? const <Place>[];

        return _PageScroll(
          children: [
            _PageTitle(title: p.displayTitle, subtitle: subtitle),
            if (p.bio != null)
              ExplorerFacetCard(
                icon: Icons.auto_stories_outlined,
                title: 'Biography — Easton\'s Bible Dictionary',
                child: _ExpandableText(p.bio!),
              ),
            if (family.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.family_restroom,
                title: 'Family',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (label, people) in family)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 72,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final person in people)
                                    ExplorerRefChip(
                                      ExplorerRef.person(
                                          person.id, person.displayTitle),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (d.events.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.flag_outlined,
                title: 'Events (${d.events.length})',
                child: Column(
                  children: [
                    for (final e in d.events)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.title),
                        subtitle: e.startYear == null
                            ? null
                            : Text(explorerYearLabel(e.startYear!)),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => ref
                            .read(explorerTrailProvider.notifier)
                            .open(ExplorerRef.event(e.eventId, e.title)),
                      ),
                  ],
                ),
              ),
            if (places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: 'Places in their story',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(places: [
                      for (final pl in places)
                        ExplorerMapPlace(pl.id, pl.name, pl.lat, pl.lng),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final pl in places)
                          ExplorerRefChip(ExplorerRef.place(pl.id, pl.name)),
                      ],
                    ),
                  ],
                ),
              ),
            if (d.verses.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.menu_book_outlined,
                title: 'Appears in ${d.verses.length} '
                    '${d.verses.length == 1 ? 'verse' : 'verses'}',
                child: ExplorerVerseGroups(refs: [
                  for (final v in d.verses)
                    (book: v.bookName, chapter: v.chapter, verse: v.verse),
                ]),
              ),
          ],
        );
      },
    );
  }
}

// --- Place ---

class _PlacePage extends ConsumerWidget {
  const _PlacePage({required this.placeId});

  final int placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(explorerPlaceDetailProvider(placeId));
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this place: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Place not found.');
        return _PageScroll(
          children: [
            _PageTitle(
              title: d.place.name,
              subtitle: '${d.verses.length} '
                  '${d.verses.length == 1 ? 'verse mentions' : 'verses mention'} '
                  'this place',
            ),
            ExplorerMap(places: [
              ExplorerMapPlace(d.place.id, d.place.name, d.place.lat,
                  d.place.lng),
            ]),
            const SizedBox(height: 12),
            if (d.events.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.flag_outlined,
                title: 'Events here (${d.events.length})',
                child: Column(
                  children: [
                    for (final e in d.events)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.title),
                        subtitle: e.startYear == null
                            ? null
                            : Text(explorerYearLabel(e.startYear!)),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => ref
                            .read(explorerTrailProvider.notifier)
                            .open(ExplorerRef.event(e.id, e.title)),
                      ),
                  ],
                ),
              ),
            if (d.people.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.person_outline,
                title: 'People mentioned here',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in d.people)
                      ExplorerRefChip(
                          ExplorerRef.person(p.id, p.displayTitle)),
                  ],
                ),
              ),
            if (d.verses.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.menu_book_outlined,
                title: 'Mentioned in ${d.verses.length} '
                    '${d.verses.length == 1 ? 'verse' : 'verses'}',
                child: ExplorerVerseGroups(refs: [
                  for (final v in d.verses)
                    (book: v.bookName, chapter: v.chapter, verse: v.verse),
                ]),
              ),
          ],
        );
      },
    );
  }
}

// --- Event ---

class _EventPage extends ConsumerWidget {
  const _EventPage({required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(explorerEventDetailProvider(eventId));
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this event: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Event not found.');
        return _PageScroll(
          children: [
            _PageTitle(
              title: d.event.title,
              subtitle: d.event.startYear == null
                  ? null
                  : explorerYearLabel(d.event.startYear!),
            ),
            if (d.verses.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.menu_book_outlined,
                title: 'The account',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final v in d.verses)
                      ExplorerVerseChip(
                        book: v.bookName,
                        chapter: v.chapter,
                        verse: v.verse,
                      ),
                  ],
                ),
              ),
            if (d.participants.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.person_outline,
                title: 'Who was there (${d.participants.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in d.participants)
                      ExplorerRefChip(
                          ExplorerRef.person(p.id, p.displayTitle)),
                  ],
                ),
              ),
            if (d.places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: 'Where it happened',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(places: [
                      for (final p in d.places)
                        ExplorerMapPlace(p.id, p.name, p.lat, p.lng),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in d.places)
                          ExplorerRefChip(ExplorerRef.place(p.id, p.name)),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// --- Topic ---

class _TopicPage extends ConsumerWidget {
  const _TopicPage({required this.topicId});

  final int topicId;

  Future<void> _openSeeAlso(WidgetRef ref, String name) async {
    final id = await ref.read(topicIdByNameProvider(name).future);
    if (id != null) {
      ref
          .read(explorerTrailProvider.notifier)
          .open(ExplorerRef.topic(id, name.trim().toUpperCase()));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(topicDetailProvider(topicId));
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this topic: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Topic not found.');
        return _PageScroll(
          children: [
            _PageTitle(
              title: d.topic.name,
              subtitle: 'Nave\'s Topical Bible',
            ),
            for (final ev in d.entries)
              ExplorerFacetCard(
                icon: Icons.notes,
                title: ev.entry.description,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ev.refs.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final r in ev.refs)
                            ExplorerVerseChip(
                              book: r.bookName,
                              chapter: r.chapter,
                              verse: r.verse ?? 1,
                              label: r.verse == null
                                  ? '${r.bookName} ${r.chapter}'
                                  : '${r.bookName} ${r.chapter}:${r.verse}'
                                      '${r.verseEnd != null ? '–${r.verseEnd}' : ''}',
                            ),
                        ],
                      ),
                    if (ev.entry.seeAlso != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in ev.entry.seeAlso!.split('\n'))
                            ActionChip(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              avatar: const Icon(Icons.link, size: 16),
                              label: Text('See also: $s'),
                              onPressed: () => _openSeeAlso(ref, s),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// --- Passage ---

class _PassagePage extends ConsumerWidget {
  const _PassagePage({required this.book, required this.chapter});

  final String book;
  final int chapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref
        .watch(explorerPassageOverviewProvider((book: book, chapter: chapter)));
    return overviewAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this passage: $e'),
      data: (d) {
        return _PageScroll(
          children: [
            _PageTitle(
              title: '$book $chapter',
              trailing: FilledButton.tonalIcon(
                icon: const Icon(Icons.menu_book, size: 18),
                label: const Text('Open in reader'),
                onPressed: () => explorerOpenVerseInReader(
                    context, ref, book, chapter, 1),
              ),
            ),
            if (d.isEmpty)
              const _ErrorBody(
                  'The datasets don\'t tag anything in this chapter yet.'),
            if (d.people.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.person_outline,
                title: 'People (${d.people.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in d.people)
                      ExplorerRefChip(
                        ExplorerRef.person(p.id, p.displayTitle),
                        subtitle: 'v. ${p.verses.join(', ')}',
                      ),
                  ],
                ),
              ),
            if (d.places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: 'Places (${d.places.length})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(places: [
                      for (final p in d.places)
                        ExplorerMapPlace(p.id, p.name, p.lat, p.lng),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in d.places)
                          ExplorerRefChip(
                            ExplorerRef.place(p.id, p.name),
                            subtitle: 'v. ${p.verses.join(', ')}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            if (d.events.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.flag_outlined,
                title: 'Events (${d.events.length})',
                child: Column(
                  children: [
                    for (final e in d.events)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.title),
                        subtitle: e.startYear == null
                            ? null
                            : Text(explorerYearLabel(e.startYear!)),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => ref
                            .read(explorerTrailProvider.notifier)
                            .open(ExplorerRef.event(e.id, e.title)),
                      ),
                  ],
                ),
              ),
            if (d.topics.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.topic_outlined,
                title: 'Topics (${d.topics.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in d.topics)
                      ExplorerRefChip(ExplorerRef.topic(t.id, t.name)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
