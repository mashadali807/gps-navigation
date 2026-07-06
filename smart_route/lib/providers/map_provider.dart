import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:smart_route/services/location_services.dart';
import 'package:smart_route/services/map_services.dart';
import 'dart:async';
import 'dart:math';

import '../models/place_model.dart';
import '../models/route_model.dart';
import '../core/constants/app_constants.dart';

class MapProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  // ============ STATE VARIABLES ============

  LatLng? _currentCenter;
  double _currentZoom = AppConstants.defaultMapZoom;
  double _currentRotation = 0.0;
  bool _isLoading = false;
  bool _isMapReady = false;
  String? _error;

  // Map markers
  List<Marker> _markers = [];
  List<Marker> _customMarkers = [];

  // Polylines
  List<Polyline> _polylines = [];
  Polyline? _routePolyline;

  // Route data
  RouteModel? _currentRoute;
  List<RouteModel> _suggestedRoutes = [];

  // Search
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  // Map style
  String _mapStyle = 'standard';
  bool _isDarkMode = false;

  // Map controls
  bool _showTraffic = false;
  bool _showSatellite = false;
  bool _show3D = false;

  // Selected items
  PlaceModel? _selectedPlace;
  SearchResult? _selectedSearchResult;
  Marker? _selectedMarker;

  // Map bounds
  LatLngBounds? _visibleBounds;

  // Animation
  bool _isAnimating = false;

  // Tile providers
  TileLayer? _tileLayer;

  // Stream subscriptions
  StreamSubscription? _mapSubscription;

  // ============ GETTERS ============

  LatLng? get currentCenter => _currentCenter;
  double get currentZoom => _currentZoom;
  double get currentRotation => _currentRotation;
  bool get isLoading => _isLoading;
  bool get isMapReady => _isMapReady;
  String? get error => _error;
  List<Marker> get markers => _markers;
  List<Marker> get customMarkers => _customMarkers;
  List<Polyline> get polylines => _polylines;
  Polyline? get routePolyline => _routePolyline;
  RouteModel? get currentRoute => _currentRoute;
  List<RouteModel> get suggestedRoutes => _suggestedRoutes;
  List<SearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get mapStyle => _mapStyle;
  bool get isDarkMode => _isDarkMode;
  bool get showTraffic => _showTraffic;
  bool get showSatellite => _showSatellite;
  bool get show3D => _show3D;
  PlaceModel? get selectedPlace => _selectedPlace;
  SearchResult? get selectedSearchResult => _selectedSearchResult;
  Marker? get selectedMarker => _selectedMarker;
  LatLngBounds? get visibleBounds => _visibleBounds;
  bool get isAnimating => _isAnimating;

  // ============ INITIALIZATION ============

  Future<void> initialize({LatLng? center}) async {
    try {
      _setLoading(true);
      _clearError();

      _currentCenter =
          center ??
          const LatLng(
            AppConstants.defaultMapLatitude,
            AppConstants.defaultMapLongitude,
          );

      _currentZoom = AppConstants.defaultMapZoom;

      // Initialize tile layer
      _tileLayer = _buildTileLayer();

      _isMapReady = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  // ============ MAP TILE MANAGEMENT ============

  TileLayer _buildTileLayer() {
    return TileLayer(
      urlTemplate: _getTileUrl(),
      userAgentPackageName: AppConstants.packageName,
      maxZoom: AppConstants.maxMapZoom,
      minZoom: AppConstants.minMapZoom,
      tileProvider: NetworkTileProvider(),
      subdomains: ['a', 'b', 'c'],
      additionalOptions: const {'attribution': '© OpenStreetMap contributors'},
    );
  }

  String _getTileUrl() {
    if (_showSatellite) {
      return 'https://tiles.stadiamaps.com/tiles/alidade_satellite/{z}/{x}/{y}{r}.png';
    }

    if (_isDarkMode) {
      return 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png';
    }

    return AppConstants.osmTileUrl;
  }

  void toggleDarkMode(bool isDark) {
    _isDarkMode = isDark;
    _tileLayer = _buildTileLayer();
    notifyListeners();
  }

  void toggleSatelliteView(bool enable) {
    _showSatellite = enable;
    if (enable) {
      _isDarkMode = false;
    }
    _tileLayer = _buildTileLayer();
    notifyListeners();
  }

  void toggleTrafficView(bool enable) {
    _showTraffic = enable;
    notifyListeners();
  }

  void toggle3DView(bool enable) {
    _show3D = enable;
    notifyListeners();
  }

  void setMapStyle(String style) {
    _mapStyle = style;
    _tileLayer = _buildTileLayer();
    notifyListeners();
  }

  // ============ MAP CONTROLS ============

  void moveTo(LatLng position, {double? zoom, bool animated = true}) {
    if (animated) {
      _animateTo(position, zoom: zoom);
    } else {
      _currentCenter = position;
      if (zoom != null) _currentZoom = zoom;
      notifyListeners();
    }
  }

  void animateTo(LatLng position, {double? zoom}) {
    _animateTo(position, zoom: zoom);
  }

  void _animateTo(LatLng position, {double? zoom}) {
    _isAnimating = true;
    _currentCenter = position;
    if (zoom != null) _currentZoom = zoom;
    notifyListeners();

    Future.delayed(
      const Duration(milliseconds: AppConstants.animationDuration),
      () {
        _isAnimating = false;
        notifyListeners();
      },
    );
  }

  void zoomIn() {
    if (_currentZoom < AppConstants.maxMapZoom) {
      _currentZoom = min(_currentZoom + 1, AppConstants.maxMapZoom);
      notifyListeners();
    }
  }

  void zoomOut() {
    if (_currentZoom > AppConstants.minMapZoom) {
      _currentZoom = max(_currentZoom - 1, AppConstants.minMapZoom);
      notifyListeners();
    }
  }

  void rotateMap(double angle) {
    _currentRotation = angle;
    notifyListeners();
  }

  void resetRotation() {
    _currentRotation = 0.0;
    notifyListeners();
  }

  void centerOnCurrentLocation(LatLng position) {
    moveTo(position, zoom: 15);
  }

  void zoomToFitBounds(LatLngBounds bounds, {double padding = 50}) {
    final center = bounds.center;
    final distance = Helpers.calculateDistance(
      lat1: bounds.north,
      lon1: bounds.west,
      lat2: bounds.south,
      lon2: bounds.east,
    );

    double zoom = 15;
    if (distance > 50) zoom = 10;
    if (distance > 100) zoom = 8;
    if (distance > 500) zoom = 6;
    if (distance > 1000) zoom = 4;

    moveTo(center, zoom: zoom);
  }

  // ============ MARKER MANAGEMENT ============

  void addMarker(Marker marker) {
    _markers.add(marker);
    notifyListeners();
  }

  void addMarkers(List<Marker> markers) {
    _markers.addAll(markers);
    notifyListeners();
  }

  void removeMarker(Marker marker) {
    _markers.remove(marker);
    notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  void addCustomMarker(Marker marker) {
    _customMarkers.add(marker);
    notifyListeners();
  }

  void clearCustomMarkers() {
    _customMarkers.clear();
    notifyListeners();
  }

  void selectPlace(PlaceModel place) {
    _selectedPlace = place;
    if (place.hasCoordinates) {
      moveTo(LatLng(place.latitude, place.longitude), zoom: 15);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedPlace = null;
    _selectedSearchResult = null;
    _selectedMarker = null;
    notifyListeners();
  }

  // ============ POLYLINE MANAGEMENT ============

  void addPolyline(Polyline polyline) {
    _polylines.add(polyline);
    notifyListeners();
  }

  void addPolylines(List<Polyline> polylines) {
    _polylines.addAll(polylines);
    notifyListeners();
  }

  void removePolyline(Polyline polyline) {
    _polylines.remove(polyline);
    notifyListeners();
  }

  void clearPolylines() {
    _polylines.clear();
    _routePolyline = null;
    notifyListeners();
  }

  void setRoutePolyline(Polyline polyline) {
    _routePolyline = polyline;
    notifyListeners();
  }

  void clearRoute() {
    _routePolyline = null;
    _currentRoute = null;
    _suggestedRoutes.clear();
    notifyListeners();
  }

  // ============ ROUTE MANAGEMENT ============

  Future<List<RouteModel>> getRoute({
    required LatLng start,
    required LatLng end,
    PlaceModel? origin,
    PlaceModel? destination,
    RouteType type = RouteType.driving,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final routeData = await MapService.getRoute(start: start, end: end);
      final route = RouteModel.fromOSRM(
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
        origin: origin,
        destination: destination,
        type: type,
      );

      _currentRoute = route;
      _routePolyline = route.polyline;

      _setLoading(false);
      notifyListeners();

      return [route];
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  Future<List<RouteModel>> getAlternativeRoutes({
    required LatLng start,
    required LatLng end,
    int alternatives = 3,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final mainRoute = await getRoute(start: start, end: end);
      final alternativesList = <RouteModel>[];

      if (mainRoute.isNotEmpty) {
        final route = mainRoute.first;

        for (int i = 0; i < alternatives - 1; i++) {
          final variation = 1.0 + (i + 1) * 0.1;
          final altRoute = route.copyWith(
            distance: route.distance * variation,
            duration: route.duration * (variation * 0.9),
            name: 'Alternative ${i + 1}',
            metadata: {'is_alternative': true, 'index': i + 1},
          );
          alternativesList.add(altRoute);
        }
      }

      _suggestedRoutes = [mainRoute.first, ...alternativesList];
      _setLoading(false);
      notifyListeners();

      return _suggestedRoutes;
    } catch (e) {
      _handleError(e);
      return [];
    }
  }

  void selectRoute(RouteModel route) {
    _currentRoute = route;
    _routePolyline = route.polyline;
    notifyListeners();
  }

  // ============ SEARCH METHODS ============

  Future<List<SearchResult>> searchLocation(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      _isSearching = false;
      notifyListeners();
      return [];
    }

    try {
      _isSearching = true;
      _clearError();
      notifyListeners();

      _searchResults = await MapService.searchLocation(query);

      _isSearching = false;
      notifyListeners();

      return _searchResults;
    } catch (e) {
      _isSearching = false;
      _handleError(e);
      return [];
    }
  }

  void selectSearchResult(SearchResult result) {
    _selectedSearchResult = result;
    moveTo(LatLng(result.latitude, result.longitude), zoom: 15);
    notifyListeners();
  }

  void clearSearch() {
    _searchResults.clear();
    _isSearching = false;
    _selectedSearchResult = null;
    notifyListeners();
  }

  // ============ VISIBLE BOUNDS ============

  void updateVisibleBounds(LatLngBounds bounds) {
    _visibleBounds = bounds;
    notifyListeners();
  }

  // ============ MAP SNAPSHOT ============

  Future<void> captureMapSnapshot() async {
    print('Map snapshot captured');
  }

  // ============ LOCATION METHODS ============

  Future<String> getAddressFromCoordinates(LatLng position) async {
    try {
      return await MapService.getAddressFromCoordinates(position);
    } catch (e) {
      _handleError(e);
      return 'Unknown location';
    }
  }

  // ============ UTILITY METHODS ============

  void setLoading(bool loading) {
    _setLoading(loading);
  }

  void clearError() {
    _clearError();
  }

  void resetMap() {
    _currentCenter = const LatLng(
      AppConstants.defaultMapLatitude,
      AppConstants.defaultMapLongitude,
    );
    _currentZoom = AppConstants.defaultMapZoom;
    _currentRotation = 0.0;
    clearMarkers();
    clearPolylines();
    clearRoute();
    clearSearch();
    clearSelection();
    _error = null;
    notifyListeners();
  }

  // ============ PRIVATE METHODS ============

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _handleError(dynamic error) {
    _error = error.toString();
    _isLoading = false;
    notifyListeners();
    Helpers.logError(error, tag: 'MapProvider');
  }

  // ============ DISPOSE ============

  @override
  void dispose() {
    _mapSubscription?.cancel();
    super.dispose();
  }
}

// ============ MAP PROVIDER EXTENSIONS ============

extension MapProviderExtension on BuildContext {
  MapProvider get map => Provider.of<MapProvider>(this, listen: false);
  MapProvider get watchMap => Provider.of<MapProvider>(this, listen: true);

  /// Get current map center
  LatLng? get mapCenter => watchMap.currentCenter;

  /// Get current map zoom
  double get mapZoom => watchMap.currentZoom;

  /// Check if map is ready
  bool get isMapReady => watchMap.isMapReady;

  /// Get map markers
  List<Marker> get mapMarkers => watchMap.markers;

  /// Get map polylines
  List<Polyline> get mapPolylines => watchMap.polylines;

  /// Get current route
  RouteModel? get currentRoute => watchMap.currentRoute;
}

// ============ MAP STREAM BUILDER ============

class MapStreamBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isMapReady,
    LatLng? center,
    double zoom,
    String? error,
  )
  builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const MapStreamBuilder({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();

    if (mapProvider.isLoading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (mapProvider.error != null) {
      return errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.route_outlined, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  mapProvider.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => mapProvider.initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    return builder(
      context,
      mapProvider.isMapReady,
      mapProvider.currentCenter,
      mapProvider.currentZoom,
      mapProvider.error,
    );
  }
}

// ============ MAP THEME EXTENSION ============

extension MapStyleExtension on String {
  bool get isDark => this == 'dark';
  bool get isSatellite => this == 'satellite';
  bool get isStandard => this == 'standard';
  bool get isTerrain => this == 'terrain';
}

// ============ LAT LNG EXTENSIONS ============

extension LatLngExtensions on LatLng {
  /// Get distance to another point in kilometers
  double distanceTo(LatLng other) {
    return Helpers.calculateDistance(
      lat1: latitude,
      lon1: longitude,
      lat2: other.latitude,
      lon2: other.longitude,
    );
  }

  /// Get bearing to another point
  double bearingTo(LatLng other) {
    return Helpers.calculateBearing(
      lat1: latitude,
      lon1: longitude,
      lat2: other.latitude,
      lon2: other.longitude,
    );
  }

  /// Get midpoint between two points
  LatLng midpointTo(LatLng other) {
    return LatLng(
      (latitude + other.latitude) / 2,
      (longitude + other.longitude) / 2,
    );
  }

  /// Check if point is within bounds
  bool isWithinBounds(LatLngBounds bounds) {
    return latitude >= bounds.south &&
        latitude <= bounds.north &&
        longitude >= bounds.west &&
        longitude <= bounds.east;
  }

  /// Get formatted string
  String get formatted =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

// ============ LAT LNG BOUNDS EXTENSIONS ============

extension LatLngBoundsExtensions on LatLngBounds {
  /// Get center of bounds
  LatLng get center => LatLng((north + south) / 2, (east + west) / 2);

  /// Get width in degrees
  double get width => east - west;

  /// Get height in degrees
  double get height => north - south;

  /// Check if bounds contain point
  bool contains(LatLng point) {
    return point.latitude >= south &&
        point.latitude <= north &&
        point.longitude >= west &&
        point.longitude <= east;
  }

  /// Expand bounds by padding
  LatLngBounds expand(double padding) {
    return LatLngBounds(
      LatLng(south - padding, west - padding),
      LatLng(north + padding, east + padding),
    );
  }

  /// Shrink bounds by padding
  LatLngBounds shrink(double padding) {
    return LatLngBounds(
      LatLng(south + padding, west + padding),
      LatLng(north - padding, east - padding),
    );
  }

  /// Check if bounds intersect with another bounds
  bool intersects(LatLngBounds other) {
    return !(other.west > east ||
        other.east < west ||
        other.south > north ||
        other.north < south);
  }

  /// Get the union of two bounds
  LatLngBounds union(LatLngBounds other) {
    return LatLngBounds(
      LatLng(
        south < other.south ? south : other.south,
        west < other.west ? west : other.west,
      ),
      LatLng(
        north > other.north ? north : other.north,
        east > other.east ? east : other.east,
      ),
    );
  }

  /// Get the intersection of two bounds
  LatLngBounds? intersection(LatLngBounds other) {
    if (!intersects(other)) return null;

    return LatLngBounds(
      LatLng(
        south > other.south ? south : other.south,
        west > other.west ? west : other.west,
      ),
      LatLng(
        north < other.north ? north : other.north,
        east < other.east ? east : other.east,
      ),
    );
  }

  /// Check if bounds are valid
  bool get isValid => north > south && east > west;

  /// Get area of bounds in square degrees
  double get area => width * height;

  /// Get bounding box as string
  String get formatted =>
      'N: ${north.toStringAsFixed(4)}, S: ${south.toStringAsFixed(4)}, '
      'E: ${east.toStringAsFixed(4)}, W: ${west.toStringAsFixed(4)}';
}

// ============ MAP MARKER BUILDER ============

class MapMarkerBuilder {
  /// Build a default location marker
  static Marker buildLocationMarker({
    required LatLng point,
    required String id,
    Color color = Colors.blue,
    double size = 40,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      key: Key(id),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  /// Build a destination marker
  static Marker buildDestinationMarker({
    required LatLng point,
    required String id,
    double size = 40,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      key: Key(id),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.flag, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  /// Build a custom marker with text
  static Marker buildTextMarker({
    required LatLng point,
    required String id,
    required String label,
    Color color = Colors.blue,
    double size = 40,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      key: Key(id),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a custom marker with any widget
  static Marker buildCustomMarker({
    required LatLng point,
    required String id,
    required Widget child,
    double size = 40,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      key: Key(id),
      child: GestureDetector(onTap: onTap, child: child),
    );
  }

  /// Build a marker with an image
  static Marker buildImageMarker({
    required LatLng point,
    required String id,
    required ImageProvider image,
    double size = 40,
    VoidCallback? onTap,
    BoxFit fit = BoxFit.cover,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      key: Key(id),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: image, fit: fit),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
