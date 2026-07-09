import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:smart_route/services/location_services.dart';
import 'package:smart_route/services/map_services.dart';
import 'dart:async';

import '../core/constants/app_constants.dart';
import '../models/location_model.dart';
import '../models/place_model.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  // ============ STATE VARIABLES ============

  Position? _currentPosition;
  LocationModel? _currentLocation;
  PlaceModel? _currentPlace;
  bool _isLoading = false;
  bool _isTracking = false;
  bool _isFollowingUser = true;
  String? _error;
  String? _currentAddress;
  double _heading = 0.0;
  double _speed = 0.0;
  double _accuracy = 0.0;
  double _altitude = 0.0;
  double _bearing = 0.0;
  DateTime? _lastUpdateTime;

  // GPS Status
  bool _isGpsEnabled = false;
  bool _hasPermission = false;
  String? _gpsStatusMessage;

  // History
  List<LocationModel> _locationHistory = [];
  int _maxHistorySize = 100;

  // Stream subscriptions
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  // Compass
  double _compassHeading = 0.0;
  bool _isCompassAvailable = false;

  // Distance tracking
  double _totalDistanceTraveled = 0.0;
  LatLng? _lastTrackedPosition;

  // ============ GETTERS ============

  Position? get currentPosition => _currentPosition;
  LocationModel? get currentLocation => _currentLocation;
  PlaceModel? get currentPlace => _currentPlace;
  bool get isLoading => _isLoading;
  bool get isTracking => _isTracking;
  bool get isFollowingUser => _isFollowingUser;
  String? get error => _error;
  String? get currentAddress => _currentAddress;
  double get heading => _heading;
  double get speed => _speed;
  double get accuracy => _accuracy;
  double get altitude => _altitude;
  double get bearing => _bearing;
  DateTime? get lastUpdateTime => _lastUpdateTime;
  bool get isGpsEnabled => _isGpsEnabled;
  bool get hasPermission => _hasPermission;
  String? get gpsStatusMessage => _gpsStatusMessage;
  List<LocationModel> get locationHistory => _locationHistory;
  double get totalDistanceTraveled => _totalDistanceTraveled;
  double get compassHeading => _compassHeading;
  bool get isCompassAvailable => _isCompassAvailable;

  // ============ INITIALIZATION ============

  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      // Check and request permissions
      await _checkPermissions();

      if (_hasPermission) {
        // Check if GPS is enabled
        await _checkGpsStatus();

        if (_isGpsEnabled) {
          // Get current position
          await _getCurrentPosition();

          // Start tracking
          await startTracking();

          // Start listening to GPS status
          _listenToGpsStatus();
        }
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  // ============ PERMISSION METHODS ============

  Future<void> _checkPermissions() async {
    try {
      final status = await Permission.location.status;

      if (status.isDenied) {
        final result = await Permission.location.request();
        _hasPermission = result.isGranted;
      } else if (status.isPermanentlyDenied) {
        _hasPermission = false;
        _error =
            'Location permission permanently denied. Please enable from settings.';
        _gpsStatusMessage = _error;
      } else {
        _hasPermission = status.isGranted;
      }

      if (_hasPermission) {
        final backgroundStatus = await Permission.locationAlways.status;
        if (!backgroundStatus.isGranted) {
          // Optionally request background permission
        }
      }

      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> requestPermission() async {
    try {
      final status = await Permission.location.request();
      _hasPermission = status.isGranted;

      if (_hasPermission) {
        await _checkGpsStatus();
        if (_isGpsEnabled) {
          await _getCurrentPosition();
          await startTracking();
        }
      }

      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _checkGpsStatus() async {
    try {
      _isGpsEnabled = await Geolocator.isLocationServiceEnabled();

      if (!_isGpsEnabled) {
        _gpsStatusMessage = 'GPS is disabled. Please enable GPS.';
        _error = _gpsStatusMessage;
      } else {
        _gpsStatusMessage = 'GPS is enabled';
        _error = null;
      }

      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> openGpsSettings() async {
    await Geolocator.openLocationSettings();
  }

  void _listenToGpsStatus() {
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      ServiceStatus status,
    ) {
      _isGpsEnabled = status == ServiceStatus.enabled;
      if (_isGpsEnabled) {
        _gpsStatusMessage = 'GPS is enabled';
        _error = null;
        _getCurrentPosition();
        startTracking();
      } else {
        _gpsStatusMessage = 'GPS is disabled';
        _error = _gpsStatusMessage;
        stopTracking();
      }
      notifyListeners();
    });
  }

  // ============ LOCATION METHODS ============

  Future<void> _getCurrentPosition() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _updatePosition(position);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> updateCurrentPosition() async {
    await _getCurrentPosition();
  }

  void _updatePosition(Position position) {
    _currentPosition = position;
    _speed = position.speed;
    _accuracy = position.accuracy;
    _altitude = position.altitude;
    _bearing = position.heading;
    _lastUpdateTime = position.timestamp;

    _currentLocation = _locationService.positionToLocationModel(
      position,
      address: _currentAddress,
    );

    _currentPlace = PlaceModel.currentLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: _currentAddress,
    );

    _getAddressFromPosition(position);
    _trackDistance(position);

    if (_currentLocation != null) {
      _addToHistory(_currentLocation!);
    }

    // CRITICAL: Notify listeners so UI updates
    notifyListeners();
  }

  Future<void> _getAddressFromPosition(Position position) async {
    try {
      _currentAddress = await MapService.getAddressFromCoordinates(
        LatLng(position.latitude, position.longitude),
      );

      if (_currentLocation != null) {
        _currentLocation = _currentLocation!.copyWith(address: _currentAddress);
        _currentPlace = PlaceModel.currentLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: _currentAddress,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _trackDistance(Position position) {
    final currentPoint = LatLng(position.latitude, position.longitude);

    if (_lastTrackedPosition != null) {
      final distance = Helpers.calculateDistance(
        lat1: _lastTrackedPosition!.latitude,
        lon1: _lastTrackedPosition!.longitude,
        lat2: currentPoint.latitude,
        lon2: currentPoint.longitude,
      );

      if (distance > 0.005) {
        _totalDistanceTraveled += distance;
      }
    }

    _lastTrackedPosition = currentPoint;
  }

  void _addToHistory(LocationModel location) {
    _locationHistory.add(location);
    if (_locationHistory.length > _maxHistorySize) {
      _locationHistory.removeAt(0);
    }
  }

  // ============ TRACKING METHODS ============

  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      if (!_hasPermission || !_isGpsEnabled) {
        throw Exception(
          'Cannot start tracking: permission or GPS not available',
        );
      }

      _isTracking = true;
      _locationService.startTracking();

      _positionStreamSubscription = _locationService.positionStream.listen(
        (Position position) {
          _updatePosition(position);
        },
        onError: (error) {
          _handleError(error);
        },
      );

      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  void stopTracking() {
    if (!_isTracking) return;

    _isTracking = false;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _locationService.stopTracking();

    notifyListeners();
  }

  void toggleTracking() {
    if (_isTracking) {
      stopTracking();
    } else {
      startTracking();
    }
  }

  // ============ MAP CONTROL METHODS ============

  void toggleFollowUser() {
    _isFollowingUser = !_isFollowingUser;
    notifyListeners();
  }

  void updateHeading(double newHeading) {
    _heading = newHeading;
    notifyListeners();
  }

  void updateCompassHeading(double heading) {
    _compassHeading = heading;
    _isCompassAvailable = true;
    notifyListeners();
  }

  // ============ SEARCH METHODS ============

  Future<List<SearchResult>> searchLocation(String query) async {
    try {
      return await MapService.searchLocation(query);
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  Future<String> getAddressFromCoordinates(LatLng position) async {
    try {
      return await MapService.getAddressFromCoordinates(position);
    } catch (e) {
      _handleError(e);
      return 'Unknown location';
    }
  }

  // ============ DISTANCE CALCULATION ============

  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Helpers.calculateDistance(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
  }

  double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Helpers.calculateBearing(
      lat1: lat1,
      lon1: lon1,
      lat2: lat2,
      lon2: lon2,
    );
  }

  double distanceToCurrentLocation({required double lat, required double lon}) {
    if (_currentPosition == null) return 0;
    return calculateDistance(
      lat1: _currentPosition!.latitude,
      lon1: _currentPosition!.longitude,
      lat2: lat,
      lon2: lon,
    );
  }

  // ============ LOCATION HISTORY ============

  void clearHistory() {
    _locationHistory.clear();
    _totalDistanceTraveled = 0.0;
    _lastTrackedPosition = null;
    notifyListeners();
  }

  List<LocationModel> getHistorySince(DateTime time) {
    return _locationHistory
        .where((location) => location.timestamp.isAfter(time))
        .toList();
  }

  // ============ UTILITY METHODS ============

  void resetDistance() {
    _totalDistanceTraveled = 0.0;
    _lastTrackedPosition = null;
    notifyListeners();
  }

  LatLng get currentLatLng {
    if (_currentPosition == null) {
      return const LatLng(
        AppConstants.defaultMapLatitude,
        AppConstants.defaultMapLongitude,
      );
    }
    return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
  }

  bool get isLocationAvailable {
    return _currentPosition != null && _hasPermission && _isGpsEnabled;
  }

  String get formattedPosition {
    if (_currentPosition == null) return 'No location';
    return '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
  }

  String get formattedSpeed {
    if (_speed <= 0) return '0 km/h';
    return '${(_speed * 3.6).toStringAsFixed(1)} km/h';
  }

  String get formattedAccuracy {
    if (_accuracy <= 0) return 'N/A';
    return '${_accuracy.toStringAsFixed(0)} m';
  }

  String get formattedAltitude {
    if (_altitude <= 0) return 'N/A';
    return '${_altitude.toStringAsFixed(0)} m';
  }

  String get formattedBearing {
    if (_bearing <= 0) return 'N/A';
    return '${_bearing.toStringAsFixed(0)}°';
  }

  String get formattedDistance {
    return AppConstants.formatDistance(_totalDistanceTraveled);
  }

  String get formattedLastUpdate {
    if (_lastUpdateTime == null) return 'Never';
    return Helpers.timeAgo(_lastUpdateTime!);
  }

  // ============ PRIVATE HELPER METHODS ============

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    _gpsStatusMessage = null;
    notifyListeners();
  }

  void _handleError(dynamic error) {
    _error = error.toString();
    _isLoading = false;
    notifyListeners();
    Helpers.logError(error, tag: 'LocationProvider');
  }

  // ============ DISPOSE ============

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    stopTracking();
    super.dispose();
  }
}

// ============ LOCATION PROVIDER EXTENSIONS ============

extension LocationProviderExtension on BuildContext {
  LocationProvider get location =>
      Provider.of<LocationProvider>(this, listen: false);

  LocationProvider get watchLocation =>
      Provider.of<LocationProvider>(this, listen: true);

  LatLng get currentLatLng => watchLocation.currentLatLng;
  bool get isLocationAvailable => watchLocation.isLocationAvailable;
  String get formattedPosition => watchLocation.formattedPosition;
  String? get currentAddress => watchLocation.currentAddress;
  String get formattedSpeed => watchLocation.formattedSpeed;
}

// ============ LOCATION PERMISSION HELPER ============

class LocationPermissionHelper {
  static Future<bool> checkPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<bool> isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<void> openGpsSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await Helpers.showPermissionDialog(
      context,
      title: 'Location Permission Required',
      message:
          'This app needs location access to provide GPS tracking and navigation features.',
    );
  }

  static Future<bool> showGpsDialog(BuildContext context) async {
    return await Helpers.showPermissionDialog(
      context,
      title: 'Enable GPS',
      message: 'Please enable GPS to use location services.',
    );
  }
}

// ============ LOCATION STREAM BUILDER ============

class LocationStreamBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    Position? position,
    LocationModel? location,
    bool isLoading,
    String? error,
  )
  builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const LocationStreamBuilder({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();

    if (locationProvider.isLoading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (locationProvider.error != null) {
      return errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  locationProvider.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => locationProvider.initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    return builder(
      context,
      locationProvider.currentPosition,
      locationProvider.currentLocation,
      locationProvider.isLoading,
      locationProvider.error,
    );
  }
}
