import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/app_colors.dart';
import '../../data/models/worker_location_model.dart';
import '../controller/tracking_state.dart';

enum MapStyleType { openStreetMap, satellite, cartoDark, cartoLight }

class TrackingMapWidget extends StatelessWidget {
  const TrackingMapWidget({
    super.key,
    required this.state,
    required this.mapController,
    required this.currentMapStyle,
    required this.onMarkerTap,
  });

  final TrackingState state;
  final MapController mapController;
  final MapStyleType currentMapStyle;
  final ValueChanged<WorkerLocationModel> onMarkerTap;

  static const LatLng _cairoCenter = LatLng(30.0444, 31.2357);

  String _getTileUrlTemplate() {
    switch (currentMapStyle) {
      case MapStyleType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapStyleType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapStyleType.cartoDark:
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapStyleType.cartoLight:
        return 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
    }
  }

  Color _getStatusColor(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.live:
        return AppColors.successGreen;
      case WorkerStatus.offline:
        return AppColors.gray;
      case WorkerStatus.pending:
        return Colors.orange;
      case WorkerStatus.declined:
        return Colors.red;
    }
  }

  List<Marker> _buildMarkers() {
    return state.workers
        .where((WorkerLocationModel w) => w.status == WorkerStatus.live)
        .map((WorkerLocationModel worker) {
      final isSelected = state.selectedWorker?.id == worker.id;
      final statusColor = _getStatusColor(worker.status);

      return Marker(
        width: isSelected ? 52 : 42,
        height: isSelected ? 52 : 42,
        point: worker.location,
        child: GestureDetector(
          onTap: () => onMarkerTap(worker),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 48 : 38,
                height: isSelected ? 48 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.45),
                      blurRadius: isSelected ? 12 : 5,
                      spreadRadius: isSelected ? 4 : 1,
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.white,
                    width: isSelected ? 3 : 2,
                  ),
                ),
                child: const Icon(
                  Icons.engineering,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.green,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: state.selectedWorker?.location ?? _cairoCenter,
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: _getTileUrlTemplate(),
          userAgentPackageName: 'com.efsmisr.app',
        ),
        MarkerLayer(
          markers: _buildMarkers(),
        ),
      ],
    );
  }
}
