import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:smart_route/core/utills/helpers.dart';
import '../core/constants/app_constants.dart';
import 'location_model.dart';
import 'place_model.dart';

class RouteModel {
  final String id;
  final String? name;
  final List<LatLng> points;
  final PlaceModel? origin;
  final PlaceModel? destination;
  final LocationModel? startLocation;
  final LocationModel? endLocation;
  final double distance; // in kilometers
  final double duration; // in minutes
  final double? trafficDelay; // in minutes
  final double? tollCost;
  final double? estimatedFuelCost;
  final List<RouteStep> steps;
  final RouteType type;
  final RouteStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;
  final String? userId;

  // Computed properties
  Polyline? _cachedPolyline;

  RouteModel({
    String? id,
    this.name,
    required this.points,
    this.origin,
    this.destination,
    this.startLocation,
    this.endLocation,
    required this.distance,
    required this.duration,
    this.trafficDelay,
    this.tollCost,
    this.estimatedFuelCost,
    this.steps = const [],
    this.type = RouteType.driving,
    this.status = RouteStatus.pending,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.metadata,
    this.userId,
  }) : id = id ?? Helpers.generateId(),
       createdAt = createdAt ?? DateTime.now();

  // ============ FACTORY CONSTRUCTORS ============

  /// Create from OSRM route response
  factory RouteModel.fromOSRM({
    required Map<String, dynamic> response,
    PlaceModel? origin,
    PlaceModel? destination,
    RouteType type = RouteType.driving,
    String? userId,
  }) {
    final routes = response['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes.first;
    final geometry = route['geometry'];
    final distance = (route['distance'] ?? 0) / 1000; // Convert to km
    final duration = (route['duration'] ?? 0) / 60; // Convert to minutes

    // Parse points
    List<LatLng> points = [];
    if (geometry != null) {
      if (geometry is String) {
        // Polyline encoded string - would need decoding
        // For simplicity, we'll handle this with a polyline decoder
        // You can use polyline_plus package for encoding/decoding
        points = _decodePolyline(geometry);
      } else if (geometry is Map && geometry.containsKey('coordinates')) {
        final coords = geometry['coordinates'] as List;
        points = coords.map((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList();
      }
    }

    // Parse steps
    List<RouteStep> steps = [];
    final legs = route['legs'] as List?;
    if (legs != null && legs.isNotEmpty) {
      final leg = legs.first;
      final legSteps = leg['steps'] as List?;
      if (legSteps != null) {
        steps = legSteps.map((step) {
          final stepPoints = step['geometry'] != null
              ? _decodePolyline(step['geometry'])
              : [];
          return RouteStep(
            instruction: step['maneuver']?['instruction'] ?? 'Continue',
            distance: (step['distance'] ?? 0) / 1000,
            duration: (step['duration'] ?? 0) / 60,
            points: stepPoints.cast<LatLng>(), // Cast to List<LatLng>
            type: _getStepType(step['maneuver']?['type'] ?? ''),
            street: step['name'],
            exitNumber: step['maneuver']?['exit'],
          );
        }).toList();
      }
    }

    return RouteModel(
      points: points,
      origin: origin,
      destination: destination,
      distance: distance,
      duration: duration,
      trafficDelay:
          route['duration'] != null && route['duration_typical'] != null
          ? ((route['duration_typical'] - route['duration']) / 60)
          : null,
      steps: steps,
      type: type,
      status: RouteStatus.pending,
      userId: userId,
      metadata: {
        'osrm_response': response,
        'weight': route['weight'],
        'weight_name': route['weight_name'],
      },
    );
  }

  /// Create from MapBox route response
  factory RouteModel.fromMapBox({
    required Map<String, dynamic> response,
    PlaceModel? origin,
    PlaceModel? destination,
    RouteType type = RouteType.driving,
    String? userId,
  }) {
    final routes = response['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes.first;
    final distance = (route['distance'] ?? 0) / 1000;
    final duration = (route['duration'] ?? 0) / 60;

    // Parse geometry
    final geometry = route['geometry'] as String?;
    List<LatLng> points = [];
    if (geometry != null) {
      // Decode polyline
      points = _decodePolyline(geometry);
    }

    // Parse steps
    List<RouteStep> steps = [];
    final legs = route['legs'] as List?;
    if (legs != null && legs.isNotEmpty) {
      final leg = legs.first;
      final legSteps = leg['steps'] as List?;
      if (legSteps != null) {
        steps = legSteps.map((step) {
          final stepGeometry = step['geometry'] as String?;
          final stepPoints = stepGeometry != null
              ? _decodePolyline(stepGeometry)
              : [];
          return RouteStep(
            instruction:
                step['maneuver']?['instruction'] ?? step['name'] ?? 'Continue',
            distance: (step['distance'] ?? 0) / 1000,
            duration: (step['duration'] ?? 0) / 60,
            points: stepPoints.cast<LatLng>(), // <-- Add .cast<LatLng>()
            type: _getStepType(step['maneuver']?['type'] ?? ''),
            street: step['name'],
            exitNumber: step['maneuver']?['exit'],
          );
        }).toList();
      }
    }

    return RouteModel(
      points: points,
      origin: origin,
      destination: destination,
      distance: distance,
      duration: duration,
      trafficDelay:
          route['duration'] != null && route['duration_typical'] != null
          ? ((route['duration_typical'] - route['duration']) / 60)
          : null,
      steps: steps,
      type: type,
      status: RouteStatus.pending,
      userId: userId,
      metadata: {
        'mapbox_response': response,
        'weight': route['weight'],
        'weight_name': route['weight_name'],
      },
    );
  }

  /// Create from Google Maps route response
  factory RouteModel.fromGoogle({
    required Map<String, dynamic> response,
    PlaceModel? origin,
    PlaceModel? destination,
    RouteType type = RouteType.driving,
    String? userId,
  }) {
    final routes = response['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes.first;
    final overviewPolyline = route['overview_polyline']?['points'] as String?;

    List<LatLng> points = [];
    if (overviewPolyline != null) {
      points = _decodePolyline(overviewPolyline);
    }

    final leg = route['legs']?.first;
    final distance = (leg?['distance']?['value'] ?? 0) / 1000;
    final duration = (leg?['duration']?['value'] ?? 0) / 60;

    // Parse steps
    List<RouteStep> steps = [];
    final legSteps = leg?['steps'] as List?;
    if (legSteps != null) {
      steps = legSteps.map((step) {
        final stepPoints = _decodePolyline(step['polyline']?['points'] ?? '');
        return RouteStep(
          instruction: step['html_instructions'] ?? 'Continue',
          distance: (step['distance']?['value'] ?? 0) / 1000,
          duration: (step['duration']?['value'] ?? 0) / 60,
          points: stepPoints,
          type: _getStepType(step['travel_mode'] ?? ''),
          street: step['maneuver']?['street_name'],
          exitNumber: step['maneuver']?['exit'],
        );
      }).toList();
    }

    return RouteModel(
      points: points,
      origin: origin,
      destination: destination,
      distance: distance,
      duration: duration,
      trafficDelay: leg?['duration_in_traffic'] != null
          ? ((leg['duration_in_traffic']['value'] - leg['duration']['value']) /
                60)
          : null,
      steps: steps,
      type: type,
      status: RouteStatus.pending,
      userId: userId,
      metadata: {
        'google_response': response,
        'waypoints': route['waypoint_order'],
      },
    );
  }

  /// Create from JSON (Supabase)
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final points =
        (json['points'] as List?)?.map((point) {
          return LatLng(point['lat'] ?? 0, point['lng'] ?? 0);
        }).toList() ??
        [];

    final steps =
        (json['steps'] as List?)?.map((step) {
          return RouteStep.fromJson(step);
        }).toList() ??
        [];

    return RouteModel(
      id: json['id'] ?? Helpers.generateId(),
      name: json['name'],
      points: points,
      origin: json['origin'] != null
          ? PlaceModel.fromJson(json['origin'])
          : null,
      destination: json['destination'] != null
          ? PlaceModel.fromJson(json['destination'])
          : null,
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      trafficDelay: json['traffic_delay']?.toDouble(),
      tollCost: json['toll_cost']?.toDouble(),
      estimatedFuelCost: json['estimated_fuel_cost']?.toDouble(),
      steps: steps,
      type: RouteType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => RouteType.driving,
      ),
      status: RouteStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => RouteStatus.pending,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      metadata: json['metadata'],
      userId: json['user_id'],
    );
  }

  // ============ CONVERSION METHODS ============

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'points': points
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'origin': origin?.toJson(),
      'destination': destination?.toJson(),
      'distance': distance,
      'duration': duration,
      'traffic_delay': trafficDelay,
      'toll_cost': tollCost,
      'estimated_fuel_cost': estimatedFuelCost,
      'steps': steps.map((step) => step.toJson()).toList(),
      'type': type.toString(),
      'status': status.toString(),
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
      'user_id': userId,
    };
  }

  /// Convert to Hive map
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'name': name,
      'points': points
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'origin': origin?.toHiveMap(),
      'destination': destination?.toHiveMap(),
      'distance': distance,
      'duration': duration,
      'traffic_delay': trafficDelay,
      'toll_cost': tollCost,
      'estimated_fuel_cost': estimatedFuelCost,
      'steps': steps.map((step) => step.toJson()).toList(),
      'type': type.toString(),
      'status': status.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'metadata': metadata,
      'userId': userId,
    };
  }

  /// Create from Hive map
  factory RouteModel.fromHiveMap(Map<String, dynamic> map) {
    final points =
        (map['points'] as List?)?.map((point) {
          return LatLng(point['lat'] ?? 0, point['lng'] ?? 0);
        }).toList() ??
        [];

    final steps =
        (map['steps'] as List?)?.map((step) {
          return RouteStep.fromJson(step);
        }).toList() ??
        [];

    return RouteModel(
      id: map['id'] ?? Helpers.generateId(),
      name: map['name'],
      points: points,
      origin: map['origin'] != null
          ? PlaceModel.fromHiveMap(map['origin'])
          : null,
      destination: map['destination'] != null
          ? PlaceModel.fromHiveMap(map['destination'])
          : null,
      distance: (map['distance'] ?? 0).toDouble(),
      duration: (map['duration'] ?? 0).toDouble(),
      trafficDelay: map['traffic_delay']?.toDouble(),
      tollCost: map['toll_cost']?.toDouble(),
      estimatedFuelCost: map['estimated_fuel_cost']?.toDouble(),
      steps: steps,
      type: RouteType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => RouteType.driving,
      ),
      status: RouteStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => RouteStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      startedAt: map['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      metadata: map['metadata'],
      userId: map['userId'],
    );
  }

  // ============ POLYLINE DECODING ============

  /// Decode polyline string to list of LatLng points
  static List<LatLng> _decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];

    final List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  /// Encode points to polyline string
  static String _encodePolyline(List<LatLng> points) {
    if (points.isEmpty) return '';

    late int lastLat, lastLng;
    StringBuffer result = StringBuffer();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      int lat = (point.latitude * 1e5).round();
      int lng = (point.longitude * 1e5).round();

      if (i == 0) {
        lastLat = lat;
        lastLng = lng;
        result.write(_encodeNumber(lat));
        result.write(_encodeNumber(lng));
      } else {
        result.write(_encodeNumber(lat - lastLat));
        result.write(_encodeNumber(lng - lastLng));
        lastLat = lat;
        lastLng = lng;
      }
    }

    return result.toString();
  }

  static String _encodeNumber(int num) {
    int n = num < 0 ? ~(num << 1) : (num << 1);
    StringBuffer result = StringBuffer();
    while (n >= 0x20) {
      result.writeCharCode((0x20 | (n & 0x1f)) + 63);
      n >>= 5;
    }
    result.writeCharCode(n + 63);
    return result.toString();
  }

  static RouteStepType _getStepType(String type) {
    switch (type.toLowerCase()) {
      case 'turn':
      case 'turn left':
      case 'turn right':
        return RouteStepType.turn;
      case 'merge':
        return RouteStepType.merge;
      case 'fork':
        return RouteStepType.fork;
      case 'exit':
        return RouteStepType.exit;
      case 'roundabout':
        return RouteStepType.roundabout;
      case 'depart':
        return RouteStepType.depart;
      case 'arrive':
        return RouteStepType.arrive;
      default:
        return RouteStepType.continue_straight;
    }
  }

  // ============ COPY METHODS ============

  RouteModel copyWith({
    String? id,
    String? name,
    List<LatLng>? points,
    PlaceModel? origin,
    PlaceModel? destination,
    LocationModel? startLocation,
    LocationModel? endLocation,
    double? distance,
    double? duration,
    double? trafficDelay,
    double? tollCost,
    double? estimatedFuelCost,
    List<RouteStep>? steps,
    RouteType? type,
    RouteStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    String? userId,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      trafficDelay: trafficDelay ?? this.trafficDelay,
      tollCost: tollCost ?? this.tollCost,
      estimatedFuelCost: estimatedFuelCost ?? this.estimatedFuelCost,
      steps: steps ?? this.steps,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
    );
  }

  // ============ STATUS METHODS ============

  RouteModel startNavigation() {
    return copyWith(status: RouteStatus.inProgress, startedAt: DateTime.now());
  }

  RouteModel completeNavigation() {
    return copyWith(status: RouteStatus.completed, completedAt: DateTime.now());
  }

  RouteModel cancelNavigation() {
    return copyWith(status: RouteStatus.cancelled);
  }

  // ============ GETTERS ============

  /// Get polyline for map display
  Polyline get polyline {
    _cachedPolyline ??= Polyline(
      points: points,
      color: const Color(0xFF2196F3),
      strokeWidth: 5,
      borderStrokeWidth: 1,
      borderColor: Colors.white.withOpacity(0.3),
      isDotted: false,
    );
    return _cachedPolyline!;
  }

  /// Get starting point
  LatLng? get startPoint {
    if (points.isEmpty) return null;
    return points.first;
  }

  /// Get ending point
  LatLng? get endPoint {
    if (points.isEmpty) return null;
    return points.last;
  }

  /// Get estimated arrival time
  DateTime? get estimatedArrival {
    if (status == RouteStatus.inProgress && startedAt != null) {
      return startedAt!.add(Duration(minutes: duration.round()));
    }
    return null;
  }

  /// Get formatted distance
  String get formattedDistance {
    return AppConstants.formatDistance(distance);
  }

  /// Get formatted duration
  String get formattedDuration {
    return AppConstants.formatDuration(duration);
  }

  /// Get formatted arrival time
  String? get formattedArrivalTime {
    final arrival = estimatedArrival;
    if (arrival != null) {
      return Helpers.formatTime(arrival);
    }
    return null;
  }

  /// Get traffic delay formatted
  String? get formattedTrafficDelay {
    if (trafficDelay == null) return null;
    return '${trafficDelay!.toStringAsFixed(0)} min';
  }

  /// Get route summary
  String get summary {
    return '${formattedDistance} • ${formattedDuration}';
  }

  /// Check if route has traffic
  bool get hasTraffic => trafficDelay != null && trafficDelay! > 0;

  /// Get total duration including traffic
  double get totalDuration {
    return duration + (trafficDelay ?? 0);
  }

  /// Get formatted total duration
  String get formattedTotalDuration {
    return AppConstants.formatDuration(totalDuration);
  }

  /// Check if route is active
  bool get isActive => status == RouteStatus.inProgress;

  /// Check if route is completed
  bool get isCompleted => status == RouteStatus.completed;

  /// Check if route is cancelled
  bool get isCancelled => status == RouteStatus.cancelled;

  /// Get progress percentage
  double get progressPercentage {
    if (points.isEmpty || status != RouteStatus.inProgress) return 0;
    // This would be calculated based on current position along the route
    return 0.0;
  }

  /// Check if route has steps
  bool get hasSteps => steps.isNotEmpty;

  /// Get step count
  int get stepCount => steps.length;

  /// Get origin name
  String get originName {
    if (origin != null) return origin!.name;
    if (startLocation != null) return 'Start';
    return 'Unknown Origin';
  }

  /// Get destination name
  String get destinationName {
    if (destination != null) return destination!.name;
    if (endLocation != null) return 'Destination';
    return 'Unknown Destination';
  }

  // ============ EQUALITY ============

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ============ ROUTE STEP MODEL ============

class RouteStep {
  final String instruction;
  final double distance; // in kilometers
  final double duration; // in minutes
  final List<LatLng> points;
  final RouteStepType type;
  final String? street;
  final String? exitNumber;
  final Map<String, dynamic>? metadata;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.points = const [],
    this.type = RouteStepType.continue_straight,
    this.street,
    this.exitNumber,
    this.metadata,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final points =
        (json['points'] as List?)?.map((point) {
          return LatLng(point['lat'] ?? 0, point['lng'] ?? 0);
        }).toList() ??
        [];

    return RouteStep(
      instruction: json['instruction'] ?? 'Continue',
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      points: points,
      type: RouteStepType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => RouteStepType.continue_straight,
      ),
      street: json['street'],
      exitNumber: json['exit_number'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'distance': distance,
      'duration': duration,
      'points': points
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'type': type.toString(),
      'street': street,
      'exit_number': exitNumber,
      'metadata': metadata,
    };
  }

  /// Get step icon based on type
  IconData get icon {
    switch (type) {
      case RouteStepType.turn:
        return Icons.turn_right;
      case RouteStepType.merge:
        return Icons.merge_type;
      case RouteStepType.fork:
        return Icons.fork_right;
      case RouteStepType.exit:
        return Icons.exit_to_app;
      case RouteStepType.roundabout:
        return Icons.rotate_right;
      case RouteStepType.depart:
        return Icons.play_arrow;
      case RouteStepType.arrive:
        return Icons.flag;
      default:
        return Icons.straighten;
    }
  }

  String get formattedDistance => AppConstants.formatDistance(distance);
  String get formattedDuration => AppConstants.formatDuration(duration);
}

// ============ ENUMS ============

enum RouteType { driving, walking, cycling, transit }

enum RouteStatus { pending, inProgress, completed, cancelled, failed }

enum RouteStepType {
  continue_straight,
  turn,
  merge,
  fork,
  exit,
  roundabout,
  depart,
  arrive,
}

// ============ ROUTE COLLECTION ============

class RouteCollection {
  final List<RouteModel> routes;
  final String? userId;

  const RouteCollection({required this.routes, this.userId});

  /// Get active routes
  List<RouteModel> get activeRoutes {
    return routes.where((route) => route.isActive).toList();
  }

  /// Get completed routes
  List<RouteModel> get completedRoutes {
    return routes.where((route) => route.isCompleted).toList();
  }

  /// Get cancelled routes
  List<RouteModel> get cancelledRoutes {
    return routes.where((route) => route.isCancelled).toList();
  }

  /// Get routes by type
  List<RouteModel> getByType(RouteType type) {
    return routes.where((route) => route.type == type).toList();
  }

  /// Get routes by status
  List<RouteModel> getByStatus(RouteStatus status) {
    return routes.where((route) => route.status == status).toList();
  }

  /// Sort by date
  List<RouteModel> sortByDate({bool ascending = false}) {
    final sorted = List<RouteModel>.from(routes);
    sorted.sort(
      (a, b) => ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt),
    );
    return sorted;
  }

  /// Sort by distance
  List<RouteModel> sortByDistance({bool ascending = true}) {
    final sorted = List<RouteModel>.from(routes);
    sorted.sort(
      (a, b) => ascending
          ? a.distance.compareTo(b.distance)
          : b.distance.compareTo(a.distance),
    );
    return sorted;
  }

  /// Sort by duration
  List<RouteModel> sortByDuration({bool ascending = true}) {
    final sorted = List<RouteModel>.from(routes);
    sorted.sort(
      (a, b) => ascending
          ? a.duration.compareTo(b.duration)
          : b.duration.compareTo(a.duration),
    );
    return sorted;
  }

  /// Get route by id
  RouteModel? getById(String id) {
    try {
      return routes.firstWhere((route) => route.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get routes for today
  List<RouteModel> getTodayRoutes() {
    final today = DateTime.now();
    return routes
        .where(
          (route) =>
              route.createdAt.year == today.year &&
              route.createdAt.month == today.month &&
              route.createdAt.day == today.day,
        )
        .toList();
  }

  /// Get routes for this week
  List<RouteModel> getWeekRoutes() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return routes.where((route) => route.createdAt.isAfter(weekAgo)).toList();
  }

  /// Get routes for this month
  List<RouteModel> getMonthRoutes() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return routes.where((route) => route.createdAt.isAfter(monthAgo)).toList();
  }

  /// Get total distance
  double get totalDistance {
    return routes.fold(0.0, (sum, route) => sum + route.distance);
  }

  /// Get total duration
  double get totalDuration {
    return routes.fold(0.0, (sum, route) => sum + route.duration);
  }

  /// Get average distance
  double get averageDistance {
    if (routes.isEmpty) return 0;
    return totalDistance / routes.length;
  }

  /// Get average duration
  double get averageDuration {
    if (routes.isEmpty) return 0;
    return totalDuration / routes.length;
  }
}
