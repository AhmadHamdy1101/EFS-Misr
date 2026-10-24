import 'package:efs_misr/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Cairo, used when there is nothing to center on yet.
const defaultMapCenter = LatLng(30.0444, 31.2357);

/// Map tile styles. Both are OpenStreetMap community servers: free, no API
/// key, but subject to their fair-use tile policies (fine for a staff app;
/// switch to a paid or self-hosted tile provider for heavy use).
enum TrackingMapStyle {
  standard('https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
  humanitarian('https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png');

  const TrackingMapStyle(this.urlTemplate);

  final String urlTemplate;

  TrackingMapStyle get next =>
      TrackingMapStyle.values[(index + 1) % TrackingMapStyle.values.length];
}

/// The OpenStreetMap view used by every tracking screen, with the rounded
/// zoom buttons from the design and the required attribution.
class TrackingMap extends StatefulWidget {
  const TrackingMap({
    super.key,
    required this.markers,
    this.controller,
    this.initialCenter = defaultMapCenter,
    this.initialZoom = 11,
    this.style = TrackingMapStyle.standard,
    this.showZoomButtons = true,
    this.zoomButtonsTop = 16,
    this.onMapReady,
  });

  final VoidCallback? onMapReady;

  final List<Marker> markers;
  final MapController? controller;
  final LatLng initialCenter;
  final double initialZoom;
  final TrackingMapStyle style;
  final bool showZoomButtons;
  final double zoomButtonsTop;

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap> {
  late final MapController _ownController = MapController();

  MapController get _controller => widget.controller ?? _ownController;

  void _zoom(double delta) {
    final camera = _controller.camera;
    _controller.move(camera.center, (camera.zoom + delta).clamp(3, 18));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            onMapReady: widget.onMapReady,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: widget.style.urlTemplate,
              userAgentPackageName: 'com.example.efs_misr',
              maxZoom: 19,
            ),
            MarkerLayer(markers: widget.markers),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        if (widget.showZoomButtons)
          Positioned(
            right: 16,
            top: widget.zoomButtonsTop,
            child: Column(
              children: [
                _MapButton(icon: Icons.add, onTap: () => _zoom(1)),
                const SizedBox(height: 12),
                _MapButton(icon: Icons.remove, onTap: () => _zoom(-1)),
              ],
            ),
          ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.black87, size: 28),
        ),
      ),
    );
  }
}

/// The round technician pin: green with a check badge when live, grey when
/// the position is stale.
class WorkerMarker extends StatelessWidget {
  const WorkerMarker({super.key, required this.live, this.size = 64});

  final bool live;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = live ? AppColors.green : AppColors.gray;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: Icon(
              Icons.engineering,
              color: Colors.white,
              size: size * 0.48,
            ),
          ),
          if (live)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.check, color: Colors.white, size: size * 0.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Destination branch pin.
class BranchMarker extends StatelessWidget {
  const BranchMarker({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.green, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Icon(
        Icons.account_balance,
        color: AppColors.green,
        size: size * 0.5,
      ),
    );
  }
}

/// The technician's own position before sharing starts (screenshot's grey
/// paused pin).
class IdleMarker extends StatelessWidget {
  const IdleMarker({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.gray,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Icon(Icons.pause, color: Colors.white, size: size * 0.45),
    );
  }
}
