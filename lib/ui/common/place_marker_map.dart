import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A point the map can plot: an id (for tap callbacks), a display name, and
/// coordinates.
class MapPoint {
  final int id;
  final String name;
  final double lat;
  final double lng;
  const MapPoint(this.id, this.name, this.lat, this.lng);

  // Content equality so didUpdateWidget can tell "the same route, rebuilt"
  // (a fresh List instance with identical points, e.g. from stepping through
  // a journey) apart from "a genuinely different set of points" (e.g.
  // switching people) without re-fitting the camera on every rebuild.
  @override
  bool operator ==(Object other) =>
      other is MapPoint &&
      other.id == id &&
      other.name == name &&
      other.lat == lat &&
      other.lng == lng;

  @override
  int get hashCode => Object.hash(id, name, lat, lng);
}

/// Marker rendering: a labeled pin (readable at low marker counts) or a plain
/// dot (for dense marker sets where labels would overlap into clutter).
enum PlaceMarkerStyle { labeledPin, dot }

/// Shared base map for every place marker view in the app: the Places panel,
/// Explorer place/event/person pages, and the Atlas. Offline-tolerant —
/// markers render even when the tile background can't load (place data is
/// bundled/offline; only the OSM tile background needs network).
class PlaceMarkerMap extends StatefulWidget {
  const PlaceMarkerMap({
    super.key,
    required this.points,
    this.style = PlaceMarkerStyle.labeledPin,
    this.onTapPoint,
    this.onExpand,
    this.mapController,
    this.initialZoom = 8,
    this.extraLayers = const [],
    this.autoFitOnPointsChange = true,
  });

  final List<MapPoint> points;
  final PlaceMarkerStyle style;

  /// Whether a later change to [points] (e.g. the Atlas's "show all places"
  /// toggle swapping in a different marker set) should refit the camera.
  /// Default true — e.g. the Places panel re-fitting when the passage
  /// changes. Set false when the caller wants to swap markers in place
  /// without disturbing the user's current pan/zoom.
  final bool autoFitOnPointsChange;

  /// Called when a marker is tapped.
  final void Function(MapPoint point)? onTapPoint;

  /// Shows a small overlaid fullscreen icon (top-right) when non-null; the
  /// caller decides what "expand" navigates to.
  final VoidCallback? onExpand;

  /// Caller-owned controller (e.g. so the caller can programmatically pan
  /// on marker tap). A controller is created internally when omitted.
  final MapController? mapController;

  final double initialZoom;

  /// Additional flutter_map layers, rendered above the point markers and
  /// below the attribution widget — e.g. the Atlas journey mode's route
  /// polylines and animated traveler marker.
  final List<Widget> extraLayers;

  @override
  State<PlaceMarkerMap> createState() => _PlaceMarkerMapState();
}

class _PlaceMarkerMapState extends State<PlaceMarkerMap> {
  bool _tilesFailed = false;
  MapController? _ownedController;

  MapController get _controller =>
      widget.mapController ?? (_ownedController ??= MapController());

  @override
  void initState() {
    super.initState();
    // flutter_map's MapOptions.initialCameraFit only ever fits once, against
    // whatever constraints its very first LayoutBuilder pass sees — its own
    // source warns constraints can be transiently wrong during startup. If a
    // sibling in this map's parent Column (e.g. the journey's step-info card
    // or playback bar) hasn't settled its size yet on that first pass, the
    // fit locks in against a viewport that's about to change and never
    // recovers on its own — the map looks fine, but a marker relying on that
    // same camera (e.g. an animated traveler) can render off from where it
    // should be until a user gesture forces flutter_map to recompute. Redo
    // the fit ourselves one frame later, once layout has actually settled.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCameraIfNeeded());
  }

  @override
  void didUpdateWidget(covariant PlaceMarkerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoFitOnPointsChange &&
        !listEquals(oldWidget.points, widget.points)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCameraIfNeeded());
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  List<LatLng> _fitLatLngs() =>
      [for (final p in widget.points) LatLng(p.lat, p.lng)];

  void _fitCameraIfNeeded() {
    if (!mounted) return;
    final fitLatLngs = _fitLatLngs();
    final distinct = fitLatLngs.map((p) => (p.latitude, p.longitude)).toSet();
    if (distinct.length < 2) return;
    try {
      _controller.fitCamera(CameraFit.coordinates(
        coordinates: fitLatLngs,
        padding: const EdgeInsets.all(40),
      ));
    } catch (_) {
      // Not attached to a rendered FlutterMap yet — MapOptions.initialCameraFit
      // below still covers the first paint in that case.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final points = widget.points;
    if (points.isEmpty) return const SizedBox.shrink();

    final fitLatLngs = _fitLatLngs();
    // Only fit to the coordinates when they span a non-zero area. Multiple
    // places sharing the same coordinate collapse to a single point, and
    // CameraFit.coordinates can't derive a finite zoom from zero-area bounds
    // (it asserts on `zoom.isFinite`). In that case fall back to initialZoom.
    final distinct = fitLatLngs.map((p) => (p.latitude, p.longitude)).toSet();

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCameraFit: distinct.length > 1
                ? CameraFit.coordinates(
                    coordinates: fitLatLngs,
                    padding: const EdgeInsets.all(40),
                  )
                : null,
            initialCenter: fitLatLngs.first,
            initialZoom: widget.initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            backgroundColor: scheme.surfaceContainerHighest,
          ),
          children: [
            // Label-free basemap so the only place names on the map are our
            // English markers (the OSM standard style labels in local languages).
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
            MarkerLayer(markers: [for (final p in points) _marker(scheme, p)]),
            ...widget.extraLayers,
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
            child: _Chip(
              icon: Icons.cloud_off,
              label: 'Map background needs internet',
              color: scheme.errorContainer,
              onColor: scheme.onErrorContainer,
            ),
          ),
        if (widget.onExpand != null)
          Positioned(
            right: 8,
            top: 8,
            child: Material(
              color: scheme.surface.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.open_in_full),
                iconSize: 18,
                tooltip: 'Open fullscreen atlas',
                visualDensity: VisualDensity.compact,
                onPressed: widget.onExpand,
              ),
            ),
          ),
      ],
    );
  }

  Marker _marker(ColorScheme scheme, MapPoint p) {
    switch (widget.style) {
      case PlaceMarkerStyle.labeledPin:
        return Marker(
          point: LatLng(p.lat, p.lng),
          width: 140,
          height: 48,
          // Pin tip sits on the coordinate; the English label floats above.
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            key: ValueKey('marker-${p.id}'),
            onTap: widget.onTapPoint == null ? null : () => widget.onTapPoint!(p),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.85),
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
                  shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
                ),
              ],
            ),
          ),
        );
      case PlaceMarkerStyle.dot:
        return Marker(
          point: LatLng(p.lat, p.lng),
          width: 16,
          height: 16,
          alignment: Alignment.center,
          child: GestureDetector(
            key: ValueKey('marker-${p.id}'),
            onTap: widget.onTapPoint == null ? null : () => widget.onTapPoint!(p),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.error,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(blurRadius: 2, color: Colors.black38),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onColor),
          const SizedBox(width: 6),
          Text(
            label,
            style:
                Theme.of(context).textTheme.labelSmall?.copyWith(color: onColor),
          ),
        ],
      ),
    );
  }
}
