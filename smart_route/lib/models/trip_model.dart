import 'package:flutter/material.dart';
import 'package:smart_route/core/utills/helpers.dart';
import '../core/constants/app_constants.dart';
import 'location_model.dart';
import 'place_model.dart';
import 'route_model.dart';

class TripModel {
  final String id;
  final String? tripName;
  final PlaceModel? origin;
  final PlaceModel? destination;
  final LocationModel? startLocation;
  final LocationModel? endLocation;
  final double distance; // in kilometers
  final double duration; // in minutes
  final double? averageSpeed; // in km/h
  final double? maxSpeed; // in km/h
  final double? fuelConsumed; // in liters
  final double? fuelCost;
  final double? tollCost;
  final double? totalCost;
  final TripStatus status;
  final TripType type;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final List<TripWaypoint> waypoints;
  final Map<String, dynamic>? metadata;
  final String? userId;

  TripModel({
    String? id,
    this.tripName,
    this.origin,
    this.destination,
    this.startLocation,
    this.endLocation,
    required this.distance,
    required this.duration,
    this.averageSpeed,
    this.maxSpeed,
    this.fuelConsumed,
    this.fuelCost,
    this.tollCost,
    this.totalCost,
    this.status = TripStatus.completed,
    this.type = TripType.driving,
    required this.startTime,
    this.endTime,
    DateTime? createdAt,
    this.updatedAt,
    this.notes,
    this.waypoints = const [],
    this.metadata,
    this.userId,
  }) : id = id ?? Helpers.generateId(),
       createdAt = createdAt ?? DateTime.now();

  // ============ FACTORY CONSTRUCTORS ============

  /// Create from a completed route
  factory TripModel.fromRoute(
    RouteModel route, {
    required DateTime startTime,
    DateTime? endTime,
    double? averageSpeed,
    double? maxSpeed,
    double? fuelConsumed,
    double? fuelCost,
    double? tollCost,
    String? notes,
    String? userId,
  }) {
    return TripModel(
      tripName:
          route.name ?? 'Trip to ${route.destination?.name ?? 'Destination'}',
      origin: route.origin,
      destination: route.destination,
      startLocation: route.startLocation,
      endLocation: route.endLocation,
      distance: route.distance,
      duration: route.duration,
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
      fuelConsumed: fuelConsumed,
      fuelCost: fuelCost,
      tollCost: tollCost,
      totalCost: (fuelCost ?? 0) + (tollCost ?? 0),
      status: TripStatus.completed,
      type: _getTripType(route.type),
      startTime: startTime,
      endTime: endTime ?? DateTime.now(),
      notes: notes,
      userId: userId,
      metadata: {
        'route_id': route.id,
        'route_type': route.type.toString(),
        'traffic_delay': route.trafficDelay,
      },
    );
  }

  /// Create from JSON (Supabase)
  factory TripModel.fromJson(Map<String, dynamic> json) {
    final waypoints =
        (json['waypoints'] as List?)?.map((wp) {
          return TripWaypoint.fromJson(wp);
        }).toList() ??
        [];

    return TripModel(
      id: json['id'] ?? Helpers.generateId(),
      tripName: json['trip_name'] ?? json['name'],
      origin: json['origin'] != null
          ? PlaceModel.fromJson(json['origin'])
          : null,
      destination: json['destination'] != null
          ? PlaceModel.fromJson(json['destination'])
          : null,
      startLocation: json['start_location'] != null
          ? LocationModel.fromJson(json['start_location'])
          : null,
      endLocation: json['end_location'] != null
          ? LocationModel.fromJson(json['end_location'])
          : null,
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      averageSpeed: json['average_speed']?.toDouble(),
      maxSpeed: json['max_speed']?.toDouble(),
      fuelConsumed: json['fuel_consumed']?.toDouble(),
      fuelCost: json['fuel_cost']?.toDouble(),
      tollCost: json['toll_cost']?.toDouble(),
      totalCost: json['total_cost']?.toDouble(),
      status: TripStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TripStatus.completed,
      ),
      type: TripType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TripType.driving,
      ),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      notes: json['notes'],
      waypoints: waypoints,
      metadata: json['metadata'],
      userId: json['user_id'],
    );
  }

  /// Create from Hive map
  factory TripModel.fromHiveMap(Map<String, dynamic> map) {
    final waypoints =
        (map['waypoints'] as List?)?.map((wp) {
          return TripWaypoint.fromJson(wp);
        }).toList() ??
        [];

    return TripModel(
      id: map['id'] ?? Helpers.generateId(),
      tripName: map['tripName'] ?? map['name'],
      origin: map['origin'] != null
          ? PlaceModel.fromHiveMap(map['origin'])
          : null,
      destination: map['destination'] != null
          ? PlaceModel.fromHiveMap(map['destination'])
          : null,
      startLocation: map['startLocation'] != null
          ? LocationModel.fromJson(map['startLocation'])
          : null,
      endLocation: map['endLocation'] != null
          ? LocationModel.fromJson(map['endLocation'])
          : null,
      distance: (map['distance'] ?? 0).toDouble(),
      duration: (map['duration'] ?? 0).toDouble(),
      averageSpeed: map['averageSpeed']?.toDouble(),
      maxSpeed: map['maxSpeed']?.toDouble(),
      fuelConsumed: map['fuelConsumed']?.toDouble(),
      fuelCost: map['fuelCost']?.toDouble(),
      tollCost: map['tollCost']?.toDouble(),
      totalCost: map['totalCost']?.toDouble(),
      status: TripStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => TripStatus.completed,
      ),
      type: TripType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => TripType.driving,
      ),
      startTime: map['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startTime'])
          : DateTime.now(),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      notes: map['notes'],
      waypoints: waypoints,
      metadata: map['metadata'],
      userId: map['userId'],
    );
  }

  /// Create for current trip in progress
  factory TripModel.currentTrip({
    required PlaceModel origin,
    required PlaceModel destination,
    required double distance,
    required double duration,
    TripType type = TripType.driving,
    String? userId,
  }) {
    return TripModel(
      origin: origin,
      destination: destination,
      distance: distance,
      duration: duration,
      status: TripStatus.inProgress,
      type: type,
      startTime: DateTime.now(),
      userId: userId,
    );
  }

  // ============ CONVERSION METHODS ============

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_name': tripName,
      'origin': origin?.toJson(),
      'destination': destination?.toJson(),
      'start_location': startLocation?.toJson(),
      'end_location': endLocation?.toJson(),
      'distance': distance,
      'duration': duration,
      'average_speed': averageSpeed,
      'max_speed': maxSpeed,
      'fuel_consumed': fuelConsumed,
      'fuel_cost': fuelCost,
      'toll_cost': tollCost,
      'total_cost': totalCost,
      'status': status.toString(),
      'type': type.toString(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'notes': notes,
      'waypoints': waypoints.map((wp) => wp.toJson()).toList(),
      'metadata': metadata,
      'user_id': userId,
    };
  }

  /// Convert to Hive map
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'tripName': tripName,
      'origin': origin?.toHiveMap(),
      'destination': destination?.toHiveMap(),
      'startLocation': startLocation?.toJson(),
      'endLocation': endLocation?.toJson(),
      'distance': distance,
      'duration': duration,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'fuelConsumed': fuelConsumed,
      'fuelCost': fuelCost,
      'tollCost': tollCost,
      'totalCost': totalCost,
      'status': status.toString(),
      'type': type.toString(),
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'notes': notes,
      'waypoints': waypoints.map((wp) => wp.toJson()).toList(),
      'metadata': metadata,
      'userId': userId,
    };
  }

  // ============ STATUS METHODS ============

  /// Complete the trip
  TripModel completeTrip({
    LocationModel? endLocation,
    DateTime? endTime,
    double? averageSpeed,
    double? maxSpeed,
    double? fuelConsumed,
    double? fuelCost,
    double? tollCost,
  }) {
    final now = DateTime.now();
    return copyWith(
      status: TripStatus.completed,
      endLocation: endLocation ?? endLocation,
      endTime: endTime ?? now,
      averageSpeed: averageSpeed ?? averageSpeed,
      maxSpeed: maxSpeed ?? maxSpeed,
      fuelConsumed: fuelConsumed ?? fuelConsumed,
      fuelCost: fuelCost ?? fuelCost,
      tollCost: tollCost ?? tollCost,
      totalCost: (fuelCost ?? 0) + (tollCost ?? 0),
      updatedAt: now,
    );
  }

  /// Cancel the trip
  TripModel cancelTrip({String? reason}) {
    return copyWith(
      status: TripStatus.cancelled,
      endTime: DateTime.now(),
      notes: reason != null ? '$notes\nCancelled: $reason' : notes,
      updatedAt: DateTime.now(),
    );
  }

  /// Add waypoint to trip
  TripModel addWaypoint(TripWaypoint waypoint) {
    final newWaypoints = List<TripWaypoint>.from(waypoints)..add(waypoint);
    return copyWith(waypoints: newWaypoints, updatedAt: DateTime.now());
  }

  /// Remove waypoint from trip
  TripModel removeWaypoint(String waypointId) {
    final newWaypoints = List<TripWaypoint>.from(waypoints)
      ..removeWhere((wp) => wp.id == waypointId);
    return copyWith(waypoints: newWaypoints, updatedAt: DateTime.now());
  }

  // ============ COPY METHOD ============

  TripModel copyWith({
    String? id,
    String? tripName,
    PlaceModel? origin,
    PlaceModel? destination,
    LocationModel? startLocation,
    LocationModel? endLocation,
    double? distance,
    double? duration,
    double? averageSpeed,
    double? maxSpeed,
    double? fuelConsumed,
    double? fuelCost,
    double? tollCost,
    double? totalCost,
    TripStatus? status,
    TripType? type,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    List<TripWaypoint>? waypoints,
    Map<String, dynamic>? metadata,
    String? userId,
  }) {
    return TripModel(
      id: id ?? this.id,
      tripName: tripName ?? this.tripName,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      fuelConsumed: fuelConsumed ?? this.fuelConsumed,
      fuelCost: fuelCost ?? this.fuelCost,
      tollCost: tollCost ?? this.tollCost,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      waypoints: waypoints ?? this.waypoints,
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
    );
  }

  // ============ GETTERS ============

  /// Get trip duration in hours
  double get durationInHours => duration / 60;

  /// Get formatted distance
  String get formattedDistance {
    return AppConstants.formatDistance(distance);
  }

  /// Get formatted duration
  String get formattedDuration {
    return AppConstants.formatDuration(duration);
  }

  /// Get formatted average speed
  String? get formattedAverageSpeed {
    if (averageSpeed == null) return null;
    return '${averageSpeed!.toStringAsFixed(1)} km/h';
  }

  /// Get formatted max speed
  String? get formattedMaxSpeed {
    if (maxSpeed == null) return null;
    return '${maxSpeed!.toStringAsFixed(1)} km/h';
  }

  /// Get formatted fuel cost
  String? get formattedFuelCost {
    if (fuelCost == null) return null;
    return '\$${fuelCost!.toStringAsFixed(2)}';
  }

  /// Get formatted toll cost
  String? get formattedTollCost {
    if (tollCost == null) return null;
    return '\$${tollCost!.toStringAsFixed(2)}';
  }

  /// Get formatted total cost
  String? get formattedTotalCost {
    if (totalCost == null) return null;
    return '\$${totalCost!.toStringAsFixed(2)}';
  }

  /// Get trip duration string
  String get durationString {
    final hours = durationInHours.floor();
    final minutes = (duration % 60).round();
    if (hours > 0) {
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    }
    return '$minutes min';
  }

  /// Get origin name
  String get originName {
    if (origin != null) return origin!.name;
    if (startLocation != null) return startLocation!.address ?? 'Start';
    return 'Unknown Origin';
  }

  /// Get destination name
  String get destinationName {
    if (destination != null) return destination!.name;
    if (endLocation != null) return endLocation!.address ?? 'Destination';
    return 'Unknown Destination';
  }

  /// Check if trip is completed
  bool get isCompleted => status == TripStatus.completed;

  /// Check if trip is in progress
  bool get isInProgress => status == TripStatus.inProgress;

  /// Check if trip is cancelled
  bool get isCancelled => status == TripStatus.cancelled;

  /// Get time ago string
  String get timeAgo {
    return Helpers.timeAgo(createdAt);
  }

  /// Get trip date
  String get tripDate {
    return Helpers.formatDate(startTime);
  }

  /// Get trip time
  String get tripTime {
    return Helpers.formatTime(startTime);
  }

  /// Get trip duration in seconds
  int get durationInSeconds => (duration * 60).round();

  /// Get fuel efficiency (km per liter)
  double? get fuelEfficiency {
    if (fuelConsumed == null || fuelConsumed == 0) return null;
    return distance / fuelConsumed!;
  }

  /// Get formatted fuel efficiency
  String? get formattedFuelEfficiency {
    final efficiency = fuelEfficiency;
    if (efficiency == null) return null;
    return '${efficiency.toStringAsFixed(1)} km/L';
  }

  /// Get cost per kilometer
  double? get costPerKm {
    if (totalCost == null || distance == 0) return null;
    return totalCost! / distance;
  }

  /// Get formatted cost per kilometer
  String? get formattedCostPerKm {
    final cost = costPerKm;
    if (cost == null) return null;
    return '\$${cost.toStringAsFixed(2)}/km';
  }

  /// Get waypoint count
  int get waypointCount => waypoints.length;

  /// Check if trip has waypoints
  bool get hasWaypoints => waypoints.isNotEmpty;

  /// Check if trip has notes
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  /// Get trip type display name
  String get typeDisplayName {
    switch (type) {
      case TripType.driving:
        return 'Driving';
      case TripType.walking:
        return 'Walking';
      case TripType.cycling:
        return 'Cycling';
      case TripType.transit:
        return 'Transit';
    }
  }

  /// Get trip icon
  IconData get icon {
    switch (type) {
      case TripType.driving:
        return Icons.directions_car;
      case TripType.walking:
        return Icons.directions_walk;
      case TripType.cycling:
        return Icons.directions_bike;
      case TripType.transit:
        return Icons.directions_transit;
    }
  }

  /// Get status icon
  IconData get statusIcon {
    switch (status) {
      case TripStatus.completed:
        return Icons.check_circle;
      case TripStatus.inProgress:
        return Icons.route;
      case TripStatus.cancelled:
        return Icons.cancel;
      case TripStatus.failed:
        return Icons.error;
    }
  }

  /// Get status color
  Color get statusColor {
    switch (status) {
      case TripStatus.completed:
        return Colors.green;
      case TripStatus.inProgress:
        return Colors.blue;
      case TripStatus.cancelled:
        return Colors.orange;
      case TripStatus.failed:
        return Colors.red;
    }
  }

  /// Get type color
  Color get typeColor {
    switch (type) {
      case TripType.driving:
        return Colors.blue;
      case TripType.walking:
        return Colors.green;
      case TripType.cycling:
        return Colors.orange;
      case TripType.transit:
        return Colors.purple;
    }
  }

  // ============ EQUALITY ============

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ============ HELPER METHODS ============

  static TripType _getTripType(RouteType routeType) {
    switch (routeType) {
      case RouteType.driving:
        return TripType.driving;
      case RouteType.walking:
        return TripType.walking;
      case RouteType.cycling:
        return TripType.cycling;
      case RouteType.transit:
        return TripType.transit;
    }
  }
}

// ============ TRIP WAYPOINT MODEL ============

class TripWaypoint {
  final String id;
  final String? name;
  final double latitude;
  final double longitude;
  final String? address;
  final int order;
  final DateTime arrivalTime;
  final DateTime? departureTime;
  final Duration? stopDuration;
  final String? notes;
  final bool isVisited;

  TripWaypoint({
    String? id,
    this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.order,
    required this.arrivalTime,
    this.departureTime,
    this.stopDuration,
    this.notes,
    this.isVisited = false,
  }) : id = id ?? Helpers.generateId();

  factory TripWaypoint.fromJson(Map<String, dynamic> json) {
    return TripWaypoint(
      id: json['id'] ?? Helpers.generateId(),
      name: json['name'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      order: json['order'] ?? 0,
      arrivalTime: json['arrival_time'] != null
          ? DateTime.parse(json['arrival_time'])
          : DateTime.now(),
      departureTime: json['departure_time'] != null
          ? DateTime.parse(json['departure_time'])
          : null,
      stopDuration: json['stop_duration'] != null
          ? Duration(seconds: json['stop_duration'])
          : null,
      notes: json['notes'],
      isVisited: json['is_visited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'order': order,
      'arrival_time': arrivalTime.toIso8601String(),
      'departure_time': departureTime?.toIso8601String(),
      'stop_duration': stopDuration?.inSeconds,
      'notes': notes,
      'is_visited': isVisited,
    };
  }

  TripWaypoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    int? order,
    DateTime? arrivalTime,
    DateTime? departureTime,
    Duration? stopDuration,
    String? notes,
    bool? isVisited,
  }) {
    return TripWaypoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      order: order ?? this.order,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      stopDuration: stopDuration ?? this.stopDuration,
      notes: notes ?? this.notes,
      isVisited: isVisited ?? this.isVisited,
    );
  }

  /// Mark waypoint as visited
  TripWaypoint markVisited() {
    return copyWith(isVisited: true, departureTime: DateTime.now());
  }

  /// Get formatted arrival time
  String get formattedArrivalTime => Helpers.formatTime(arrivalTime);

  /// Get formatted departure time
  String? get formattedDepartureTime {
    if (departureTime == null) return null;
    return Helpers.formatTime(departureTime!);
  }

  /// Get stop duration string
  String? get stopDurationString {
    if (stopDuration == null) return null;
    final minutes = stopDuration!.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours h ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
  }

  /// Get location string
  String get locationString => '$latitude,$longitude';
}

// ============ ENUMS ============

enum TripStatus { completed, inProgress, cancelled, failed }

enum TripType { driving, walking, cycling, transit }

// ============ TRIP STATISTICS ============

class TripStatistics {
  final int totalTrips;
  final double totalDistance;
  final double totalDuration;
  final double averageDistance;
  final double averageDuration;
  final double? averageSpeed;
  final double? maxSpeed;
  final double? totalFuelConsumed;
  final double? totalFuelCost;
  final double? totalTollCost;
  final double? totalCost;
  final Map<TripType, int> tripsByType;
  final Map<TripStatus, int> tripsByStatus;
  final DateTime fromDate;
  final DateTime toDate;

  TripStatistics({
    required this.totalTrips,
    required this.totalDistance,
    required this.totalDuration,
    required this.averageDistance,
    required this.averageDuration,
    this.averageSpeed,
    this.maxSpeed,
    this.totalFuelConsumed,
    this.totalFuelCost,
    this.totalTollCost,
    this.totalCost,
    required this.tripsByType,
    required this.tripsByStatus,
    required this.fromDate,
    required this.toDate,
  });

  factory TripStatistics.fromTrips(List<TripModel> trips) {
    if (trips.isEmpty) {
      return TripStatistics(
        totalTrips: 0,
        totalDistance: 0,
        totalDuration: 0,
        averageDistance: 0,
        averageDuration: 0,
        tripsByType: {},
        tripsByStatus: {},
        fromDate: DateTime.now(),
        toDate: DateTime.now(),
      );
    }

    final totalTrips = trips.length;
    final totalDistance = trips.fold(0.0, (sum, trip) => sum + trip.distance);
    final totalDuration = trips.fold(0.0, (sum, trip) => sum + trip.duration);
    final averageDistance = totalDistance / totalTrips;
    final averageDuration = totalDuration / totalTrips;

    // Calculate speeds
    final completedTrips = trips.where((t) => t.status == TripStatus.completed);
    double? averageSpeed;
    double? maxSpeed;
    if (completedTrips.isNotEmpty) {
      final speeds = completedTrips
          .map((t) => t.averageSpeed)
          .where((s) => s != null)
          .cast<double>()
          .toList();
      if (speeds.isNotEmpty) {
        averageSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
        maxSpeed = speeds.reduce((a, b) => a > b ? a : b);
      }
    }

    // Calculate fuel and costs
    final totalFuelConsumed = trips
        .map((t) => t.fuelConsumed)
        .where((f) => f != null)
        .cast<double>()
        .fold(0.0, (sum, f) => sum + f);

    final totalFuelCost = trips
        .map((t) => t.fuelCost)
        .where((c) => c != null)
        .cast<double>()
        .fold(0.0, (sum, c) => sum + c);

    final totalTollCost = trips
        .map((t) => t.tollCost)
        .where((c) => c != null)
        .cast<double>()
        .fold(0.0, (sum, c) => sum + c);

    final totalCost = trips
        .map((t) => t.totalCost)
        .where((c) => c != null)
        .cast<double>()
        .fold(0.0, (sum, c) => sum + c);

    // Group by type
    final tripsByType = <TripType, int>{};
    for (final type in TripType.values) {
      final count = trips.where((t) => t.type == type).length;
      if (count > 0) tripsByType[type] = count;
    }

    // Group by status
    final tripsByStatus = <TripStatus, int>{};
    for (final status in TripStatus.values) {
      final count = trips.where((t) => t.status == status).length;
      if (count > 0) tripsByStatus[status] = count;
    }

    // Get date range
    final dates = trips.map((t) => t.startTime).toList();
    final fromDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final toDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);

    return TripStatistics(
      totalTrips: totalTrips,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      averageDistance: averageDistance,
      averageDuration: averageDuration,
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
      totalFuelConsumed: totalFuelConsumed > 0 ? totalFuelConsumed : null,
      totalFuelCost: totalFuelCost > 0 ? totalFuelCost : null,
      totalTollCost: totalTollCost > 0 ? totalTollCost : null,
      totalCost: totalCost > 0 ? totalCost : null,
      tripsByType: tripsByType,
      tripsByStatus: tripsByStatus,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  /// Get formatted statistics for display
  Map<String, String> get formattedStats {
    return {
      'Total Trips': totalTrips.toString(),
      'Total Distance': AppConstants.formatDistance(totalDistance),
      'Total Duration': AppConstants.formatDuration(totalDuration),
      'Average Distance': AppConstants.formatDistance(averageDistance),
      'Average Duration': AppConstants.formatDuration(averageDuration),
      'Average Speed': averageSpeed != null
          ? '${averageSpeed!.toStringAsFixed(1)} km/h'
          : 'N/A',
      'Max Speed': maxSpeed != null
          ? '${maxSpeed!.toStringAsFixed(1)} km/h'
          : 'N/A',
      'Fuel Consumed': totalFuelConsumed != null
          ? '${totalFuelConsumed!.toStringAsFixed(1)} L'
          : 'N/A',
      'Fuel Cost': totalFuelCost != null
          ? '\$${totalFuelCost!.toStringAsFixed(2)}'
          : 'N/A',
      'Toll Cost': totalTollCost != null
          ? '\$${totalTollCost!.toStringAsFixed(2)}'
          : 'N/A',
      'Total Cost': totalCost != null
          ? '\$${totalCost!.toStringAsFixed(2)}'
          : 'N/A',
    };
  }
}

// ============ TRIP COLLECTION ============

class TripCollection {
  final List<TripModel> trips;
  final String? userId;

  const TripCollection({required this.trips, this.userId});

  // Filter by status
  List<TripModel> getByStatus(TripStatus status) {
    return trips.where((trip) => trip.status == status).toList();
  }

  // Filter by type
  List<TripModel> getByType(TripType type) {
    return trips.where((trip) => trip.type == type).toList();
  }

  // Filter by date range
  List<TripModel> getByDateRange(DateTime from, DateTime to) {
    return trips
        .where(
          (trip) => trip.startTime.isAfter(from) && trip.startTime.isBefore(to),
        )
        .toList();
  }

  // Get today's trips
  List<TripModel> getTodayTrips() {
    final today = DateTime.now();
    return trips
        .where(
          (trip) =>
              trip.startTime.year == today.year &&
              trip.startTime.month == today.month &&
              trip.startTime.day == today.day,
        )
        .toList();
  }

  // Get this week's trips
  List<TripModel> getWeekTrips() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return trips.where((trip) => trip.startTime.isAfter(weekAgo)).toList();
  }

  // Get this month's trips
  List<TripModel> getMonthTrips() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return trips.where((trip) => trip.startTime.isAfter(monthAgo)).toList();
  }

  // Sort by date
  List<TripModel> sortByDate({bool ascending = false}) {
    final sorted = List<TripModel>.from(trips);
    sorted.sort(
      (a, b) => ascending
          ? a.startTime.compareTo(b.startTime)
          : b.startTime.compareTo(a.startTime),
    );
    return sorted;
  }

  // Sort by distance
  List<TripModel> sortByDistance({bool ascending = true}) {
    final sorted = List<TripModel>.from(trips);
    sorted.sort(
      (a, b) => ascending
          ? a.distance.compareTo(b.distance)
          : b.distance.compareTo(a.distance),
    );
    return sorted;
  }

  // Sort by duration
  List<TripModel> sortByDuration({bool ascending = true}) {
    final sorted = List<TripModel>.from(trips);
    sorted.sort(
      (a, b) => ascending
          ? a.duration.compareTo(b.duration)
          : b.duration.compareTo(a.duration),
    );
    return sorted;
  }

  // Get statistics
  TripStatistics getStatistics() {
    return TripStatistics.fromTrips(trips);
  }

  // Get total distance
  double get totalDistance {
    return trips.fold(0.0, (sum, trip) => sum + trip.distance);
  }

  // Get total duration
  double get totalDuration {
    return trips.fold(0.0, (sum, trip) => sum + trip.duration);
  }

  // Get total fuel cost
  double? get totalFuelCost {
    final costs = trips
        .map((t) => t.fuelCost)
        .where((c) => c != null)
        .cast<double>()
        .toList();
    if (costs.isEmpty) return null;
    return costs.fold(0.0, (sum, c) => sum! + c); // Add ! to c
  }

  // Get total toll cost
  double? get totalTollCost {
    final costs = trips
        .map((t) => t.tollCost)
        .where((c) => c != null)
        .cast<double>()
        .toList();
    if (costs.isEmpty) return null;
    return costs.fold(0.0, (sum, c) => sum! + c);
  }

  // Get total cost
  double? get totalCost {
    final costs = trips
        .map((t) => t.totalCost)
        .where((c) => c != null)
        .cast<double>()
        .toList();
    if (costs.isEmpty) return null;
    return costs.fold(0.0, (sum, c) => sum! + c);
  }

  // Get trip by id
  TripModel? getById(String id) {
    try {
      return trips.firstWhere((trip) => trip.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get completed trips
  List<TripModel> get completedTrips {
    return getByStatus(TripStatus.completed);
  }

  // Get in progress trips
  List<TripModel> get inProgressTrips {
    return getByStatus(TripStatus.inProgress);
  }

  // Get cancelled trips
  List<TripModel> get cancelledTrips {
    return getByStatus(TripStatus.cancelled);
  }

  // Get failed trips
  List<TripModel> get failedTrips {
    return getByStatus(TripStatus.failed);
  }

  // Get driving trips
  List<TripModel> get drivingTrips {
    return getByType(TripType.driving);
  }

  // Get walking trips
  List<TripModel> get walkingTrips {
    return getByType(TripType.walking);
  }

  // Get cycling trips
  List<TripModel> get cyclingTrips {
    return getByType(TripType.cycling);
  }

  // Get transit trips
  List<TripModel> get transitTrips {
    return getByType(TripType.transit);
  }
}
