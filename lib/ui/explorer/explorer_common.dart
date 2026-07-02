import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/content_providers.dart';
import '../../app/explorer_providers.dart';
import '../../app/reader_state.dart';
import '../../domain/explorer/explorer_ref.dart';

/// Formats an ISO year for display: negative years are BC.
String explorerYearLabel(int year) => year < 0 ? '${-year} BC' : 'AD $year';

IconData explorerEntityIcon(ExplorerEntityType type) => switch (type) {
      ExplorerEntityType.person => Icons.person_outline,
      ExplorerEntityType.place => Icons.place_outlined,
      ExplorerEntityType.event => Icons.flag_outlined,
      ExplorerEntityType.topic => Icons.topic_outlined,
      ExplorerEntityType.passage => Icons.menu_book_outlined,
    };

/// Jump the reader to a verse and unwind back to the shell so it's visible.
void explorerOpenVerseInReader(
  BuildContext context,
  WidgetRef ref,
  String book,
  int chapter,
  int verse,
) {
  ref.read(selectedBookNameProvider.notifier).set(book);
  ref.read(selectedChapterProvider.notifier).set(chapter);
  ref.read(targetVerseToScrollProvider.notifier).set(verse);
  ref.read(selectedVersesProvider.notifier).clear();
  ref.read(selectedVersesProvider.notifier).toggle(verse);
  ref.read(navigationControllerProvider).recordHistory(verse: verse);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// One facet of an entity page: a card with an icon-and-title header and the
/// facet's content below.
class ExplorerFacetCard extends StatelessWidget {
  const ExplorerFacetCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// A chip that drills into another Explorer entity.
class ExplorerRefChip extends ConsumerWidget {
  const ExplorerRefChip(this.target, {super.key, this.subtitle});

  final ExplorerRef target;

  /// Optional qualifier rendered after the label, de-emphasized.
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(
        explorerEntityIcon(target.type),
        size: 16,
        color: scheme.primary,
      ),
      label: subtitle == null
          ? Text(target.label)
          : Text.rich(
              TextSpan(
                text: target.label,
                children: [
                  TextSpan(
                    text: '  $subtitle',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
      onPressed: () => ref.read(explorerTrailProvider.notifier).open(target),
    );
  }
}

/// A chip that opens a verse in the reader (leaving the Explorer).
class ExplorerVerseChip extends ConsumerWidget {
  const ExplorerVerseChip({
    super.key,
    required this.book,
    required this.chapter,
    required this.verse,
    this.label,
  });

  final String book;
  final int chapter;
  final int verse;

  /// Chip text; defaults to the full "Book chapter:verse" reference.
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(label ?? '$book $chapter:$verse'),
      onPressed: () =>
          explorerOpenVerseInReader(context, ref, book, chapter, verse),
    );
  }
}

/// Verse references grouped one-expansion-tile-per-book, so entities with
/// hundreds of mentions stay scannable. [refs] must be in canonical order.
class ExplorerVerseGroups extends StatelessWidget {
  const ExplorerVerseGroups({super.key, required this.refs});

  final List<({String book, int chapter, int verse})> refs;

  @override
  Widget build(BuildContext context) {
    final byBook = <String, List<({String book, int chapter, int verse})>>{};
    for (final r in refs) {
      byBook.putIfAbsent(r.book, () => []).add(r);
    }
    return Column(
      children: [
        for (final entry in byBook.entries)
          ExpansionTile(
            dense: true,
            tilePadding: EdgeInsets.zero,
            title: Text('${entry.key} (${entry.value.length})'),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in entry.value)
                        ExplorerVerseChip(
                          book: r.book,
                          chapter: r.chapter,
                          verse: r.verse,
                          label: '${r.chapter}:${r.verse}',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// A marker the Explorer map can plot; tapping drills into the place.
class ExplorerMapPlace {
  final int id;
  final String name;
  final double lat;
  final double lng;
  const ExplorerMapPlace(this.id, this.name, this.lat, this.lng);
}

/// Small embedded map for place/event pages, offline-tolerant like the Places
/// panel: markers render even when the tile background can't load.
class ExplorerMap extends ConsumerStatefulWidget {
  const ExplorerMap({super.key, required this.places});

  final List<ExplorerMapPlace> places;

  @override
  ConsumerState<ExplorerMap> createState() => _ExplorerMapState();
}

class _ExplorerMapState extends ConsumerState<ExplorerMap> {
  bool _tilesFailed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final points = [for (final p in widget.places) LatLng(p.lat, p.lng)];
    if (points.isEmpty) return const SizedBox.shrink();
    // CameraFit.coordinates asserts on zero-area bounds, so it needs at least
    // two distinct coordinates (see PlacesPanel).
    final distinct = points.map((p) => (p.latitude, p.longitude)).toSet();

    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              key: ValueKey(
                widget.places.map((p) => p.id).join(','),
              ),
              options: MapOptions(
                initialCameraFit: distinct.length > 1
                    ? CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(40),
                      )
                    : null,
                initialCenter: points.first,
                initialZoom: 7,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                backgroundColor: scheme.surfaceContainerHighest,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'io.github.crazymevt.studybible',
                  errorTileCallback: (tile, error, stackTrace) {
                    if (!_tilesFailed && mounted) {
                      WidgetsBinding.instance.addPostFrameCallback(
                          (_) => setState(() => _tilesFailed = true));
                    }
                  },
                ),
                MarkerLayer(
                  markers: [
                    for (final p in widget.places)
                      Marker(
                        point: LatLng(p.lat, p.lng),
                        width: 140,
                        height: 48,
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () => ref
                              .read(explorerTrailProvider.notifier)
                              .open(ExplorerRef.place(p.id, p.name)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      scheme.surface.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Icon(
                                Icons.location_on,
                                color: scheme.error,
                                size: 28,
                                shadows: const [
                                  Shadow(blurRadius: 3, color: Colors.black54)
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                    TextSourceAttribution('CARTO'),
                  ],
                ),
              ],
            ),
            if (_tilesFailed)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off,
                          size: 14, color: scheme.onErrorContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Map background needs internet',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: scheme.onErrorContainer),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
