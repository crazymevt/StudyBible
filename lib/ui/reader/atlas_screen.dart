import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/atlas_providers.dart';
import '../../app/content_providers.dart';
import '../../app/people_providers.dart';
import '../../app/reader_state.dart';
import '../common/empty_state.dart';
import '../common/place_marker_map.dart';
import '../common/skeleton.dart';
import 'people_panel.dart' show formatIsoYear;

/// Fullscreen, pannable/zoomable map of every geocoded Bible place, with an
/// animated "journey" mode for a chosen person: their dated events, plotted
/// in chronological order and connected as a path. The bundled datasets have
/// no curated notion of a journey (e.g. Paul's missionary journeys aren't
/// modeled data anywhere) — the path is auto-derived from the person's
/// existing dated events, each resolved to a place via [personJourneyProvider].
class AtlasScreen extends ConsumerStatefulWidget {
  const AtlasScreen({super.key, this.initialPersonId, this.initialPoints});

  /// Non-null: open straight into journey mode for this person.
  final int? initialPersonId;

  /// Browse-mode camera seed — the points the caller was already showing
  /// when it expanded into the Atlas. Ignored once a person is selected.
  final List<MapPoint>? initialPoints;

  @override
  ConsumerState<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends ConsumerState<AtlasScreen>
    with TickerProviderStateMixin {
  static const _legDuration = Duration(milliseconds: 2200);

  // Separate controllers for browse mode and journey mode — never shared.
  // _followCamera can fire synchronously (via _controller.value = 0, from
  // _selectPerson/_step/etc.) before the corresponding PlaceMarkerMap has
  // even rebuilt, and a controller that's still attached to a *different*,
  // about-to-be-replaced FlutterMap (e.g. the browse map, mid-transition to
  // journey mode) getting an unexpected .move() call is exactly the kind of
  // stray update that's shown up as a leftover/misplaced marker on Android.
  // Recreating _journeyMap fresh per person closes that off: a premature
  // call targets a controller that isn't attached to anything yet (throws,
  // caught, no-op) instead of a live one.
  final _browseMap = MapController();
  MapController _journeyMap = MapController();
  late final AnimationController _controller;
  int? _personId;
  /// The waypoint currently at rest (0..waypoints.length-1). While playing,
  /// the animation runs the leg from [_position] to [_position] + 1, then
  /// [_position] advances once that leg completes.
  int _position = 0;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _personId = widget.initialPersonId;
    _controller = AnimationController(vsync: this, duration: _legDuration)
      ..addStatusListener(_onStatus)
      ..addListener(_followCamera);
  }

  @override
  void dispose() {
    _controller.dispose();
    _browseMap.dispose();
    _journeyMap.dispose();
    super.dispose();
  }

  List<JourneyWaypoint>? _waypointsOrNull() {
    final id = _personId;
    if (id == null) return null;
    return ref.read(personJourneyProvider(id)).asData?.value?.waypoints;
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final waypoints = _waypointsOrNull();
    if (waypoints == null) return;
    setState(() => _position = (_position + 1).clamp(0, waypoints.length - 1));
    if (_playing && _position < waypoints.length - 1) {
      _controller.forward(from: 0);
    } else {
      setState(() => _playing = false);
      _controller.value = 0;
    }
  }

  /// The leg the traveler is currently on (or resting at the end of): the
  /// waypoints either side, and how far between them ([0, 1]). When resting
  /// at the final waypoint, both ends are that waypoint (t is irrelevant).
  (JourneyWaypoint, JourneyWaypoint, double) _currentLeg(
      List<JourneyWaypoint> waypoints) {
    final atEnd = _position >= waypoints.length - 1;
    final a = waypoints[atEnd ? waypoints.length - 1 : _position];
    final b = waypoints[atEnd ? waypoints.length - 1 : _position + 1];
    return (a, b, _controller.value);
  }

  LatLng _lerp(JourneyWaypoint a, JourneyWaypoint b, double t) => LatLng(
        a.lat + (b.lat - a.lat) * t,
        a.lng + (b.lng - a.lng) * t,
      );

  /// Pans the map to the traveler's current interpolated position each tick.
  /// A no-op until the map has rendered at least one frame.
  void _followCamera() {
    final waypoints = _waypointsOrNull();
    if (waypoints == null || waypoints.length < 2) return;
    final (a, b, t) = _currentLeg(waypoints);
    try {
      _journeyMap.move(_lerp(a, b, t), _journeyMap.camera.zoom);
    } catch (_) {
      // Map hasn't rendered a first frame yet.
    }
  }

  void _togglePlay(List<JourneyWaypoint> waypoints) {
    final resuming = !_playing;
    setState(() => _playing = resuming);
    if (!resuming) {
      _controller.stop();
      // Settle at the nearer waypoint rather than freezing mid-leg: without
      // this, the traveler marker is left part-way between two waypoints
      // (a real, correctly-interpolated point) while the step card and
      // footnote still show the leg's starting waypoint, which reads as the
      // marker having been "dropped" in the wrong place.
      final t = _controller.value;
      if (t >= 0.5 && _position < waypoints.length - 1) {
        setState(() => _position++);
      }
      _controller.value = 0;
      return;
    }
    if (_position >= waypoints.length - 1) {
      setState(() => _position = 0);
      _controller.forward(from: 0);
    } else {
      _controller.forward(from: _controller.value);
    }
  }

  void _step(List<JourneyWaypoint> waypoints, int delta) {
    setState(() {
      _playing = false;
      _position = (_position + delta).clamp(0, waypoints.length - 1);
    });
    _controller
      ..stop()
      ..value = 0;
  }

  void _scrubTo(List<JourneyWaypoint> waypoints, double value) {
    setState(() {
      _playing = false;
      _position = value.round().clamp(0, waypoints.length - 1);
    });
    _controller
      ..stop()
      ..value = 0;
  }

  void _selectPerson(int id) {
    // Fresh controller *before* touching _controller's value below — a
    // synchronous _followCamera firing from that reset must land on a
    // controller that isn't attached to anything yet, not the previous
    // journey's (or the browse map's) live one.
    _journeyMap.dispose();
    _journeyMap = MapController();
    setState(() {
      _personId = id;
      _position = 0;
      _playing = false;
    });
    _controller
      ..stop()
      ..value = 0;
  }

  void _backToBrowse() {
    setState(() {
      _personId = null;
      _position = 0;
      _playing = false;
    });
    _controller
      ..stop()
      ..value = 0;
  }

  void _goToVerse(String book, int chapter, int verse) {
    ref.read(selectedBookNameProvider.notifier).set(book);
    ref.read(selectedChapterProvider.notifier).set(chapter);
    ref.read(targetVerseToScrollProvider.notifier).set(verse);
    ref.read(selectedVersesProvider.notifier).clear();
    ref.read(selectedVersesProvider.notifier).toggle(verse);
    ref.read(navigationControllerProvider).recordHistory(verse: verse);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Atlas'),
        content: const Text(
          'Browse every geocoded place in the Bible, or pick a person to '
          'follow their journey: their dated events, plotted in order and '
          'connected as an animated path.\n\n'
          'Journeys are auto-derived, not curated — the bundled datasets '
          "don't record journeys as such. Each step is the first place named "
          "in that event's account. Some events are undated, or don't "
          'resolve to a mappable place; those are counted but left off the '
          'path.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _openPersonSearch() async {
    // Wait for the sheet's pop to fully finish (not just fire) before
    // switching to journey mode: selecting a result closes the keyboard and
    // the sheet, and if the map builds — fixing its one-time initial camera
    // fit — before the on-screen keyboard has finished collapsing, that fit
    // is computed against the temporarily shrunk viewport and never
    // recovers once the keyboard is gone, leaving the journey visibly
    // offset.
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _PersonSearchSheet(),
    );
    if (id != null) _selectPerson(id);
  }

  void _showPlaceSheet(MapPoint p) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(p.name),
          trailing: TextButton(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _browseMap.move(LatLng(p.lat, p.lng), 9);
            },
            child: const Text('Center here'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas'),
        actions: [
          if (_personId != null)
            IconButton(
              icon: const Icon(Icons.public),
              tooltip: 'Back to browse',
              onPressed: _backToBrowse,
            )
          else
            IconButton(
              icon: const Icon(Icons.person_search),
              tooltip: "Follow a person's journey",
              onPressed: _openPersonSearch,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'About the Atlas',
            onPressed: _showHelp,
          ),
        ],
      ),
      body: _personId == null ? _buildBrowse() : _buildJourney(_personId!),
    );
  }

  Widget _buildBrowse() {
    final placesAsync = ref.watch(allPlacesProvider);
    return placesAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => Center(child: Text('Could not load places: $e')),
      data: (places) {
        if (places.isEmpty) {
          return const EmptyState(
            icon: Icons.public_off,
            title: 'No places to show',
          );
        }
        return PlaceMarkerMap(
          mapController: _browseMap,
          points: [
            for (final p in places) MapPoint(p.id, p.name, p.lat, p.lng),
          ],
          cameraFitPoints: widget.initialPoints,
          style: PlaceMarkerStyle.dot,
          initialZoom: 5,
          onTapPoint: _showPlaceSheet,
        );
      },
    );
  }

  Widget _buildJourney(int personId) {
    final journeyAsync = ref.watch(personJourneyProvider(personId));
    return journeyAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => Center(child: Text('Could not load this journey: $e')),
      data: (journey) {
        if (journey == null) {
          return const EmptyState(
            icon: Icons.person_off_outlined,
            title: 'Person not found',
          );
        }
        final waypoints = journey.waypoints;
        final excluded =
            journey.undatedEventCount + journey.unmappedEventCount;
        if (waypoints.isEmpty) {
          final reasons = <String>[
            if (journey.undatedEventCount > 0)
              '${journey.undatedEventCount} undated',
            if (journey.unmappedEventCount > 0)
              '${journey.unmappedEventCount} with no mappable location',
          ];
          return EmptyState(
            icon: Icons.map_outlined,
            title: 'No journey to show',
            message: reasons.isEmpty
                ? '${journey.displayTitle} has no dated events yet.'
                : "${journey.displayTitle}'s events are all "
                    '${reasons.join(' or ')}.',
          );
        }

        final points = [
          for (final w in waypoints)
            MapPoint(w.eventId, w.placeName, w.lat, w.lng),
        ];
        final current = waypoints[_position.clamp(0, waypoints.length - 1)];

        return Column(
          children: [
            Expanded(
              child: PlaceMarkerMap(
                key: ValueKey(personId),
                mapController: _journeyMap,
                points: points,
                initialZoom: 7,
                extraLayers: waypoints.length < 2
                    ? const []
                    : [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) =>
                              PolylineLayer(polylines: _polylines(waypoints)),
                        ),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => MarkerLayer(
                              markers: [_travelerMarker(waypoints)]),
                        ),
                      ],
              ),
            ),
            _StepInfoCard(
              waypoint: current,
              onReadPassage: current.bookName == null
                  ? null
                  : () => _goToVerse(
                      current.bookName!, current.chapter!, current.verse!),
            ),
            if (excluded > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  '$excluded event${excluded == 1 ? '' : 's'} not shown '
                  '(${journey.undatedEventCount} undated, '
                  '${journey.unmappedEventCount} no mappable location).',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            if (waypoints.length > 1)
              _PlaybackBar(
                position: _position,
                stepCount: waypoints.length,
                playing: _playing,
                onTogglePlay: () => _togglePlay(waypoints),
                onStepBack: () => _step(waypoints, -1),
                onStepForward: () => _step(waypoints, 1),
                onScrub: (v) => _scrubTo(waypoints, v),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  List<Polyline> _polylines(List<JourneyWaypoint> waypoints) {
    final scheme = Theme.of(context).colorScheme;
    final (a, b, t) = _currentLeg(waypoints);
    final current = _lerp(a, b, t);
    final traveledEnd =
        _position.clamp(0, waypoints.length - 1); // waypoints fully passed
    return [
      Polyline(
        points: [for (final w in waypoints) LatLng(w.lat, w.lng)],
        strokeWidth: 2,
        color: scheme.outline,
        pattern: StrokePattern.dashed(segments: <double>[8, 6]),
      ),
      Polyline(
        points: [
          for (var i = 0; i <= traveledEnd; i++)
            LatLng(waypoints[i].lat, waypoints[i].lng),
          current,
        ],
        strokeWidth: 3,
        color: scheme.primary,
      ),
    ];
  }

  Marker _travelerMarker(List<JourneyWaypoint> waypoints) {
    final scheme = Theme.of(context).colorScheme;
    final (a, b, t) = _currentLeg(waypoints);
    final point = _lerp(a, b, t);
    return Marker(
      point: point,
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: Icon(
        Icons.directions_walk,
        color: scheme.primary,
        size: 22,
        shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
      ),
    );
  }
}

class _PersonSearchSheet extends ConsumerStatefulWidget {
  const _PersonSearchSheet();

  @override
  ConsumerState<_PersonSearchSheet> createState() =>
      _PersonSearchSheetState();
}

class _PersonSearchSheetState extends ConsumerState<_PersonSearchSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(personSearchQueryProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(personSearchQueryProvider).trim();
    final resultsAsync = ref.watch(personSearchResultsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search people (e.g. Paul, David)…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) =>
                  ref.read(personSearchQueryProvider.notifier).setQuery(v),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: query.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child:
                          Text("Search for a person to follow their journey."),
                    )
                  : resultsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (people) => people.isEmpty
                          ? Center(child: Text('No people matching "$query".'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: people.length,
                              itemBuilder: (context, i) {
                                final p = people[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(p.displayTitle),
                                  subtitle: Text(
                                    '${p.verseCount} '
                                    '${p.verseCount == 1 ? 'verse' : 'verses'}',
                                  ),
                                  onTap: () {
                                    // Dismiss the keyboard before the sheet
                                    // closes so the journey map isn't built
                                    // against a keyboard-shrunk viewport.
                                    FocusScope.of(context).unfocus();
                                    Navigator.of(context).pop(p.id);
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepInfoCard extends StatelessWidget {
  const _StepInfoCard({required this.waypoint, required this.onReadPassage});

  final JourneyWaypoint waypoint;
  final VoidCallback? onReadPassage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  waypoint.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${formatIsoYear(waypoint.startYear)} · ${waypoint.placeName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (onReadPassage != null)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.menu_book, size: 18),
              label: const Text('Read passage'),
              onPressed: onReadPassage,
            ),
        ],
      ),
    );
  }
}

class _PlaybackBar extends StatelessWidget {
  const _PlaybackBar({
    required this.position,
    required this.stepCount,
    required this.playing,
    required this.onTogglePlay,
    required this.onStepBack,
    required this.onStepForward,
    required this.onScrub,
  });

  final int position;
  final int stepCount;
  final bool playing;
  final VoidCallback onTogglePlay;
  final VoidCallback onStepBack;
  final VoidCallback onStepForward;
  final ValueChanged<double> onScrub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            tooltip: 'Previous step',
            onPressed: position > 0 ? onStepBack : null,
          ),
          IconButton(
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            tooltip: playing ? 'Pause' : 'Play',
            onPressed: onTogglePlay,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Next step',
            onPressed: position < stepCount - 1 ? onStepForward : null,
          ),
          Expanded(
            child: Slider(
              value: position.toDouble().clamp(0, (stepCount - 1).toDouble()),
              min: 0,
              max: (stepCount - 1).toDouble(),
              divisions: stepCount > 1 ? stepCount - 1 : null,
              onChanged: onScrub,
            ),
          ),
        ],
      ),
    );
  }
}
