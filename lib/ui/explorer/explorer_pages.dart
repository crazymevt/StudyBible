import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:path/path.dart' as p;

import '../../app/content_providers.dart';
import '../../app/explorer_providers.dart';
import '../../app/media_providers.dart';
import '../../app/people_providers.dart';
import '../../app/place_providers.dart';
import '../../app/prophecy_providers.dart';
import '../../app/reference_providers.dart';
import '../../app/search_providers.dart';
import '../../app/topic_providers.dart';
import '../../app/user_providers.dart';
import '../../data/app_paths.dart';
import '../../data/content_store.dart';
import '../../data/user_store.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../../domain/prophecy/prophecy.dart';
import '../../domain/prophecy/prophecy_data.dart';
import '../../domain/prophecy/prophecy_index.dart';
import '../../domain/reference/reference_index.dart';
import '../common/skeleton.dart';
import '../reader/image_viewer_dialog.dart';
import '../reader/media_video_list.dart';
import '../reader/pdf_viewer_dialog.dart';
import 'explorer_common.dart';
import 'explorer_index_page.dart';
import 'family_tree_screen.dart';

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
      ExplorerEntityType.passage => _PassagePage(
        book: entry.book!,
        chapter: entry.chapter!,
      ),
      ExplorerEntityType.tag => _TagPage(tagId: entry.tagId!),
      ExplorerEntityType.prophecy => _ProphecyPage(index: entry.id!),
      ExplorerEntityType.browse => ExplorerIndexPage(
        kind: entry.browseKind!,
        category: entry.browseCategory,
      ),
    };
  }
}

/// A single prophecy from the pure-Dart `prophecies` dataset: the Old
/// Testament foretelling and its New Testament fulfillment, each with tappable
/// passages that open in the reader. No async — the data is a const list.
class _ProphecyPage extends StatelessWidget {
  const _ProphecyPage({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    if (index < 0 || index >= prophecies.length) {
      return const _ErrorBody('Prophecy not found.');
    }
    final prophecy = prophecies[index];
    final otFulfillment = prophecy.category == ProphecyCategory.oldTestament;
    return _PageScroll(
      children: [
        _PageTitle(title: prophecy.title, subtitle: prophecy.category.label),
        ExplorerFacetCard(
          icon: Icons.auto_stories_outlined,
          title: 'The Prophecy',
          child: _ProphecySection(
            text: prophecy.prophecyText,
            passages: prophecy.prophecy,
          ),
        ),
        ExplorerFacetCard(
          icon: Icons.check_circle_outline,
          title: otFulfillment ? 'Fulfilled' : 'The Fulfillment',
          child: _ProphecySection(
            text: prophecy.fulfillmentText,
            passages: prophecy.fulfillment,
          ),
        ),
      ],
    );
  }
}

/// A prophecy facet's prose plus its passage chips. Chip parsing mirrors the
/// Prophecies panel: "Book C", "Book C:V", or "Book C:V-V"; a range opens at
/// its first verse but keeps the full reference as its label.
class _ProphecySection extends StatelessWidget {
  const _ProphecySection({required this.text, required this.passages});

  final String text;
  final List<String> passages;

  static final _exp = RegExp(r'^(.+?)\s+(\d+)(?::(\d+)(?:-(\d+))?)?$');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: Theme.of(context).textTheme.bodyMedium),
        if (passages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final passage in passages)
                  if (_exp.firstMatch(passage.trim()) case final m?)
                    ExplorerVerseChip(
                      book: m.group(1)!.trim(),
                      chapter: int.parse(m.group(2)!),
                      verse: int.tryParse(m.group(3) ?? '') ?? 1,
                      label: passage,
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Short qualifier for a prophecy chip on a chapter page: whether this chapter
/// carries the foretelling, the fulfillment, or both, plus the verses cited.
String _prophecyRoleLabel(ProphecyChapterHit h) {
  final role = h.foretold && h.fulfilled
      ? 'foretold & fulfilled'
      : h.foretold
      ? 'foretold'
      : 'fulfilled';
  final vs = h.verses.length == 1
      ? 'v. ${h.verses.first}'
      : 'vv. ${h.verses.join(', ')}';
  return '$role · $vs';
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
    final stories =
        ref.watch(explorerPersonStoriesProvider(personId)).asData?.value ??
        const <ExplorerTopicHit>[];
    final tags =
        ref.watch(explorerPersonTagsProvider(personId)).asData?.value ??
        const <ExplorerEntityTag>[];
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this person: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Person not found.');
        final p = d.person;
        final sermons =
            ref
                .watch(
                  explorerSermonsProvider(
                    ExplorerRef.person(p.id, p.displayTitle),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final notebookPages =
            ref
                .watch(
                  explorerNotebookPagesProvider(
                    ExplorerRef.person(p.id, p.displayTitle),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
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
                trailing:
                    d.father == null && d.mother == null && d.children.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.account_tree_outlined),
                        tooltip: 'View family tree',
                        onPressed: () =>
                            Navigator.of(context).push(familyTreeRoute(p.id)),
                      ),
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
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
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
                                        person.id,
                                        person.displayTitle,
                                      ),
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
            if (stories.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.topic_outlined,
                title: 'Their stories',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in stories)
                      ExplorerRefChip(ExplorerRef.topic(s.id, s.name)),
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
                    ExplorerMap(
                      journeyPersonId: personId,
                      places: [
                        for (final pl in places)
                          ExplorerMapPlace(pl.id, pl.name, pl.lat, pl.lng),
                      ],
                    ),
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
                title:
                    'Appears in ${d.verses.length} '
                    '${d.verses.length == 1 ? 'verse' : 'verses'}',
                child: ExplorerVerseGroups(
                  refs: [
                    for (final v in d.verses)
                      (book: v.bookName, chapter: v.chapter, verse: v.verse),
                  ],
                ),
              ),
            if (sermons.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.co_present_outlined,
                title: 'Your sermons (${sermons.length})',
                child: Column(
                  children: [for (final s in sermons) _TaggedItemTile(item: s)],
                ),
              ),
            if (notebookPages.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.library_books_outlined,
                title: 'Your notebooks (${notebookPages.length})',
                child: Column(
                  children: [
                    for (final n in notebookPages) _TaggedItemTile(item: n),
                  ],
                ),
              ),
            if (tags.isNotEmpty) _EntityTagsCard(tags: tags),
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
    final tags =
        ref.watch(explorerPlaceTagsProvider(placeId)).asData?.value ??
        const <ExplorerEntityTag>[];
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this place: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Place not found.');
        final dictionary =
            ref
                .watch(explorerEntryDictionaryProvider(d.place.name))
                .asData
                ?.value ??
            const <DictionaryEntryWithDict>[];
        final sermons =
            ref
                .watch(
                  explorerSermonsProvider(
                    ExplorerRef.place(d.place.id, d.place.name),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final notebookPages =
            ref
                .watch(
                  explorerNotebookPagesProvider(
                    ExplorerRef.place(d.place.id, d.place.name),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        return _PageScroll(
          children: [
            _PageTitle(
              title: d.place.name,
              subtitle:
                  '${d.verses.length} '
                  '${d.verses.length == 1 ? 'verse mentions' : 'verses mention'} '
                  'this place',
            ),
            ExplorerMap(
              places: [
                ExplorerMapPlace(
                  d.place.id,
                  d.place.name,
                  d.place.lat,
                  d.place.lng,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (dictionary.isNotEmpty) _DictionaryCard(entries: dictionary),
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
                      ExplorerRefChip(ExplorerRef.person(p.id, p.displayTitle)),
                  ],
                ),
              ),
            if (d.verses.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.menu_book_outlined,
                title:
                    'Mentioned in ${d.verses.length} '
                    '${d.verses.length == 1 ? 'verse' : 'verses'}',
                child: ExplorerVerseGroups(
                  refs: [
                    for (final v in d.verses)
                      (book: v.bookName, chapter: v.chapter, verse: v.verse),
                  ],
                ),
              ),
            if (sermons.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.co_present_outlined,
                title: 'Your sermons (${sermons.length})',
                child: Column(
                  children: [for (final s in sermons) _TaggedItemTile(item: s)],
                ),
              ),
            if (notebookPages.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.library_books_outlined,
                title: 'Your notebooks (${notebookPages.length})',
                child: Column(
                  children: [
                    for (final n in notebookPages) _TaggedItemTile(item: n),
                  ],
                ),
              ),
            if (tags.isNotEmpty) _EntityTagsCard(tags: tags),
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
    final tags =
        ref.watch(explorerEventTagsProvider(eventId)).asData?.value ??
        const <ExplorerEntityTag>[];
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this event: $e'),
      data: (d) {
        if (d == null) return const _ErrorBody('Event not found.');
        final sermons =
            ref
                .watch(
                  explorerSermonsProvider(
                    ExplorerRef.event(d.event.id, d.event.title),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final notebookPages =
            ref
                .watch(
                  explorerNotebookPagesProvider(
                    ExplorerRef.event(d.event.id, d.event.title),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
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
                      ExplorerRefChip(ExplorerRef.person(p.id, p.displayTitle)),
                  ],
                ),
              ),
            if (d.places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: d.places.length == d.placesTotalCount
                    ? 'Where it happened'
                    : 'Where it happened (${d.places.length} of '
                          '${d.placesTotalCount})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(
                      places: [
                        for (final p in d.places)
                          ExplorerMapPlace(p.id, p.name, p.lat, p.lng),
                      ],
                    ),
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
            if (sermons.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.co_present_outlined,
                title: 'Your sermons (${sermons.length})',
                child: Column(
                  children: [for (final s in sermons) _TaggedItemTile(item: s)],
                ),
              ),
            if (notebookPages.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.library_books_outlined,
                title: 'Your notebooks (${notebookPages.length})',
                child: Column(
                  children: [
                    for (final n in notebookPages) _TaggedItemTile(item: n),
                  ],
                ),
              ),
            if (tags.isNotEmpty) _EntityTagsCard(tags: tags),
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
        final dictionary =
            ref
                .watch(explorerEntryDictionaryProvider(d.topic.name))
                .asData
                ?.value ??
            const <DictionaryEntryWithDict>[];
        final sermons =
            ref
                .watch(
                  explorerSermonsProvider(
                    ExplorerRef.topic(d.topic.id, d.topic.name),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final notebookPages =
            ref
                .watch(
                  explorerNotebookPagesProvider(
                    ExplorerRef.topic(d.topic.id, d.topic.name),
                  ),
                )
                .asData
                ?.value ??
            const <SearchResult>[];
        final passageFacets =
            ref
                .watch(explorerTopicPassageFacetsProvider(topicId))
                .asData
                ?.value ??
            const <ExplorerTopicLocationFacets>[];
        final multiLocation = passageFacets.length > 1;
        final places = _mergeTopicPlaces(passageFacets);
        final videoGroups = _mergeTopicVideoGroups(passageFacets);
        final attachments = _mergeTopicAttachments(passageFacets);
        return _PageScroll(
          children: [
            _PageTitle(
              title: d.topic.name,
              subtitle: switch (d.topic.category) {
                'feast' => 'Bible feast',
                'story' => 'Bible story',
                _ => 'Nave\'s Topical Bible',
              },
            ),
            if (dictionary.isNotEmpty) _DictionaryCard(entries: dictionary),
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
            if (places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: 'Places (${places.length})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(
                      places: [
                        for (final p in places)
                          ExplorerMapPlace(p.id, p.name, p.lat, p.lng),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in places)
                          ExplorerRefChip(
                            ExplorerRef.place(p.id, p.name),
                            // A merged verse list only makes sense within a
                            // single chapter — see [_mergeTopicPlaces].
                            subtitle: multiLocation
                                ? null
                                : 'v. ${p.verses.join(', ')}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            for (final group in videoGroups)
              ExplorerFacetCard(
                icon: Icons.play_circle_outline,
                title: '${group.collection.name} (${group.items.length})',
                child: Column(
                  children: [
                    for (final item in group.items) MediaVideoTile(item: item),
                  ],
                ),
              ),
            if (attachments.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.attachment_outlined,
                title: 'Your media (${attachments.length})',
                child: Column(
                  children: [
                    for (final a in attachments) _AttachmentTile(attachment: a),
                  ],
                ),
              ),
            if (passageFacets.any((f) => f.commentaries.isNotEmpty))
              ExplorerFacetCard(
                icon: Icons.import_contacts_outlined,
                title: 'Commentaries',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in passageFacets)
                      if (f.commentaries.isNotEmpty) ...[
                        if (multiLocation)
                          _TopicLocationLabel(f.book, f.chapter),
                        for (final section in f.commentaries)
                          _CommentarySection(section: section),
                      ],
                  ],
                ),
              ),
            if (passageFacets.any((f) => f.crossRefGroups.isNotEmpty))
              ExplorerCollapsibleFacetCard(
                icon: Icons.compare_arrows_outlined,
                title:
                    'Cross-references '
                    '(${passageFacets.fold(0, (n, f) => n + f.crossRefGroups.fold(0, (m, g) => m + g.refs.length))})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in passageFacets)
                      if (f.crossRefGroups.isNotEmpty) ...[
                        if (multiLocation)
                          _TopicLocationLabel(f.book, f.chapter),
                        for (final group in f.crossRefGroups)
                          _CrossRefGroupTile(group: group),
                      ],
                  ],
                ),
              ),
            if (sermons.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.co_present_outlined,
                title: 'Your sermons (${sermons.length})',
                child: Column(
                  children: [for (final s in sermons) _TaggedItemTile(item: s)],
                ),
              ),
            if (notebookPages.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.library_books_outlined,
                title: 'Your notebooks (${notebookPages.length})',
                child: Column(
                  children: [
                    for (final n in notebookPages) _TaggedItemTile(item: n),
                  ],
                ),
              ),
            if (passageFacets.any((f) => f.notes.isNotEmpty))
              ExplorerFacetCard(
                icon: Icons.edit_note_outlined,
                title: 'Your notes',
                child: Column(
                  children: [
                    for (final f in passageFacets)
                      if (f.notes.isNotEmpty)
                        for (final n in f.notes)
                          _PassageNoteTile(
                            book: f.book,
                            chapter: f.chapter,
                            note: n,
                          ),
                  ],
                ),
              ),
            if (passageFacets.any((f) => f.tags.isNotEmpty))
              ExplorerFacetCard(
                icon: Icons.label_outline,
                title: 'Your tags',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in passageFacets)
                      if (f.tags.isNotEmpty) ...[
                        if (multiLocation)
                          _TopicLocationLabel(f.book, f.chapter),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in f.tags)
                              ExplorerTagChip(
                                t.tag,
                                subtitle: 'v. ${t.verses.join(', ')}',
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
    final overviewAsync = ref.watch(
      explorerPassageOverviewProvider((book: book, chapter: chapter)),
    );
    final commentaries =
        ref
            .watch(
              explorerPassageCommentariesProvider((
                book: book,
                chapter: chapter,
              )),
            )
            .asData
            ?.value ??
        const <ExplorerCommentarySection>[];
    final crossRefGroups =
        ref
            .watch(
              explorerPassageCrossReferencesProvider((
                book: book,
                chapter: chapter,
              )),
            )
            .asData
            ?.value ??
        const <ExplorerCrossRefGroup>[];
    final passageSermons =
        ref
            .watch(explorerSermonsProvider(ExplorerRef.passage(book, chapter)))
            .asData
            ?.value ??
        const <SearchResult>[];
    final passageNotebookPages =
        ref
            .watch(
              explorerNotebookPagesProvider(ExplorerRef.passage(book, chapter)),
            )
            .asData
            ?.value ??
        const <SearchResult>[];
    final notes =
        ref
            .watch(
              chapterNotesFamilyProvider((bookName: book, chapter: chapter)),
            )
            .asData
            ?.value ??
        const <Note>[];
    final passageTags =
        ref
            .watch(explorerPassageTagsProvider((book: book, chapter: chapter)))
            .asData
            ?.value ??
        const <ExplorerPassageTag>[];
    final videoGroups = ref.watch(
      chapterMediaProvider((book: book, chapter: chapter)),
    );
    final attachments =
        ref
            .watch(chapterAttachmentsProvider((book: book, chapter: chapter)))
            .asData
            ?.value ??
        const <MediaAttachment>[];
    final prophecyHits =
        ref.watch(prophecyChapterIndexProvider)[prophecyChapterKey(
          book,
          chapter,
        )] ??
        const <ProphecyChapterHit>[];
    final referenceHits =
        ref.watch(referenceChapterIndexProvider)[referenceChapterKey(
          book,
          chapter,
        )] ??
        const <ReferenceChapterHit>[];
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
                onPressed: () =>
                    explorerOpenVerseInReader(context, ref, book, chapter, 1),
              ),
            ),
            if (d.isEmpty &&
                commentaries.isEmpty &&
                crossRefGroups.isEmpty &&
                passageSermons.isEmpty &&
                passageNotebookPages.isEmpty &&
                notes.isEmpty &&
                passageTags.isEmpty &&
                videoGroups.isEmpty &&
                attachments.isEmpty &&
                prophecyHits.isEmpty &&
                referenceHits.isEmpty)
              const _ErrorBody(
                'The datasets don\'t tag anything in this chapter yet.',
              ),
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
                    ExplorerMap(
                      places: [
                        for (final p in d.places)
                          ExplorerMapPlace(p.id, p.name, p.lat, p.lng),
                      ],
                    ),
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
            if (prophecyHits.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.auto_awesome_outlined,
                title: 'Prophecies (${prophecyHits.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final h in prophecyHits)
                      ExplorerRefChip(
                        ExplorerRef.prophecy(h.index, h.title),
                        subtitle: _prophecyRoleLabel(h),
                      ),
                  ],
                ),
              ),
            if (referenceHits.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.table_chart_outlined,
                title: 'Reference (${referenceHits.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final h in referenceHits)
                      h.explorerPersonId != null
                          ? ExplorerRefChip(
                              ExplorerRef.person(h.explorerPersonId!, h.title),
                              subtitle: h.kind.label,
                            )
                          : Chip(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              avatar: const Icon(Icons.table_chart, size: 16),
                              label: Text.rich(
                                TextSpan(
                                  text: h.title,
                                  children: [
                                    TextSpan(
                                      text: '  ${h.kind.label}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                  ],
                ),
              ),
            for (final group in videoGroups)
              ExplorerFacetCard(
                icon: Icons.play_circle_outline,
                title: '${group.collection.name} (${group.items.length})',
                child: Column(
                  children: [
                    for (final item in group.items) MediaVideoTile(item: item),
                  ],
                ),
              ),
            if (attachments.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.attachment_outlined,
                title: 'Your media (${attachments.length})',
                child: Column(
                  children: [
                    for (final a in attachments) _AttachmentTile(attachment: a),
                  ],
                ),
              ),
            if (commentaries.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.import_contacts_outlined,
                title: 'Commentaries (${commentaries.length})',
                child: Column(
                  children: [
                    for (final section in commentaries)
                      _CommentarySection(section: section),
                  ],
                ),
              ),
            if (crossRefGroups.isNotEmpty)
              ExplorerCollapsibleFacetCard(
                icon: Icons.compare_arrows_outlined,
                title:
                    'Cross-references '
                    '(${crossRefGroups.fold(0, (n, g) => n + g.refs.length)})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in crossRefGroups)
                      _CrossRefGroupTile(group: group),
                  ],
                ),
              ),
            if (passageSermons.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.co_present_outlined,
                title: 'Your sermons (${passageSermons.length})',
                child: Column(
                  children: [
                    for (final s in passageSermons) _TaggedItemTile(item: s),
                  ],
                ),
              ),
            if (passageNotebookPages.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.library_books_outlined,
                title: 'Your notebooks (${passageNotebookPages.length})',
                child: Column(
                  children: [
                    for (final n in passageNotebookPages)
                      _TaggedItemTile(item: n),
                  ],
                ),
              ),
            if (notes.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.edit_note_outlined,
                title: 'Your notes (${notes.length})',
                child: Column(
                  children: [
                    for (final n in notes)
                      _PassageNoteTile(book: book, chapter: chapter, note: n),
                  ],
                ),
              ),
            if (passageTags.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.label_outline,
                title: 'Your tags (${passageTags.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in passageTags)
                      ExplorerTagChip(
                        t.tag,
                        subtitle: 'v. ${t.verses.join(', ')}',
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

/// One source verse's cross-references, capped so a single heavily
/// cross-referenced verse (common in Psalms/Gospels) can't dominate the card.
class _CrossRefGroupTile extends StatelessWidget {
  const _CrossRefGroupTile({required this.group});

  final ExplorerCrossRefGroup group;

  static const _maxShown = 6;

  @override
  Widget build(BuildContext context) {
    final shown = group.refs.take(_maxShown).toList();
    final remaining = group.refs.length - shown.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'v. ${group.verse}',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final xref in shown)
                ExplorerVerseChip(
                  book: xref.targetBookName,
                  chapter: xref.targetChapter,
                  verse: xref.targetVerse,
                ),
              if (remaining > 0)
                Text(
                  '+$remaining more',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One commentary module's chapter entries, collapsed behind the module name
/// so several installed commentaries stay scannable.
class _CommentarySection extends StatelessWidget {
  const _CommentarySection({required this.section});

  final ExplorerCommentarySection section;

  @override
  Widget build(BuildContext context) {
    final count = section.entries.length;
    return ExpansionTile(
      dense: true,
      tilePadding: EdgeInsets.zero,
      title: Text(section.commentary.name),
      subtitle: Text('$count ${count == 1 ? 'entry' : 'entries'}'),
      children: [
        for (final entry in section.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.verse != null && entry.verse! > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'Verse ${entry.verse}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                HtmlWidget(entry.textContent),
              ],
            ),
          ),
      ],
    );
  }
}

/// The "Dictionary" facet card for a place or topic: the matching headword
/// entry from every installed dictionary, grouped by module. Definitions are
/// HTML (SWORD/MyBible), so they render through [HtmlWidget]. Only built when
/// [entries] is non-empty, so a page with no dictionary hits shows no card.
class _DictionaryCard extends StatelessWidget {
  const _DictionaryCard({required this.entries});

  final List<DictionaryEntryWithDict> entries;

  @override
  Widget build(BuildContext context) {
    // Group by dictionary, preserving first-seen order.
    final byDictionary = <int, List<DictionaryEntry>>{};
    final dictionaries = <int, Dictionary>{};
    for (final e in entries) {
      dictionaries[e.dictionary.id] = e.dictionary;
      byDictionary.putIfAbsent(e.dictionary.id, () => []).add(e.entry);
    }
    final single = byDictionary.length == 1;
    return ExplorerFacetCard(
      icon: Icons.book_outlined,
      title: 'Dictionary',
      child: Column(
        children: [
          for (final id in byDictionary.keys)
            _DictionarySection(
              dictionaryName: dictionaries[id]!.name,
              entries: byDictionary[id]!,
              initiallyExpanded: single,
            ),
        ],
      ),
    );
  }
}

/// One dictionary module's matching entries, collapsed behind the module name
/// (auto-expanded when it's the only module) to mirror [_CommentarySection].
class _DictionarySection extends StatelessWidget {
  const _DictionarySection({
    required this.dictionaryName,
    required this.entries,
    required this.initiallyExpanded,
  });

  final String dictionaryName;
  final List<DictionaryEntry> entries;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final count = entries.length;
    return ExpansionTile(
      dense: true,
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: initiallyExpanded,
      title: Text(dictionaryName),
      subtitle: Text('$count ${count == 1 ? 'entry' : 'entries'}'),
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    entry.word,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                HtmlWidget(entry.definition),
              ],
            ),
          ),
      ],
    );
  }
}

/// A small "Book Chapter" subheader above one location's share of a topic's
/// aggregated facet card — only shown when the topic cites more than one
/// chapter (see [_TopicPage]'s `multiLocation`), so a single-chapter feast or
/// story reads exactly like the passage page it borrows these cards from.
class _TopicLocationLabel extends StatelessWidget {
  const _TopicLocationLabel(this.book, this.chapter);

  final String book;
  final int chapter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Text(
        '$book $chapter',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Merges a topic's per-chapter places into one deduped, name-ordered list —
/// the map/chips on the topic page plot every chapter's markers together. A
/// place's merged `verses` list mixes verse numbers across whatever chapters
/// it appeared in, so it's only meaningful (and only shown) when the topic
/// has just one location — see the `multiLocation` check where this is used.
List<PlaceInPassage> _mergeTopicPlaces(
  List<ExplorerTopicLocationFacets> facets,
) {
  final byId = <int, PlaceInPassage>{};
  for (final f in facets) {
    for (final p in f.places) {
      final existing = byId[p.id];
      if (existing == null) {
        byId[p.id] = PlaceInPassage(
          id: p.id,
          name: p.name,
          lat: p.lat,
          lng: p.lng,
          verses: [...p.verses],
        );
      } else {
        existing.verses.addAll(p.verses);
      }
    }
  }
  return byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}

/// Merges a topic's per-chapter video groups into one group per collection,
/// de-duplicating items a story's overlapping chapters would otherwise list
/// twice (matched by youtube id/slug, falling back to title).
List<MediaGroup> _mergeTopicVideoGroups(
  List<ExplorerTopicLocationFacets> facets,
) {
  final merged = <String, MediaGroup>{};
  final seenKeys = <String, Set<String>>{};
  for (final f in facets) {
    for (final g in f.videoGroups) {
      final keys = seenKeys.putIfAbsent(g.collection.name, () => {});
      final newItems = [
        for (final item in g.items)
          if (keys.add(item.id ?? item.slug ?? item.title)) item,
      ];
      if (newItems.isEmpty) continue;
      final existing = merged[g.collection.name];
      merged[g.collection.name] = MediaGroup(
        collection: g.collection,
        items: existing == null ? newItems : [...existing.items, ...newItems],
      );
    }
  }
  return merged.values.toList();
}

/// Merges a topic's per-chapter media attachments, de-duplicating by id (an
/// attachment tagged to more than one of a story's chapters would otherwise
/// appear once per chapter).
List<MediaAttachment> _mergeTopicAttachments(
  List<ExplorerTopicLocationFacets> facets,
) {
  final byId = <String, MediaAttachment>{};
  for (final f in facets) {
    for (final a in f.attachments) {
      byId[a.id] = a;
    }
  }
  return byId.values.toList();
}

// --- Tag ---

class _TagPage extends ConsumerWidget {
  const _TagPage({required this.tagId});

  final String tagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(explorerTagDetailProvider(tagId));
    final crossRefs = ref
        .watch(explorerTagCrossRefsProvider(tagId))
        .asData
        ?.value;
    final commentaries =
        ref.watch(explorerTagCommentariesProvider(tagId)).asData?.value ??
        const <ExplorerCommentarySection>[];
    final crossRefGroups =
        ref.watch(explorerTagCrossReferencesProvider(tagId)).asData?.value ??
        const <ExplorerCrossRefGroup>[];
    return detailAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => _ErrorBody('Couldn\'t load this tag: $e'),
      data: (d) {
        if (d == null) {
          // Tags are user data: unlike the bundled entities, one can vanish
          // from under its breadcrumb (deleted here or on a synced device).
          return const _ErrorBody(
            'This tag no longer exists — it may have been deleted, '
            'possibly on another device.',
          );
        }
        return _PageScroll(
          children: [
            _PageTitle(title: '#${d.tag.name}', subtitle: 'Your tag'),
            if (d.isEmpty)
              const _ErrorBody('Nothing is filed under this tag yet.'),
            if (d.verses.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.menu_book_outlined,
                title: 'Tagged verses (${d.verses.length})',
                child: Column(
                  children: [
                    for (final v in d.verses) _TaggedItemTile(item: v),
                  ],
                ),
              ),
            if (crossRefs != null && crossRefs.people.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.person_outline,
                title: 'People in these verses (${crossRefs.people.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in crossRefs.people)
                      ExplorerRefChip(
                        ExplorerRef.person(p.id, p.label),
                        subtitle: _tagRefCountLabel(p.verseCount),
                      ),
                  ],
                ),
              ),
            if (crossRefs != null && crossRefs.places.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.place_outlined,
                title: 'Places in these verses (${crossRefs.places.length})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExplorerMap(
                      places: [
                        for (final p in crossRefs.places)
                          ExplorerMapPlace(p.id, p.label, p.lat!, p.lng!),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final p in crossRefs.places)
                          ExplorerRefChip(
                            ExplorerRef.place(p.id, p.label),
                            subtitle: _tagRefCountLabel(p.verseCount),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            if (crossRefs != null && crossRefs.events.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.flag_outlined,
                title: 'Events in these verses (${crossRefs.events.length})',
                child: Column(
                  children: [
                    for (final e in crossRefs.events)
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
            if (crossRefs != null && crossRefs.topics.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.topic_outlined,
                title: 'Topics in these verses (${crossRefs.topics.length})',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in crossRefs.topics)
                      ExplorerRefChip(
                        ExplorerRef.topic(t.id, t.label),
                        subtitle: _tagRefCountLabel(t.verseCount),
                      ),
                  ],
                ),
              ),
            if (d.passages.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.travel_explore,
                title: 'Explore their chapters',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final p in d.passages)
                      ExplorerRefChip(ExplorerRef.passage(p.book, p.chapter)),
                  ],
                ),
              ),
            if (d.media.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.attachment_outlined,
                title: 'Media (${d.media.length})',
                child: Column(
                  children: [
                    for (final m in d.media) _AttachmentTile(attachment: m),
                  ],
                ),
              ),
            if (commentaries.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.import_contacts_outlined,
                title: 'Commentaries (${commentaries.length})',
                child: Column(
                  children: [
                    for (final section in commentaries)
                      _CommentarySection(section: section),
                  ],
                ),
              ),
            if (crossRefGroups.isNotEmpty)
              ExplorerCollapsibleFacetCard(
                icon: Icons.compare_arrows_outlined,
                title:
                    'Cross-references '
                    '(${crossRefGroups.fold(0, (n, g) => n + g.refs.length)})',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in crossRefGroups)
                      _CrossRefGroupTile(group: group),
                  ],
                ),
              ),
            if (d.notes.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.edit_note_outlined,
                title: 'Notes (${d.notes.length})',
                child: Column(
                  children: [for (final n in d.notes) _TaggedItemTile(item: n)],
                ),
              ),
            if (d.sermons.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.co_present_outlined,
                title: 'Sermons (${d.sermons.length})',
                child: Column(
                  children: [
                    for (final s in d.sermons) _TaggedItemTile(item: s),
                  ],
                ),
              ),
            if (d.notebooks.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.library_books_outlined,
                title: 'Notebooks (${d.notebooks.length})',
                child: Column(
                  children: [
                    for (final n in d.notebooks) _TaggedItemTile(item: n),
                  ],
                ),
              ),
            if (d.journals.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.edit_document,
                title: 'Journals (${d.journals.length})',
                child: Column(
                  children: [
                    for (final j in d.journals) _TaggedItemTile(item: j),
                  ],
                ),
              ),
            if (d.prayers.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.volunteer_activism_outlined,
                title: 'Prayers (${d.prayers.length})',
                child: Column(
                  children: [
                    for (final p in d.prayers) _TaggedItemTile(item: p),
                  ],
                ),
              ),
            if (d.related.isNotEmpty)
              ExplorerFacetCard(
                icon: Icons.label_outline,
                title: 'Related tags',
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in d.related)
                      ExplorerTagChip(
                        t.tag,
                        subtitle:
                            '${t.itemCount} shared ${t.itemCount == 1 ? 'item' : 'items'}',
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

/// One item filed under a tag; tapping opens it in its home module (reader,
/// sermon editor, journal editor, or the Prayers tab).
class _TaggedItemTile extends ConsumerWidget {
  const _TaggedItemTile({required this.item});

  final SearchResult item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: item.textContent.trim().isEmpty
          ? null
          : Text(
              item.textContent,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () => explorerOpenTaggedItem(context, ref, item),
    );
  }
}

/// Subtitle for a person/place chip on the tag page: how many of the tag's
/// verses mention that entity.
String _tagRefCountLabel(int count) =>
    '$count ${count == 1 ? 'verse' : 'verses'}';

/// A user-uploaded media attachment (image/PDF), shown on the tag and passage
/// pages. Tapping opens the same in-app image or PDF viewer the reader's Media
/// panel uses (only images/PDFs are attachable, so no external-handler fallback
/// is needed).
class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final MediaAttachment attachment;

  Future<File> _resolveFile() async {
    final dir = await appDataDir();
    return File(p.join(dir.path, 'media_attachments', attachment.filename));
  }

  Future<void> _open(BuildContext context) async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found locally. It may still be syncing.'),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final title = attachment.title ?? attachment.filename;
    if (attachment.mimeType.startsWith('image/')) {
      showDialog(
        context: context,
        builder: (_) => ImageViewerDialog(title: title, file: file),
      );
    } else if (attachment.mimeType == 'application/pdf') {
      showDialog(
        context: context,
        builder: (_) => PdfViewerDialog(title: title, file: file),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = attachment.mimeType.startsWith('image/');
    final sizeKb = (attachment.sizeBytes / 1024).toStringAsFixed(1);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(attachment.title ?? attachment.filename),
      subtitle: Text('$sizeKb KB'),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => _open(context),
    );
  }
}

/// The "Your tags" facet card on person/place/event pages: the tags you've
/// put on verses where the entity appears, most shared verses first. Chips
/// drill into the tag's page.
class _EntityTagsCard extends StatelessWidget {
  const _EntityTagsCard({required this.tags});

  final List<ExplorerEntityTag> tags;

  @override
  Widget build(BuildContext context) {
    return ExplorerFacetCard(
      icon: Icons.label_outline,
      title: 'Your tags',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final t in tags)
            ExplorerTagChip(
              t.tag,
              subtitle:
                  '${t.refs.length} ${t.refs.length == 1 ? 'verse' : 'verses'}',
            ),
        ],
      ),
    );
  }
}

/// A user note anchored in this chapter; tapping jumps the reader to the
/// note's verse.
class _PassageNoteTile extends ConsumerWidget {
  const _PassageNoteTile({
    required this.book,
    required this.chapter,
    required this.note,
  });

  final String book;
  final int chapter;
  final Note note;

  String get _label {
    final selected = note.selectedVerses;
    if (selected != null) {
      return selected.contains(',') ? 'Verses $selected' : 'Verse $selected';
    }
    if (note.verse != null) return 'Verse ${note.verse}';
    return 'Chapter note';
  }

  /// The verse the reader should land on: the explicit anchor, else the first
  /// of the selected verses, else the chapter top.
  int get _targetVerse {
    if (note.verse != null) return note.verse!;
    final first = note.selectedVerses?.split(',').first.trim();
    return int.tryParse(first ?? '') ?? 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        _label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        note.content,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () =>
          explorerOpenVerseInReader(context, ref, book, chapter, _targetVerse),
    );
  }
}
