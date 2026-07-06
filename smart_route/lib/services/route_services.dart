import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:smart_route/core/utills/helpers.dart';
import 'dart:convert';

import '../models/route_model.dart';
import '../models/place_model.dart';
import '../core/constants/app_constants.dart';

class RouteService {
  // ============ ROUTE CALCULATION ============

  /// Get route between two points
  Future<RouteModel> getRoute({
    required LatLng origin,
    required LatLng destination,
    PlaceModel? originPlace,
    PlaceModel? destinationPlace,
    RouteType type = RouteType.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
    bool alternatives = false,
  }) async {
    try {
      final routes = await getRoutes(
        origin: origin,
        destination: destination,
        originPlace: originPlace,
        destinationPlace: destinationPlace,
        type: type,
        avoidTolls: avoidTolls,
        avoidHighways: avoidHighways,
        avoidFerries: avoidFerries,
        alternatives: alternatives,
      );

      if (routes.isEmpty) {
        throw Exception('No routes found');
      }

      return routes.first;
    } catch (e) {
      Helpers.logError(e, tag: 'RouteService.getRoute');
      rethrow;
    }
  }

  /// Get multiple routes with alternatives
  Future<List<RouteModel>> getRoutes({
    required LatLng origin,
    required LatLng destination,
    PlaceModel? originPlace,
    PlaceModel? destinationPlace,
    RouteType type = RouteType.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
    bool alternatives = false,
    int alternativeCount = 3,
  }) async {
    try {
      final profile = _getRouteProfile(type);
      final baseUrl = _buildRouteUrl(
        origin: origin,
        destination: destination,
        profile: profile,
        alternatives: alternatives,
        alternativeCount: alternativeCount,
        avoidTolls: avoidTolls,
        avoidHighways: avoidHighways,
        avoidFerries: avoidFerries,
      );

      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to get route: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      return _parseRoutes(
        data,
        originPlace: originPlace,
        destinationPlace: destinationPlace,
        type: type,
      );
    } catch (e) {
      Helpers.logError(e, tag: 'RouteService.getRoutes');
      rethrow;
    }
  }

  /// Get route with waypoints
  Future<RouteModel> getRouteWithWaypoints({
    required List<LatLng> waypoints,
    List<PlaceModel>? waypointPlaces,
    PlaceModel? originPlace,
    PlaceModel? destinationPlace,
    RouteType type = RouteType.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
  }) async {
    if (waypoints.length < 2) {
      throw Exception('At least 2 waypoints required');
    }

    try {
      final profile = _getRouteProfile(type);
      final coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      final baseUrl = _buildRouteUrlWithWaypoints(
        coordinates: coordinates,
        profile: profile,
        avoidTolls: avoidTolls,
        avoidHighways: avoidHighways,
        avoidFerries: avoidFerries,
      );

      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to get route: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final routes = _parseRoutes(
        data,
        originPlace: originPlace,
        destinationPlace: destinationPlace,
        type: type,
      );

      if (routes.isEmpty) {
        throw Exception('No routes found');
      }

      return routes.first;
    } catch (e) {
      Helpers.logError(e, tag: 'RouteService.getRouteWithWaypoints');
      rethrow;
    }
  }

  // ============ ROUTE MATRIX ============

  /// Get distance matrix between origins and destinations
  Future<RouteMatrix> getRouteMatrix({
    required List<LatLng> origins,
    required List<LatLng> destinations,
    RouteType type = RouteType.driving,
  }) async {
    try {
      final profile = _getRouteProfile(type);
      final originStr = origins
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');
      final destStr = destinations
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url =
          '${AppConstants.osmRoutingUrl}table/$profile/'
          '$originStr?destinations=$destStr&annotations=distance,duration';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to get route matrix: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      return _parseRouteMatrix(data);
    } catch (e) {
      Helpers.logError(e, tag: 'RouteService.getRouteMatrix');
      rethrow;
    }
  }

  // ============ ROUTE SNAPPING ============

  /// Snap points to road network
  Future<List<LatLng>> snapToRoad({
    required List<LatLng> points,
    RouteType type = RouteType.driving,
  }) async {
    try {
      final profile = _getRouteProfile(type);
      final coordinates = points
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url = '${AppConstants.osmRoutingUrl}match/$profile/$coordinates';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to snap points: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        return points;
      }

      final route = routes.first;
      final geometry = route['geometry'];
      if (geometry == null) {
        return points;
      }

      final coords = geometry['coordinates'] as List?;
      if (coords == null || coords.isEmpty) {
        return points;
      }

      return coords.map((coord) => LatLng(coord[1], coord[0])).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'RouteService.snapToRoad');
      return points;
    }
  }

  // ============ ROUTE OPTIMIZATION ============

  /// Optimize route order for multiple destinations
  Future<List<LatLng>> optimizeRoute({
    required LatLng origin,
    required List<LatLng> destinations,
    RouteType type = RouteType.driving,
  }) async {
    try {
      // Get matrix to calculate optimal order
      final matrix = await getRouteMatrix(
        origins: [origin, ...destinations],
        destinations: [origin, ...destinations],
        type: type,
      );

      return _calculateOptimalOrder(origin, destinations, matrix);
    } catch (e) {
      Helpers.logError(e, tag: 'RouteService.optimizeRoute');
      return [origin, ...destinations];
    }
  }

  // ============ ROUTE PARSING ============

  List<RouteModel> _parseRoutes(
    Map<String, dynamic> data, {
    PlaceModel? originPlace,
    PlaceModel? destinationPlace,
    RouteType type = RouteType.driving,
  }) {
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      return [];
    }

    final waypoints = data['waypoints'] as List? ?? [];
    final parsedRoutes = <RouteModel>[];

    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      final distance = (route['distance'] ?? 0) / 1000;
      final duration = (route['duration'] ?? 0) / 60;

      final points = _parseGeometry(route['geometry']);
      final steps = _parseSteps(route['legs']);

      // Get origin and destination from waypoints
      PlaceModel? origin;
      PlaceModel? destination;

      if (i < waypoints.length - 1) {
        final originWp = waypoints[i];
        final destWp = waypoints[i + 1];
        origin = PlaceModel.fromOSM({
          'lat': originWp['location']?[1],
          'lon': originWp['location']?[0],
          'name': originWp['name'] ?? 'Start',
        });
        destination = PlaceModel.fromOSM({
          'lat': destWp['location']?[1],
          'lon': destWp['location']?[0],
          'name': destWp['name'] ?? 'Destination',
        });
      }

      parsedRoutes.add(
        RouteModel(
          points: points,
          origin: originPlace ?? origin,
          destination: destinationPlace ?? destination,
          distance: distance,
          duration: duration,
          trafficDelay: _calculateTrafficDelay(route),
          steps: steps,
          type: type,
          status: RouteStatus.pending,
          metadata: {
            'weight': route['weight'],
            'weight_name': route['weight_name'],
            'osrm_response': route,
          },
        ),
      );
    }

    return parsedRoutes;
  }

  List<LatLng> _parseGeometry(dynamic geometry) {
    if (geometry == null) return [];

    if (geometry is Map && geometry.containsKey('coordinates')) {
      final coords = geometry['coordinates'] as List;
      return coords.map((coord) => LatLng(coord[1], coord[0])).toList();
    }

    if (geometry is String) {
      return _decodePolyline(geometry);
    }

    return [];
  }

  List<RouteStep> _parseSteps(dynamic legs) {
    if (legs == null) return [];

    final steps = <RouteStep>[];
    final legsList = legs as List?;
    if (legsList == null || legsList.isEmpty) return steps;

    final leg = legsList.first;
    final legSteps = leg['steps'] as List?;
    if (legSteps == null) return steps;

    for (final step in legSteps) {
      final stepPoints = _parseGeometry(step['geometry']);
      steps.add(
        RouteStep(
          instruction:
              step['maneuver']?['instruction'] ??
              step['maneuver']?['type'] ??
              'Continue',
          distance: (step['distance'] ?? 0) / 1000,
          duration: (step['duration'] ?? 0) / 60,
          points: stepPoints,
          type: _getStepType(step['maneuver']?['type'] ?? ''),
          street: step['name'],
          exitNumber: step['maneuver']?['exit'],
          metadata: {
            'maneuver': step['maneuver'],
            'intersections': step['intersections'],
          },
        ),
      );
    }

    return steps;
  }

  double? _calculateTrafficDelay(Map<String, dynamic> route) {
    final duration = route['duration'] as double?;
    final durationTypical = route['duration_typical'] as double?;
    if (duration != null &&
        durationTypical != null &&
        durationTypical > duration) {
      return (durationTypical - duration) / 60;
    }
    return null;
  }

  RouteMatrix _parseRouteMatrix(Map<String, dynamic> data) {
    final durations = data['durations'] as List? ?? [];
    final distances = data['distances'] as List? ?? [];

    final matrixData = <RouteMatrixData>[];
    for (int i = 0; i < durations.length; i++) {
      final rowDurations = durations[i] as List? ?? [];
      final rowDistances = distances[i] as List? ?? [];
      for (int j = 0; j < rowDurations.length; j++) {
        matrixData.add(
          RouteMatrixData(
            originIndex: i,
            destinationIndex: j,
            distance: (rowDistances[j] ?? 0) / 1000,
            duration: (rowDurations[j] ?? 0) / 60,
          ),
        );
      }
    }

    return RouteMatrix(
      data: matrixData,
      origins:
          (data['sources'] as List?)
              ?.map(
                (s) => LatLng(s['location']?[1] ?? 0, s['location']?[0] ?? 0),
              )
              .toList() ??
          [],
      destinations:
          (data['destinations'] as List?)
              ?.map(
                (d) => LatLng(d['location']?[1] ?? 0, d['location']?[0] ?? 0),
              )
              .toList() ??
          [],
    );
  }

  // ============ ROUTE OPTIMIZATION ALGORITHM ============

  List<LatLng> _calculateOptimalOrder(
    LatLng origin,
    List<LatLng> destinations,
    RouteMatrix matrix,
  ) {
    if (destinations.isEmpty) return [origin];
    if (destinations.length == 1) return [origin, destinations.first];

    // Simple nearest neighbor algorithm
    final unvisited = List<LatLng>.from(destinations);
    final ordered = <LatLng>[origin];
    var current = origin;

    while (unvisited.isNotEmpty) {
      LatLng? nearest;
      double? nearestDistance;

      for (final point in unvisited) {
        final distance = matrix.getDistance(current, point);
        if (nearest == null ||
            distance < (nearestDistance ?? double.infinity)) {
          nearest = point;
          nearestDistance = distance;
        }
      }

      if (nearest != null) {
        ordered.add(nearest);
        current = nearest;
        unvisited.remove(nearest);
      }
    }

    return ordered;
  }

  // ============ URL BUILDING ============

  String _buildRouteUrl({
    required LatLng origin,
    required LatLng destination,
    required String profile,
    bool alternatives = false,
    int alternativeCount = 3,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
  }) {
    final url =
        '${AppConstants.osmRoutingUrl}$profile/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full'
        '&geometries=geojson'
        '&steps=true'
        '&alternatives=$alternatives'
        '&number=$alternativeCount';

    // Add avoid options
    final avoids = <String>[];
    if (avoidTolls) avoids.add('toll');
    if (avoidHighways) avoids.add('motorway');
    if (avoidFerries) avoids.add('ferry');

    if (avoids.isNotEmpty) {
      return '$url&exclude=${avoids.join(',')}';
    }

    return url;
  }

  String _buildRouteUrlWithWaypoints({
    required String coordinates,
    required String profile,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
  }) {
    final url =
        '${AppConstants.osmRoutingUrl}$profile/$coordinates'
        '?overview=full'
        '&geometries=geojson'
        '&steps=true';

    final avoids = <String>[];
    if (avoidTolls) avoids.add('toll');
    if (avoidHighways) avoids.add('motorway');
    if (avoidFerries) avoids.add('ferry');

    if (avoids.isNotEmpty) {
      return '$url&exclude=${avoids.join(',')}';
    }

    return url;
  }

  // ============ HELPER METHODS ============

  String _getRouteProfile(RouteType type) {
    switch (type) {
      case RouteType.driving:
        return 'driving';
      case RouteType.walking:
        return 'walking';
      case RouteType.cycling:
        return 'cycling';
      case RouteType.transit:
        return 'driving'; // OSRM doesn't have transit, fallback to driving
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
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

  RouteStepType _getStepType(String type) {
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

  // ============ ROUTE FILTERING ============

  /// Filter routes by maximum distance
  List<RouteModel> filterByMaxDistance(
    List<RouteModel> routes,
    double maxDistance,
  ) {
    return routes.where((route) => route.distance <= maxDistance).toList();
  }

  /// Filter routes by maximum duration
  List<RouteModel> filterByMaxDuration(
    List<RouteModel> routes,
    double maxDuration,
  ) {
    return routes.where((route) => route.duration <= maxDuration).toList();
  }

  /// Get shortest route
  RouteModel? getShortestRoute(List<RouteModel> routes) {
    if (routes.isEmpty) return null;
    return routes.reduce((a, b) => a.distance < b.distance ? a : b);
  }

  /// Get fastest route
  RouteModel? getFastestRoute(List<RouteModel> routes) {
    if (routes.isEmpty) return null;
    return routes.reduce((a, b) => a.duration < b.duration ? a : b);
  }

  /// Get most efficient route (balance of distance and duration)
  RouteModel? getMostEfficientRoute(List<RouteModel> routes) {
    if (routes.isEmpty) return null;

    // Normalize distance and duration
    final maxDistance = routes
        .map((r) => r.distance)
        .reduce((a, b) => a > b ? a : b);
    final maxDuration = routes
        .map((r) => r.duration)
        .reduce((a, b) => a > b ? a : b);

    RouteModel? mostEfficient;
    double? bestScore;

    for (final route in routes) {
      final normalizedDistance = route.distance / maxDistance;
      final normalizedDuration = route.duration / maxDuration;
      final score = normalizedDistance + normalizedDuration;

      if (bestScore == null || score < bestScore) {
        bestScore = score;
        mostEfficient = route;
      }
    }

    return mostEfficient;
  }

  // ============ ROUTE AGGREGATION ============

  /// Aggregate multiple routes
  RouteAggregation aggregateRoutes(List<RouteModel> routes) {
    if (routes.isEmpty) {
      return RouteAggregation(
        totalDistance: 0,
        totalDuration: 0,
        averageDistance: 0,
        averageDuration: 0,
        shortestDistance: 0,
        longestDistance: 0,
        shortestDuration: 0,
        longestDuration: 0,
        routes: routes,
      );
    }

    final totalDistance = routes.fold(0.0, (sum, r) => sum + r.distance);
    final totalDuration = routes.fold(0.0, (sum, r) => sum + r.duration);
    final averageDistance = totalDistance / routes.length;
    final averageDuration = totalDuration / routes.length;

    final shortest = getShortestRoute(routes)!;
    final fastest = getFastestRoute(routes)!;

    return RouteAggregation(
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      averageDistance: averageDistance,
      averageDuration: averageDuration,
      shortestDistance: shortest.distance,
      longestDistance: routes
          .map((r) => r.distance)
          .reduce((a, b) => a > b ? a : b),
      shortestDuration: fastest.duration,
      longestDuration: routes
          .map((r) => r.duration)
          .reduce((a, b) => a > b ? a : b),
      routes: routes,
    );
  }
}

// ============ ROUTE MATRIX ============

class RouteMatrix {
  final List<RouteMatrixData> data;
  final List<LatLng> origins;
  final List<LatLng> destinations;

  RouteMatrix({
    required this.data,
    required this.origins,
    required this.destinations,
  });

  /// Get distance between two points
  double getDistance(LatLng origin, LatLng destination) {
    final originIndex = origins.indexOf(origin);
    final destIndex = destinations.indexOf(destination);
    if (originIndex == -1 || destIndex == -1) return 0;

    final result = data
        .where(
          (d) =>
              d.originIndex == originIndex && d.destinationIndex == destIndex,
        )
        .toList();

    if (result.isEmpty) return 0;
    return result.first.distance;
  }

  /// Get duration between two points
  double getDuration(LatLng origin, LatLng destination) {
    final originIndex = origins.indexOf(origin);
    final destIndex = destinations.indexOf(destination);
    if (originIndex == -1 || destIndex == -1) return 0;

    final result = data
        .where(
          (d) =>
              d.originIndex == originIndex && d.destinationIndex == destIndex,
        )
        .toList();

    if (result.isEmpty) return 0;
    return result.first.duration;
  }
}

class RouteMatrixData {
  final int originIndex;
  final int destinationIndex;
  final double distance; // in km
  final double duration; // in minutes

  RouteMatrixData({
    required this.originIndex,
    required this.destinationIndex,
    required this.distance,
    required this.duration,
  });
}

// ============ ROUTE AGGREGATION ============

class RouteAggregation {
  final double totalDistance;
  final double totalDuration;
  final double averageDistance;
  final double averageDuration;
  final double shortestDistance;
  final double longestDistance;
  final double shortestDuration;
  final double longestDuration;
  final List<RouteModel> routes;

  RouteAggregation({
    required this.totalDistance,
    required this.totalDuration,
    required this.averageDistance,
    required this.averageDuration,
    required this.shortestDistance,
    required this.longestDistance,
    required this.shortestDuration,
    required this.longestDuration,
    required this.routes,
  });

  String get formattedTotalDistance =>
      AppConstants.formatDistance(totalDistance);
  String get formattedTotalDuration =>
      AppConstants.formatDuration(totalDuration);
  String get formattedAverageDistance =>
      AppConstants.formatDistance(averageDistance);
  String get formattedAverageDuration =>
      AppConstants.formatDuration(averageDuration);
}
