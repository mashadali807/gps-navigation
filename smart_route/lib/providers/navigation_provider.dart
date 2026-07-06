import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:smart_route/services/map_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';

import '../models/route_model.dart';
import '../models/place_model.dart';
import '../models/location_model.dart';
import '../core/constants/app_constants.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class NavigationProvider extends ChangeNotifier {
  // ============ STATE VARIABLES ============

  // Route data
  RouteModel? _currentRoute;
  List<RouteModel> _alternativeRoutes = [];
  int _selectedRouteIndex = 0;

  // Navigation state
  bool _isNavigating = false;
  bool _isRouteCalculating = false;
  bool _isRouteLoaded = false;
  String? _error;

  // Current position on route
  LatLng? _currentPosition;
  int _currentStepIndex = 0;
  double _progress = 0.0; // 0.0 to 1.0

  // Navigation metrics
  double _remainingDistance = 0.0; // in km
  double _remainingTime = 0.0; // in minutes
  double _currentSpeed = 0.0; // in km/h
  double _distanceToDestination = 0.0; // in km
  DateTime? _estimatedArrivalTime;
  DateTime? _startTime;
  DateTime? _lastUpdateTime;

  // Route progress
  LatLng? _nextWaypoint;
  String? _nextInstruction;
  double _nextInstructionDistance = 0.0;

  // Route options
  RouteType _routeType = RouteType.driving;
  bool _avoidTolls = false;
  bool _avoidHighways = false;
  bool _avoidFerries = false;
  bool _showTraffic = true;

  // Navigation history
  List<LatLng> _traveledPath = [];
  List<NavigationEvent> _navigationEvents = [];

  // Timer for navigation updates
  Timer? _navigationTimer;
  StreamSubscription? _positionSubscription;
  Polyline? _routePolyline;

  // ============ GETTERS ============

  RouteModel? get currentRoute => _currentRoute;
  List<RouteModel> get alternativeRoutes => _alternativeRoutes;
  int get selectedRouteIndex => _selectedRouteIndex;
  bool get isNavigating => _isNavigating;
  bool get isRouteCalculating => _isRouteCalculating;
  bool get isRouteLoaded => _isRouteLoaded;
  String? get error => _error;
  LatLng? get currentPosition => _currentPosition;
  int get currentStepIndex => _currentStepIndex;
  double get progress => _progress;
  double get remainingDistance => _remainingDistance;
  double get remainingTime => _remainingTime;
  double get currentSpeed => _currentSpeed;
  double get distanceToDestination => _distanceToDestination;
  DateTime? get estimatedArrivalTime => _estimatedArrivalTime;
  DateTime? get startTime => _startTime;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  LatLng? get nextWaypoint => _nextWaypoint;
  String? get nextInstruction => _nextInstruction;
  double get nextInstructionDistance => _nextInstructionDistance;
  RouteType get routeType => _routeType;
  bool get avoidTolls => _avoidTolls;
  bool get avoidHighways => _avoidHighways;
  bool get avoidFerries => _avoidFerries;
  bool get showTraffic => _showTraffic;
  List<LatLng> get traveledPath => _traveledPath;
  List<NavigationEvent> get navigationEvents => _navigationEvents;

  // ============ COMPUTED GETTERS ============

  String get formattedRemainingDistance {
    return AppConstants.formatDistance(_remainingDistance);
  }

  String get formattedRemainingTime {
    return AppConstants.formatDuration(_remainingTime);
  }

  String get formattedCurrentSpeed {
    return AppConstants.formatSpeed(_currentSpeed / 3.6); // Convert km/h to m/s
  }

  String get formattedDistanceToDestination {
    return AppConstants.formatDistance(_distanceToDestination);
  }

  String get formattedEstimatedArrival {
    if (_estimatedArrivalTime == null) return 'N/A';
    return Helpers.formatTime(_estimatedArrivalTime!);
  }

  double get progressPercentage {
    return _progress * 100;
  }

  bool get hasAlternativeRoutes => _alternativeRoutes.length > 1;

  int get totalSteps => _currentRoute?.steps.length ?? 0;

  RouteStep? get currentStep {
    if (_currentRoute == null ||
        _currentStepIndex >= _currentRoute!.steps.length) {
      return null;
    }
    return _currentRoute!.steps[_currentStepIndex];
  }

  RouteStep? get nextStep {
    if (_currentRoute == null ||
        _currentStepIndex + 1 >= _currentRoute!.steps.length) {
      return null;
    }
    return _currentRoute!.steps[_currentStepIndex + 1];
  }

  bool get isLastStep {
    if (_currentRoute == null) return true;
    return _currentStepIndex >= _currentRoute!.steps.length - 1;
  }

  bool get isNearDestination {
    return _remainingDistance < 0.1; // Within 100 meters
  }

  // ============ ROUTE CALCULATION ============

  Future<bool> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    PlaceModel? originPlace,
    PlaceModel? destinationPlace,
    RouteType type = RouteType.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
    bool avoidFerries = false,
    bool getAlternatives = true,
  }) async {
    try {
      _setRouteCalculating(true);
      _clearError();

      _routeType = type;
      _avoidTolls = avoidTolls;
      _avoidHighways = avoidHighways;
      _avoidFerries = avoidFerries;

      // Get routes
      final routes = await _getRoutes(
        origin: origin,
        destination: destination,
        originPlace: originPlace,
        destinationPlace: destinationPlace,
        type: type,
      );

      if (routes.isEmpty) {
        throw Exception('No routes found');
      }

      _currentRoute = routes.first;
      _alternativeRoutes = routes;
      _selectedRouteIndex = 0;
      _isRouteLoaded = true;

      // Initialize navigation metrics
      _remainingDistance = _currentRoute!.distance;
      _remainingTime = _currentRoute!.duration;
      _distanceToDestination = _currentRoute!.distance;

      _setRouteCalculating(false);
      notifyListeners();

      return true;
    } catch (e) {
      _handleError(e);
      _setRouteCalculating(false);
      return false;
    }
  }

  Future<List<RouteModel>> _getRoutes({
    required LatLng origin,
    required LatLng destination,
    PlaceModel? originPlace,
    PlaceModel? destinationPlace,
    RouteType type = RouteType.driving,
    int alternatives = 3,
  }) async {
    // Get main route
    final routeData = await MapService.getRoute(
      start: origin,
      end: destination,
    );
    final mainRoute = RouteModel.fromOSRM(
      response: {
        'routes': [
          {
            'geometry': {
              'coordinates': routeData.points
                  .map((p) => [p.longitude, p.latitude])
                  .toList(),
            },
            'distance': routeData.distance * 1000,
            'duration': routeData.duration * 60,
          },
        ],
      },
      origin: originPlace,
      destination: destinationPlace,
      type: type,
    );

    // Generate alternative routes (simplified)
    final routes = <RouteModel>[mainRoute];

    if (alternatives > 1) {
      for (int i = 1; i < alternatives; i++) {
        final variation = 1.0 + (i * 0.15);
        final altRoute = mainRoute.copyWith(
          distance: mainRoute.distance * variation,
          duration: mainRoute.duration * (variation * 0.95),
          name: 'Alternative ${i + 1}',
          metadata: {'is_alternative': true, 'index': i},
        );
        routes.add(altRoute);
      }
    }

    return routes;
  }

  // ============ NAVIGATION CONTROL ============

  void startNavigation({int routeIndex = 0, DateTime? startTime}) {
    if (_currentRoute == null || !_isRouteLoaded) {
      _error = 'No route loaded';
      notifyListeners();
      return;
    }

    if (routeIndex > 0 && routeIndex < _alternativeRoutes.length) {
      _currentRoute = _alternativeRoutes[routeIndex];
      _selectedRouteIndex = routeIndex;
    }

    _isNavigating = true;
    _startTime = startTime ?? DateTime.now();
    _currentStepIndex = 0;
    _progress = 0.0;
    _remainingDistance = _currentRoute!.distance;
    _remainingTime = _currentRoute!.duration;
    _distanceToDestination = _currentRoute!.distance;
    _traveledPath.clear();
    _navigationEvents.clear();
    _lastUpdateTime = DateTime.now();

    // Calculate estimated arrival
    _updateEstimatedArrival();

    // Get first instruction
    if (_currentRoute!.steps.isNotEmpty) {
      _nextInstruction = _currentRoute!.steps.first.instruction;
      _nextInstructionDistance = _currentRoute!.steps.first.distance;
    }

    // Add navigation start event
    _addNavigationEvent(
      type: NavigationEventType.start,
      message: 'Navigation started',
      position: _currentRoute!.startPoint,
    );

    // Start position updates
    _startPositionUpdates();

    notifyListeners();
  }

  void stopNavigation() {
    _isNavigating = false;
    _navigationTimer?.cancel();
    _positionSubscription?.cancel();

    // Add navigation end event
    if (_currentPosition != null) {
      _addNavigationEvent(
        type: NavigationEventType.end,
        message: 'Navigation ended',
        position: _currentPosition,
      );
    }

    notifyListeners();
  }

  /// Select a specific route for navigation
  void selectRoute(RouteModel route) {
    _currentRoute = route;
    _routePolyline = route.polyline as Polyline?;
    _remainingDistance = route.distance;
    _remainingTime = route.duration;
    _distanceToDestination = route.distance;
    notifyListeners();
  }

  void pauseNavigation() {
    _isNavigating = false;
    _navigationTimer?.cancel();
    _positionSubscription?.pause();
    notifyListeners();
  }

  void resumeNavigation() {
    if (_currentRoute == null) return;
    _isNavigating = true;
    _positionSubscription?.resume();
    _startPositionUpdates();
    notifyListeners();
  }

  void selectAlternativeRoute(int index) {
    if (index < 0 || index >= _alternativeRoutes.length) return;

    _selectedRouteIndex = index;
    _currentRoute = _alternativeRoutes[index];
    _remainingDistance = _currentRoute!.distance;
    _remainingTime = _currentRoute!.duration;
    _distanceToDestination = _currentRoute!.distance;
    _progress = 0.0;
    _currentStepIndex = 0;

    _updateEstimatedArrival();
    notifyListeners();
  }

  // ============ POSITION UPDATES ============

  void updatePosition(LatLng position, {double speed = 0.0}) {
    if (!_isNavigating || _currentRoute == null) return;

    _currentPosition = position;
    _currentSpeed = speed;
    _lastUpdateTime = DateTime.now();

    // Add to traveled path
    _traveledPath.add(position);

    // Update route progress
    _updateRouteProgress(position);

    // Update navigation metrics
    _updateMetrics(position);

    // Update next instruction
    _updateNextInstruction(position);

    // Check if arrived
    _checkArrival();

    // Update estimated arrival
    _updateEstimatedArrival();

    // Add navigation update event
    _addNavigationEvent(
      type: NavigationEventType.update,
      message: 'Position updated',
      position: position,
      data: {
        'speed': speed,
        'remaining_distance': _remainingDistance,
        'remaining_time': _remainingTime,
      },
    );

    notifyListeners();
  }

  void _updateRouteProgress(LatLng position) {
    if (_currentRoute == null || _currentRoute!.points.isEmpty) return;

    // Calculate progress based on distance to destination
    final totalDistance = _currentRoute!.distance;
    final remainingDistance = _calculateRemainingDistance(position);
    _remainingDistance = remainingDistance;
    _progress = 1.0 - (remainingDistance / totalDistance);
    _progress = _progress.clamp(0.0, 1.0);

    // Update step index
    _updateStepIndex(position);
  }

  void _updateStepIndex(LatLng position) {
    if (_currentRoute == null) return;

    final steps = _currentRoute!.steps;
    double minDistance = double.infinity;
    int closestStep = 0;

    for (int i = 0; i < steps.length; i++) {
      if (steps[i].points.isEmpty) continue;
      final stepPoint = steps[i].points.first;
      final distance = Helpers.calculateDistance(
        lat1: position.latitude,
        lon1: position.longitude,
        lat2: stepPoint.latitude,
        lon2: stepPoint.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestStep = i;
      }
    }

    // Only move forward
    if (closestStep >= _currentStepIndex) {
      _currentStepIndex = closestStep;
    }
  }

  void _updateMetrics(LatLng position) {
    if (_currentRoute == null) return;

    // Calculate remaining distance
    _remainingDistance = _calculateRemainingDistance(position);

    // Calculate remaining time based on current speed
    if (_currentSpeed > 0) {
      final estimatedTime = _remainingDistance / _currentSpeed; // hours
      _remainingTime = estimatedTime * 60; // minutes
    } else {
      // Use average speed from route
      final avgSpeed = _currentRoute!.distance / (_currentRoute!.duration / 60);
      if (avgSpeed > 0) {
        final estimatedTime = _remainingDistance / avgSpeed; // hours
        _remainingTime = estimatedTime * 60; // minutes
      }
    }

    _distanceToDestination = _remainingDistance;
  }

  double _calculateRemainingDistance(LatLng position) {
    if (_currentRoute == null) return 0;

    // Find closest point on route
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _currentRoute!.points.length; i++) {
      final point = _currentRoute!.points[i];
      final distance = Helpers.calculateDistance(
        lat1: position.latitude,
        lon1: position.longitude,
        lat2: point.latitude,
        lon2: point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Calculate remaining distance from closest point to end
    double remaining = 0;
    for (int i = closestIndex; i < _currentRoute!.points.length - 1; i++) {
      final p1 = _currentRoute!.points[i];
      final p2 = _currentRoute!.points[i + 1];
      remaining += Helpers.calculateDistance(
        lat1: p1.latitude,
        lon1: p1.longitude,
        lat2: p2.latitude,
        lon2: p2.longitude,
      );
    }

    return remaining;
  }

  void _updateNextInstruction(LatLng position) {
    if (_currentRoute == null || _currentRoute!.steps.isEmpty) return;

    // Get next unvisited step
    for (int i = _currentStepIndex; i < _currentRoute!.steps.length; i++) {
      final step = _currentRoute!.steps[i];
      if (step.points.isEmpty) continue;

      final stepStart = step.points.first;
      final distance = Helpers.calculateDistance(
        lat1: position.latitude,
        lon1: position.longitude,
        lat2: stepStart.latitude,
        lon2: stepStart.longitude,
      );

      if (distance < 0.1) {
        // Within 100 meters
        _nextInstruction = step.instruction;
        _nextInstructionDistance = step.distance;
        _nextWaypoint = step.points.last;
        break;
      }
    }
  }

  void _updateEstimatedArrival() {
    if (_startTime == null) return;
    _estimatedArrivalTime = _startTime!.add(
      Duration(minutes: _remainingTime.round()),
    );
  }

  void _checkArrival() {
    if (_remainingDistance < 0.05) {
      // Within 50 meters
      _onArrive();
    }
  }

  void _onArrive() {
    _isNavigating = false;
    _navigationTimer?.cancel();
    _positionSubscription?.cancel();

    _addNavigationEvent(
      type: NavigationEventType.arrive,
      message: 'Arrived at destination',
      position: _currentPosition,
    );

    notifyListeners();
  }

  // ============ POSITION STREAM ============

  void _startPositionUpdates() {
    _navigationTimer?.cancel();
    _navigationTimer = Timer.periodic(
      const Duration(seconds: AppConstants.locationUpdateInterval),
      (timer) {
        // Simulate position updates if no real position stream
        // In production, this would come from LocationService
        if (_currentPosition != null) {
          // Update position slightly along route
          _simulatePositionUpdate();
        }
      },
    );
  }

  void _simulatePositionUpdate() {
    if (_currentRoute == null || !_isNavigating) return;

    // Simulate moving along route
    final points = _currentRoute!.points;
    if (points.isEmpty) return;

    // Find current index
    int currentIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final distance = Helpers.calculateDistance(
        lat1: _currentPosition?.latitude ?? 0,
        lon1: _currentPosition?.longitude ?? 0,
        lat2: point.latitude,
        lon2: point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        currentIndex = i;
      }
    }

    // Move to next point
    final nextIndex = min(currentIndex + 2, points.length - 1);
    final nextPoint = points[nextIndex];

    // Interpolate speed
    final speed = _currentSpeed > 0 ? _currentSpeed : 30; // Default 30 km/h

    // Calculate new position (simplified)
    final latDiff = nextPoint.latitude - (points[currentIndex].latitude);
    final lngDiff = nextPoint.longitude - (points[currentIndex].longitude);
    final steps = max(1, (speed / 10).round());
    final stepLat = latDiff / steps;
    final stepLng = lngDiff / steps;

    final newLat = (_currentPosition?.latitude ?? 0) + stepLat;
    final newLng = (_currentPosition?.longitude ?? 0) + stepLng;

    final newPosition = LatLng(newLat.clamp(-90, 90), newLng.clamp(-180, 180));

    updatePosition(newPosition, speed: speed.toDouble());
  }

  // ============ NAVIGATION EVENTS ============

  void _addNavigationEvent({
    required NavigationEventType type,
    required String message,
    LatLng? position,
    Map<String, dynamic>? data,
  }) {
    _navigationEvents.add(
      NavigationEvent(
        type: type,
        message: message,
        position: position,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ============ UTILITY METHODS ============

  void clearNavigation() {
    _navigationTimer?.cancel();
    _positionSubscription?.cancel();
    _isNavigating = false;
    _isRouteLoaded = false;
    _isRouteCalculating = false;
    _currentRoute = null;
    _alternativeRoutes.clear();
    _selectedRouteIndex = 0;
    _currentPosition = null;
    _remainingDistance = 0;
    _remainingTime = 0;
    _currentSpeed = 0;
    _distanceToDestination = 0;
    _progress = 0;
    _traveledPath.clear();
    _navigationEvents.clear();
    _error = null;
    notifyListeners();
  }

  void setRouteOptions({
    RouteType? type,
    bool? avoidTolls,
    bool? avoidHighways,
    bool? avoidFerries,
    bool? showTraffic,
  }) {
    if (type != null) _routeType = type;
    if (avoidTolls != null) _avoidTolls = avoidTolls;
    if (avoidHighways != null) _avoidHighways = avoidHighways;
    if (avoidFerries != null) _avoidFerries = avoidFerries;
    if (showTraffic != null) _showTraffic = showTraffic;
    notifyListeners();
  }

  // ============ PRIVATE METHODS ============

  void _setRouteCalculating(bool calculating) {
    _isRouteCalculating = calculating;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _handleError(dynamic error) {
    _error = error.toString();
    _isRouteCalculating = false;
    _isNavigating = false;
    notifyListeners();
    Helpers.logError(error, tag: 'NavigationProvider');
  }

  // ============ DISPOSE ============

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}

class Polyline {}

// ============ NAVIGATION EVENT MODEL ============

class NavigationEvent {
  final String id;
  final NavigationEventType type;
  final String message;
  final LatLng? position;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  NavigationEvent({
    String? id,
    required this.type,
    required this.message,
    this.position,
    this.data,
    required this.timestamp,
  }) : id = id ?? Helpers.generateId();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'message': message,
      'position': position != null
          ? {'lat': position!.latitude, 'lng': position!.longitude}
          : null,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory NavigationEvent.fromJson(Map<String, dynamic> json) {
    return NavigationEvent(
      id: json['id'],
      type: NavigationEventType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NavigationEventType.update,
      ),
      message: json['message'] ?? '',
      position: json['position'] != null
          ? LatLng(json['position']['lat'], json['position']['lng'])
          : null,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

// ============ ENUMS ============

enum NavigationEventType { start, update, arrive, end, reroute, error, warning }

// ============ NAVIGATION PROVIDER EXTENSIONS ============
extension NavigationProviderExtension on BuildContext {
  NavigationProvider get navigation =>
      Provider.of<NavigationProvider>(this, listen: false);

  // Change from method to getter
  NavigationProvider get watchNavigation =>
      Provider.of<NavigationProvider>(this, listen: true);

  /// Check if currently navigating
  bool get isNavigating => watchNavigation.isNavigating;

  /// Get current route
  RouteModel? get currentRoute => watchNavigation.currentRoute;

  /// Get remaining distance formatted
  String get remainingDistance => watchNavigation.formattedRemainingDistance;

  /// Get remaining time formatted
  String get remainingTime => watchNavigation.formattedRemainingTime;

  /// Get current speed formatted
  String get currentSpeed => watchNavigation.formattedCurrentSpeed;
}

// ============ NAVIGATION STREAM BUILDER ============

class NavigationStreamBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isNavigating,
    RouteModel? route,
    double progress,
    String remainingDistance,
    String remainingTime,
    String? nextInstruction,
  )
  builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? idleWidget;

  const NavigationStreamBuilder({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.idleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();

    if (navigationProvider.isRouteCalculating) {
      return loadingWidget ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Calculating route...'),
              ],
            ),
          );
    }

    if (navigationProvider.error != null) {
      return errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route_outlined, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  navigationProvider.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => navigationProvider.clearNavigation(),
                  child: const Text('Clear'),
                ),
              ],
            ),
          );
    }

    if (!navigationProvider.isRouteLoaded) {
      return idleWidget ?? const SizedBox.shrink();
    }

    return builder(
      context,
      navigationProvider.isNavigating,
      navigationProvider.currentRoute,
      navigationProvider.progress,
      navigationProvider.formattedRemainingDistance,
      navigationProvider.formattedRemainingTime,
      navigationProvider.nextInstruction,
    );
  }
}

// ============ ROUTE OPTIONS WIDGET ============

class RouteOptionsWidget extends StatefulWidget {
  final NavigationProvider provider;
  final Function(RouteOptions) onOptionsChanged;

  const RouteOptionsWidget({
    super.key,
    required this.provider,
    required this.onOptionsChanged,
  });

  @override
  State<RouteOptionsWidget> createState() => _RouteOptionsWidgetState();
}

class _RouteOptionsWidgetState extends State<RouteOptionsWidget> {
  RouteType _routeType = RouteType.driving;
  bool _avoidTolls = false;
  bool _avoidHighways = false;
  bool _avoidFerries = false;
  bool _showTraffic = true;

  @override
  void initState() {
    super.initState();
    _routeType = widget.provider.routeType;
    _avoidTolls = widget.provider.avoidTolls;
    _avoidHighways = widget.provider.avoidHighways;
    _avoidFerries = widget.provider.avoidFerries;
    _showTraffic = widget.provider.showTraffic;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Route type
            DropdownButtonFormField<RouteType>(
              value: _routeType,
              decoration: const InputDecoration(
                labelText: 'Route Type',
                border: OutlineInputBorder(),
              ),
              items: RouteType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _routeType = value);
                  _updateOptions();
                }
              },
            ),
            const SizedBox(height: 12),
            // Checkboxes
            SwitchListTile(
              title: const Text('Avoid Tolls'),
              value: _avoidTolls,
              onChanged: (value) {
                setState(() => _avoidTolls = value);
                _updateOptions();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Avoid Highways'),
              value: _avoidHighways,
              onChanged: (value) {
                setState(() => _avoidHighways = value);
                _updateOptions();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Avoid Ferries'),
              value: _avoidFerries,
              onChanged: (value) {
                setState(() => _avoidFerries = value);
                _updateOptions();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Show Traffic'),
              value: _showTraffic,
              onChanged: (value) {
                setState(() => _showTraffic = value);
                _updateOptions();
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _updateOptions() {
    widget.provider.setRouteOptions(
      type: _routeType,
      avoidTolls: _avoidTolls,
      avoidHighways: _avoidHighways,
      avoidFerries: _avoidFerries,
      showTraffic: _showTraffic,
    );
    widget.onOptionsChanged(
      RouteOptions(
        type: _routeType,
        avoidTolls: _avoidTolls,
        avoidHighways: _avoidHighways,
        avoidFerries: _avoidFerries,
        showTraffic: _showTraffic,
      ),
    );
  }
}

// ============ ROUTE OPTIONS MODEL ============

class RouteOptions {
  final RouteType type;
  final bool avoidTolls;
  final bool avoidHighways;
  final bool avoidFerries;
  final bool showTraffic;

  RouteOptions({
    required this.type,
    required this.avoidTolls,
    required this.avoidHighways,
    required this.avoidFerries,
    required this.showTraffic,
  });
}
