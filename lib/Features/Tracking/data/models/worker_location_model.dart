import 'package:latlong2/latlong.dart';

enum WorkerStatus { live, offline, pending, declined }

class WorkerLocationModel {
  final int id;
  final String name;
  final String position;
  final String phone;
  final String avatarUrl;
  final LatLng location;
  final WorkerStatus status;
  final int batteryLevel;
  final String currentTask;
  final String branchName;
  final String movementStatus;
  final String lastUpdated;
  final bool isLocationRequested;
  final String? requestDuration;
  final DateTime? requestedAt;

  const WorkerLocationModel({
    required this.id,
    required this.name,
    required this.position,
    required this.phone,
    required this.avatarUrl,
    required this.location,
    required this.status,
    required this.batteryLevel,
    required this.currentTask,
    required this.branchName,
    required this.movementStatus,
    required this.lastUpdated,
    this.isLocationRequested = false,
    this.requestDuration,
    this.requestedAt,
  });

  WorkerLocationModel copyWith({
    WorkerStatus? status,
    String? lastUpdated,
    bool? isLocationRequested,
    String? requestDuration,
    DateTime? requestedAt,
  }) {
    return WorkerLocationModel(
      id: id,
      name: name,
      position: position,
      phone: phone,
      avatarUrl: avatarUrl,
      location: location,
      status: status ?? this.status,
      batteryLevel: batteryLevel,
      currentTask: currentTask,
      branchName: branchName,
      movementStatus: movementStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLocationRequested: isLocationRequested ?? this.isLocationRequested,
      requestDuration: requestDuration ?? this.requestDuration,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  static List<WorkerLocationModel> getInitialWorkers() {
    final portraits = [
      "https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=160&h=160&q=85",
      "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=160&h=160&q=85",
      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=160&h=160&q=85",
      "https://images.unsplash.com/photo-1705645930353-0e335311ef20?auto=format&fit=crop&w=160&h=160&q=85",
    ];

    return [
      WorkerLocationModel(
        id: 1,
        name: "Mohamed Ali",
        position: "Maintenance Technician",
        phone: "+20 100 123 4567",
        avatarUrl: portraits[0],
        location: const LatLng(30.0444, 31.2357),
        status: WorkerStatus.live,
        batteryLevel: 88,
        currentTask: "AC System Repair at Main Branch",
        branchName: "Main Cairo Branch",
        movementStatus: "Moving • 15 km/h",
        lastUpdated: "Just now",
      ),
      WorkerLocationModel(
        id: 2,
        name: "Ahmed Hassan",
        position: "Maintenance Worker",
        phone: "+20 111 987 6543",
        avatarUrl: portraits[1],
        location: const LatLng(30.0131, 31.2089),
        status: WorkerStatus.offline,
        batteryLevel: 74,
        currentTask: "Generator Inspection & Testing",
        branchName: "Giza Square Branch",
        movementStatus: "Not sharing",
        lastUpdated: "Not sharing",
      ),
      WorkerLocationModel(
        id: 3,
        name: "Omar Khaled",
        position: "Field Technician",
        phone: "+20 122 456 7890",
        avatarUrl: portraits[2],
        location: const LatLng(30.0626, 31.2497),
        status: WorkerStatus.pending,
        batteryLevel: 45,
        currentTask: "On Break / Awaiting Ticket Assignment",
        branchName: "Heliopolis Branch",
        movementStatus: "Idle",
        lastUpdated: "Sent 4 min ago",
      ),
      WorkerLocationModel(
        id: 4,
        name: "Youssef Nabil",
        position: "Operations Specialist",
        phone: "+20 106 333 2211",
        avatarUrl: portraits[3],
        location: const LatLng(29.9602, 31.2569),
        status: WorkerStatus.live,
        batteryLevel: 92,
        currentTask: "Water Leak Repair in Vault",
        branchName: "Maadi Branch",
        movementStatus: "Moving • 8 km/h",
        lastUpdated: "1 min ago",
      ),
    ];
  }
}
