import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../app/app_state.dart';
import '../../app/content_providers.dart';
import '../../app/place_providers.dart';
import '../../app/reader_state.dart';
import '../common/breakpoints.dart';
import '../common/empty_state.dart';
import '../common/place_marker_map.dart';
import '../common/skeleton.dart';
import 'atlas_screen.dart';

/// Maps the geographic places mentioned in the active passage (OpenBible.info
/// geocoding). Place data is bundled/offline; only the OSM tile background needs
/// network — when it's unavailable the markers and list still work.
class PlacesPanel extends ConsumerStatefulWidget {
  const PlacesPanel({super.key});

  @override
  ConsumerState<PlacesPanel> createState() => _PlacesPanelState();
}

class _PlacesPanelState extends ConsumerState<PlacesPanel> {
  final MapController _map = MapController();

  void _goToVerse(String book, int chapter, int verse) {
    ref.read(selectedBookNameProvider.notifier).set(book);
    ref.read(selectedChapterProvider.notifier).set(chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(verse);
    ref.read(selectedVersesProvider.notifier).clear();
    ref.read(selectedVersesProvider.notifier).toggle(verse);
    ref.read(navigationControllerProvider).recordHistory(verse: verse);
    if (MediaQuery.sizeOf(context).width <= Breakpoints.compact) {
      Navigator.of(context).maybePop();
    }
  }

  void _focusPlace(PlaceInPassage p) {
    ref.read(selectedPlaceProvider.notifier).select(p.id);
    _map.move(LatLng(p.lat, p.lng), 9);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final book = ref.watch(selectedBookNameProvider);
    final chapter = ref.watch(selectedChapterProvider);
    final placesAsync = ref.watch(currentPassagePlacesProvider);

    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Places — $book $chapter',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
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
          ),
          const Divider(height: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: placesAsync.when(
              loading: () => const SkeletonList(),
              error: (e, _) => const EmptyState(
                icon: Icons.error_outline,
                title: 'Couldn\'t load places',
              ),
              data: (places) {
                if (places.isEmpty) {
                  return const EmptyState(
                    icon: Icons.place_outlined,
                    title: 'No mapped places',
                    message: 'This passage doesn\'t mention any places we can map.',
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Size the map as a fraction of the available height (capped)
                    // so the list always gets the remainder — the panel never
                    // overflows when the sidebar is short.
                    final mapHeight =
                        (constraints.maxHeight * 0.4).clamp(0.0, 280.0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: mapHeight,
                          child: _buildMap(context, book, chapter, places),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: _buildList(context, book, chapter, places),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
      BuildContext context, String book, int chapter, List<PlaceInPassage> places) {
    return PlaceMarkerMap(
      // Re-fit the camera whenever the passage changes.
      key: ValueKey('$book|$chapter'),
      mapController: _map,
      points: [for (final p in places) MapPoint(p.id, p.name, p.lat, p.lng)],
      onTapPoint: (mp) => _focusPlace(places.firstWhere((p) => p.id == mp.id)),
      onExpand: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AtlasScreen(
            initialPoints: [
              for (final p in places) MapPoint(p.id, p.name, p.lat, p.lng),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, String book, int chapter, List<PlaceInPassage> places) {
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(selectedPlaceProvider);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: places.length,
      itemBuilder: (context, i) {
        final p = places[i];
        return Container(
          color: p.id == selected ? scheme.primaryContainer.withValues(alpha: 0.3) : null,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.location_on, color: scheme.error, size: 20),
            title: Text(p.name),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final v in p.verses)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text('v$v'),
                      onPressed: () => _goToVerse(book, chapter, v),
                    ),
                ],
              ),
            ),
            onTap: () => _focusPlace(p),
          ),
        );
      },
    );
  }
}
