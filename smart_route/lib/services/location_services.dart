import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'dart:async';
import 'dart:math';

import '../models/location_model.dart';
import '../core/constants/app_constants.dart';

class LocationService {
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;

  // FIXED: Use a broadcast stream controller so multiple listeners can subscribe
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  StreamSubscription<Position>? _positionStreamSubscription;
  Stream<ServiceStatus>? _serviceStatusStream;
  bool _isTracking = false;
  bool _isGpsEnabled = false;
  bool _hasPermission = false;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;

  // Location history
  List<Position> _locationHistory = [];
  int _maxHistorySize = 100;

  // Distance tracking
  double _totalDistance = 0.0;
  Position? _lastTrackedPosition;

  // Compass heading
  double _currentHeading = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // ============ GETTERS ============

  bool get isTracking => _isTracking;
  bool get isGpsEnabled => _isGpsEnabled;
  bool get hasPermission => _hasPermission;
  Position? get lastPosition => _lastPosition;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  List<Position> get locationHistory => List.unmodifiable(_locationHistory);
  double get totalDistance => _totalDistance;
  double get currentHeading => _currentHeading;

  /// FIXED: Get position stream - now returns the broadcast stream
  Stream<Position> get positionStream {
    return _positionController.stream;
  }

  // ============ PERMISSION METHODS ============

  Future<PermissionStatus> checkPermission() async {
    return await Permission.location.status;
  }

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.location.request();
      _hasPermission = status.isGranted;
      return _hasPermission;
    } catch (e) {
      Helpers.logError(e, tag: 'LocationService.requestPermission');
      return false;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      _isGpsEnabled = await _geolocator.isLocationServiceEnabled();
      return _isGpsEnabled;
    } catch (e) {
      Helpers.logError(e, tag: 'LocationService.isLocationServiceEnabled');
      return false;
    }
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // ============ GPS STATUS ============

  Stream<ServiceStatus> getServiceStatusStream() {
    _serviceStatusStream ??= Geolocator.getServiceStatusStream();
    return _serviceStatusStream!;
  }

  // ============ POSITION METHODS ============

  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int timeLimit = 15000,
  }) async {
    try {
      // Try with high accuracy first
      try {
        final settings = LocationSettings(
          accuracy: accuracy,
          timeLimit: Duration(milliseconds: timeLimit),
        );
        _lastPosition = await _geolocator.getCurrentPosition(
          locationSettings: settings,
        );
        _lastUpdateTime = DateTime.now();
        return _lastPosition!;
      } catch (e) {
        // If high accuracy fails, try with medium
        try {
          final settings = LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: const Duration(milliseconds: 10000),
          );
          _lastPosition = await _geolocator.getCurrentPosition(
            locationSettings: settings,
          );
          _lastUpdateTime = DateTime.now();
          return _lastPosition!;
        } catch (e2) {
          // If medium fails, try with low
          final settings = LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: const Duration(milliseconds: 5000),
          );
          _lastPosition = await _geolocator.getCurrentPosition(
            locationSettings: settings,
          );
          _lastUpdateTime = DateTime.now();
          return _lastPosition!;
        }
      }
    } catch (e) {
      Helpers.logError(e, tag: 'LocationService.getCurrentPosition');
      rethrow;
    }
  }

  Future<Position?> getLastKnownPosition() async {
    try {
      return await _geolocator.getLastKnownPosition();
    } catch (e) {
      Helpers.logError(e, tag: 'LocationService.getLastKnownPosition');
      return null;
    }
  }

  // ============ TRACKING METHODS ============

  void startTracking({
    Duration interval = const Duration(
      seconds: AppConstants.locationUpdateInterval,
    ),
    int distanceFilter = AppConstants.locationDistanceFilter,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    if (_isTracking) {
      // If already tracking, restart to ensure fresh stream
      stopTracking();
    }

    try {
      // FIXED: Removed intervalDuration - it doesn't exist in LocationSettings
      // The interval is controlled by distanceFilter and accuracy
      final settings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      );

      // FIXED: Properly listen to position stream and add to controller
      _positionStreamSubscription = _geolocator
          .getPositionStream(locationSettings: settings)
          .listen(
            (Position position) {
              _handlePositionUpdate(position);
              // FIXED: Add position to the broadcast stream controller
              _positionController.add(position);
            },
            onError: _handlePositionError,
            onDone: _handleStreamDone,
          );

      _isTracking = true;
      Helpers.log('Location tracking started', tag: 'LocationService');
    } catch (e) {
      Helpers.logError(e, tag: 'LocationService.startTracking');
      rethrow;
    }
  }

  void stopTracking() {
    if (!_isTracking) return;

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    _lastTrackedPosition = null;

    // Don't close the controller, just stop adding to it
    Helpers.log('Location tracking stopped', tag: 'LocationService');
  }

  void pauseTracking() {
    if (!_isTracking) return;
    _positionStreamSubscription?.pause();
    _isTracking = false;
  }

  void resumeTracking() {
    if (_isTracking) return;
    _positionStreamSubscription?.resume();
    _isTracking = true;
  }

  // ============ HEADING TRACKING ============

  void _startHeadingTracking() {
    _accelerometerSubscription = accelerometerEvents.listen(
      (event) {
        final heading = (180 / pi) * atan2(event.x, event.y);
        _currentHeading = heading >= 0 ? heading : heading + 360;
      },
      onError: (error) {
        Helpers.logError(error, tag: 'LocationService.headingError');
      },
    );
  }

  void _stopHeadingTracking() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  Future<double> getDeviceHeading() async {
    return _currentHeading;
  }

  // ============ POSITION HANDLERS ============

  void _handlePositionUpdate(Position position) {
    _lastPosition = position;
    _lastUpdateTime = DateTime.now();

    _addToHistory(position);
    _trackDistance(position);
    _isGpsEnabled = true;

    // Start heading tracking if not already
    if (_accelerometerSubscription == null) {
      _startHeadingTracking();
    }
  }

  void _handlePositionError(dynamic error) {
    Helpers.logError(error, tag: 'LocationService.positionError');
    // Don't stop tracking on error, just log it
  }

  void _handleStreamDone() {
    _isTracking = false;
    Helpers.log('Position stream closed', tag: 'LocationService');
  }

  // ============ HISTORY MANAGEMENT ============

  void _addToHistory(Position position) {
    _locationHistory.add(position);
    if (_locationHistory.length > _maxHistorySize) {
      _locationHistory.removeAt(0);
    }
  }

  void clearHistory() {
    _locationHistory.clear();
    _totalDistance = 0.0;
    _lastTrackedPosition = null;
  }

  List<Position> getHistorySince(DateTime time) {
    return _locationHistory
        .where((pos) => pos.timestamp.isAfter(time))
        .toList();
  }

  // ============ DISTANCE TRACKING ============

  void _trackDistance(Position position) {
    if (_lastTrackedPosition != null) {
      final distance =
          _geolocator.distanceBetween(
            _lastTrackedPosition!.latitude,
            _lastTrackedPosition!.longitude,
            position.latitude,
            position.longitude,
          ) /
          1000;

      if (distance > 0.005) {
        _totalDistance += distance;
      }
    }

    _lastTrackedPosition = position;
  }

  double getDistanceBetween({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return _geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  double getTotalDistance({bool reset = false}) {
    final distance = _totalDistance;
    if (reset) {
      _totalDistance = 0.0;
      _lastTrackedPosition = null;
    }
    return distance;
  }

  // ============ BEARING ============

  double getBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return _geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  double getHeadingFromSpeed(double speed, double bearing) {
    if (speed < 0.5) return 0.0;
    return bearing;
  }

  // ============ CONVERSION METHODS ============

  LocationModel positionToLocationModel(
    Position position, {
    String? address,
    String? city,
    String? country,
  }) {
    final heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : _currentHeading;

    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed >= 0 ? position.speed : 0.0,
      heading: heading,
      altitude: position.altitude >= 0 ? position.altitude : 0.0,
      address: address,
      city: city,
      country: country,
      timestamp: position.timestamp,
    );
  }

  LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  double getSpeedInKmh(Position position) {
    return position.speed * 3.6;
  }

  double getSpeedInMph(Position position) {
    return position.speed * 2.23694;
  }

  String formatSpeed(Position position, {String unit = AppConstants.speedKmh}) {
    final speed = unit == AppConstants.speedKmh
        ? getSpeedInKmh(position)
        : getSpeedInMph(position);
    return '${speed.toStringAsFixed(1)} ${unit == AppConstants.speedKmh ? 'km/h' : 'mph'}';
  }

  // ============ ACCURACY METHODS ============

  double getHorizontalAccuracy(Position position) {
    return position.accuracy;
  }

  double getVerticalAccuracy(Position position) {
    return position.altitudeAccuracy;
  }

  bool isAccurate(Position position, {double threshold = 20.0}) {
    return position.accuracy < threshold;
  }

  // ============ UTILITY METHODS ============

  double calculateRouteDistance(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      totalDistance += _geolocator.distanceBetween(
        p1.latitude,
        p1.longitude,
        p2.latitude,
        p2.longitude,
      );
    }
    return totalDistance / 1000;
  }

  bool isWithinRadius({
    required double centerLat,
    required double centerLng,
    required double targetLat,
    required double targetLng,
    required double radiusInKm,
  }) {
    final distance = getDistanceBetween(
      lat1: centerLat,
      lon1: centerLng,
      lat2: targetLat,
      lon2: targetLng,
    );
    return distance <= radiusInKm;
  }

  LatLng getMidpoint({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return LatLng((lat1 + lat2) / 2, (lon1 + lon2) / 2);
  }

  LocationBounds getBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LocationBounds(minLat: 0, maxLat: 0, minLng: 0, maxLng: 0);
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LocationBounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }

  // ============ BACKGROUND LOCATION ============

  Future<bool> hasBackgroundPermission() async {
    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  Future<bool> requestBackgroundPermission() async {
    try {
      final status = await Permission.locationAlways.request();
      return status.isGranted;
    } catch (e) {
      Helpers.logError(e, tag: 'LocationService.requestBackgroundPermission');
      return false;
    }
  }

  // ============ SERVICE STATUS ============

  Future<LocationServiceStatus> getServiceStatus() async {
    final permission = await checkPermission();
    final gpsEnabled = await isLocationServiceEnabled();

    return LocationServiceStatus(
      hasPermission: permission.isGranted,
      isGpsEnabled: gpsEnabled,
      isTracking: _isTracking,
      lastUpdateTime: _lastUpdateTime,
      totalDistance: _totalDistance,
    );
  }

  // ============ DISPOSE ============

  void dispose() {
    stopTracking();
    _positionController.close();
    _locationHistory.clear();
    _lastTrackedPosition = null;
    _stopHeadingTracking();
    Helpers.log('LocationService disposed', tag: 'LocationService');
  }
}

// ============ LOCATION SERVICE STATUS ============

class LocationServiceStatus {
  final bool hasPermission;
  final bool isGpsEnabled;
  final bool isTracking;
  final DateTime? lastUpdateTime;
  final double totalDistance;

  LocationServiceStatus({
    required this.hasPermission,
    required this.isGpsEnabled,
    required this.isTracking,
    this.lastUpdateTime,
    this.totalDistance = 0.0,
  });

  bool get isAvailable => hasPermission && isGpsEnabled;

  String get statusMessage {
    if (!hasPermission) return 'Location permission denied';
    if (!isGpsEnabled) return 'GPS is disabled';
    if (!isTracking) return 'Location tracking stopped';
    return 'Location tracking active';
  }
}

// ============ LOCATION BOUNDS ============

class LocationBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  LocationBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  double get centerLat => (minLat + maxLat) / 2;
  double get centerLng => (minLng + maxLng) / 2;
  double get latSpan => maxLat - minLat;
  double get lngSpan => maxLng - minLng;

  bool contains(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  bool containsPoint(LatLng point) {
    return contains(point.latitude, point.longitude);
  }
}

// ============ LOCATION STREAM BUILDER ============

class LocationStreamBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    Position? position,
    LocationModel? location,
    bool isTracking,
    String? error,
  )
  builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final LocationService? service;

  const LocationStreamBuilder({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.service,
  });

  @override
  Widget build(BuildContext context) {
    final locationService = service ?? LocationService();

    return StreamBuilder<Position>(
      stream: locationService.positionStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorWidget ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Location error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        final position = snapshot.data;
        final locationModel = position != null
            ? locationService.positionToLocationModel(position)
            : null;

        return builder(
          context,
          position,
          locationModel,
          locationService.isTracking,
          null,
        );
      },
    );
  }
}

// ============ EXTENSIONS ============

extension LocationServiceExtension on BuildContext {
  LocationService get locationService => LocationService();
}

extension PositionExtension on Position {
  LatLng get toLatLng => LatLng(latitude, longitude);

  double get speedInKmh => speed * 3.6;

  double get speedInMph => speed * 2.23694;

  bool isAccurate({double threshold = 20.0}) => accuracy < threshold;

  String formattedSpeed({String unit = AppConstants.speedKmh}) {
    final speedValue = unit == AppConstants.speedKmh ? speedInKmh : speedInMph;
    return '${speedValue.toStringAsFixed(1)} ${unit == AppConstants.speedKmh ? 'km/h' : 'mph'}';
  }

  String get formattedAccuracy => '±${accuracy.toStringAsFixed(0)}m';

  String get formattedAltitude =>
      altitude > 0 ? '${altitude.toStringAsFixed(0)}m' : 'N/A';

  String get formattedBearing =>
      heading > 0 ? '${heading.toStringAsFixed(0)}°' : 'N/A';

  String get locationString => '$latitude, $longitude';
}
