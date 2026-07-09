import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_route/services/map_services.dart';

import '../../providers/navigation_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/route_model.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng destination;
  final RouteModel? route;

  const NavigationScreen({super.key, required this.destination, this.route});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  late MapController _mapController;
  bool _isFollowingUser = true;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Live tracking data
  double _currentSpeed = 0.0;
  String _currentAddress = '';
  double _currentDistance = 0.0;

  // User position for map updates
  LatLng? _currentUserPosition;

  // Track user's path (green line)
  List<LatLng> _userPath = [];

  // Last position for drawing path
  LatLng? _lastPosition;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Flag to prevent multiple updates
  bool _isUpdating = false;

  // FIXED: Store current zoom level to prevent unwanted zoom changes
  double _currentZoom = 15.0;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNavigation();
    });
  }

  Future<void> _initializeNavigation() async {
    if (_isInitialized) return;
    _isInitialized = true;

    setState(() => _isLoading = true);

    try {
      final navigationProvider = context.read<NavigationProvider>();
      final locationProvider = context.read<LocationProvider>();

      if (!locationProvider.isLocationAvailable) {
        await locationProvider.initialize();

        int attempts = 0;
        while (locationProvider.currentPosition == null && attempts < 50) {
          await Future.delayed(const Duration(milliseconds: 300));
          attempts++;
        }

        if (locationProvider.currentPosition == null) {
          throw Exception('Unable to get current location. Please enable GPS.');
        }
      }

      if (locationProvider.currentPosition != null) {
        _currentUserPosition = LatLng(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
        _currentSpeed = locationProvider.speed;
        _currentAddress = locationProvider.currentAddress ?? 'Current Location';

        _userPath.add(_currentUserPosition!);
        _lastPosition = _currentUserPosition;
      }

      if (widget.route != null) {
        navigationProvider.selectRoute(widget.route!);
        navigationProvider.startNavigation();
      } else {
        if (locationProvider.currentPosition != null) {
          final origin = LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
          await navigationProvider.calculateRoute(
            origin: origin,
            destination: widget.destination,
          );
          navigationProvider.startNavigation();
        } else {
          throw Exception('Location not available');
        }
      }

      if (!locationProvider.isTracking) {
        await locationProvider.startTracking();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navigationProvider = context.watch<NavigationProvider>();
    final locationProvider = context.watch<LocationProvider>();

    if (locationProvider.currentPosition != null && !_isUpdating) {
      _isUpdating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateLocation(locationProvider, navigationProvider);
          _isUpdating = false;
        }
      });
    }

    if (_currentUserPosition == null && !_isLoading && _error == null) {
      return _buildLoadingScreen(theme);
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: LoadingWidget(
            message: 'Preparing navigation...',
            style: LoadingStyle.spinner,
          ),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorScreen(theme);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(theme, isDark, navigationProvider, locationProvider),

          // Top Safe Area Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Colors.black.withOpacity(0.7)
                        : Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top Info Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildTopCard(theme, isDark, navigationProvider),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSheet(theme, isDark),
          ),
        ],
      ),
    );
  }

  void _updateLocation(
    LocationProvider locationProvider,
    NavigationProvider navigationProvider,
  ) {
    if (locationProvider.currentPosition == null) return;

    final position = LatLng(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
    );

    _currentUserPosition = position;
    _currentSpeed = locationProvider.speed;
    _currentAddress = locationProvider.currentAddress ?? 'Current Location';
    _currentDistance = navigationProvider.remainingDistance;

    bool positionChanged = false;
    if (_lastPosition != null) {
      final distance = MapService.calculateDistance(_lastPosition!, position);
      final distanceInMeters = distance * 1000;
      if (distanceInMeters > 1.0) {
        positionChanged = true;
      }
    } else {
      positionChanged = true;
    }

    if (positionChanged) {
      setState(() {
        _userPath.add(position);
        _lastPosition = position;
      });

      navigationProvider.updatePosition(position, speed: _currentSpeed);

      // FIXED: Only move map if following user AND user is not interacting
      if (_isFollowingUser && mounted && !_isUserInteracting) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _mapController.camera != null) {
            try {
              // FIXED: Use the current zoom level instead of forcing 15
              _mapController.move(position, _currentZoom);
            } catch (e) {
              print('Error moving map: $e');
            }
          }
        });
      }
    }
  }

  void _centerOnUser() {
    if (_currentUserPosition != null) {
      setState(() {
        _isFollowingUser = true;
        _isUserInteracting = false;
        // FIXED: Reset zoom to 15 when centering
        _currentZoom = 15.0;
      });

      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _mapController.camera != null) {
          try {
            _mapController.move(_currentUserPosition!, _currentZoom);
          } catch (e) {
            print('Error centering map: $e');
          }
        }
      });
    }
  }

  void _endNavigation() {
    final navigationProvider = context.read<NavigationProvider>();
    final mapProvider = context.read<MapProvider>();

    navigationProvider.stopNavigation();
    mapProvider.clearRoute();
    context.go('/home');
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ============ UI BUILDERS ============

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.3),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Getting Your Location',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enable GPS and ensure you have network connection',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initializeNavigation();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final locationProvider = context.read<LocationProvider>();
                      await locationProvider.openGpsSettings();
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Open GPS'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(ThemeData theme) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.withOpacity(0.1),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[300],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Navigation Error',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home, size: 18),
                    label: const Text('Go Home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initializeNavigation();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap(
    ThemeData theme,
    bool isDark,
    NavigationProvider navigationProvider,
    LocationProvider locationProvider,
  ) {
    final userPosition = _currentUserPosition ?? locationProvider.currentLatLng;

    if (userPosition == const LatLng(0, 0) || userPosition == null) {
      return Container(
        color: isDark ? Colors.grey[900]! : Colors.grey[200]!,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final polylines = <Polyline>[];

    if (navigationProvider.currentRoute != null) {
      final route = navigationProvider.currentRoute!;
      polylines.add(
        Polyline(
          points: route.points,
          color: const Color(0xFF4A90D9),
          strokeWidth: 5,
          borderStrokeWidth: 1,
          borderColor: Colors.blue.withOpacity(0.3),
        ),
      );
    }

    if (_userPath.length > 1) {
      polylines.add(
        Polyline(
          points: List.from(_userPath),
          color: Colors.green,
          strokeWidth: 5,
          borderStrokeWidth: 1,
          borderColor: Colors.green.withOpacity(0.3),
        ),
      );
    }

    return FlutterMap(
      key: ValueKey('map_${_userPath.length}'),
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userPosition,
        initialZoom: _currentZoom,
        maxZoom: AppConstants.maxMapZoom,
        minZoom: AppConstants.minMapZoom,
        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            // FIXED: Store the current zoom level when user interacts
            _currentZoom = position.zoom ?? 15.0;

            setState(() {
              _isFollowingUser = false;
            });
          }
        },
        onMapReady: () {
          if (_currentUserPosition != null) {
            _mapController.move(_currentUserPosition!, _currentZoom);
          }
        },
      ),
      children: [
        MapService.getTileLayer(darkMode: isDark, satellite: false),
        MarkerLayer(markers: [_buildDestinationMarker()]),
        if (_currentUserPosition != null)
          MarkerLayer(markers: [_buildUserMarker()]),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
      ],
    );
  }

  Marker _buildUserMarker() {
    if (_currentUserPosition == null) {
      return Marker(
        point: const LatLng(0, 0),
        width: 60,
        height: 60,
        key: const Key('user_marker'),
        child: const SizedBox(),
      );
    }

    return Marker(
      point: _currentUserPosition!,
      width: 60,
      height: 60,
      key: Key(
        'user_marker_${_currentUserPosition!.latitude}_${_currentUserPosition!.longitude}',
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 50 * _pulseAnimation.value,
                  height: 50 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.15),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Marker _buildDestinationMarker() {
    return Marker(
      point: widget.destination,
      width: 40,
      height: 40,
      key: const Key('destination_marker'),
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
        child: const Icon(Icons.flag, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildTopCard(
    ThemeData theme,
    bool isDark,
    NavigationProvider navigationProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[850]!.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoChip(
            theme,
            Icons.route,
            navigationProvider.formattedRemainingDistance,
            'Distance',
            isDark,
          ),
          _buildInfoChip(
            theme,
            Icons.timer,
            navigationProvider.formattedRemainingTime,
            'Time',
            isDark,
          ),
          if (navigationProvider.estimatedArrivalTime != null)
            _buildInfoChip(
              theme,
              Icons.alarm,
              navigationProvider.formattedEstimatedArrival,
              'ETA',
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.primaryColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850]! : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip(
                theme,
                Icons.speed,
                _currentSpeed > 0
                    ? '${(_currentSpeed * 3.6).toStringAsFixed(0)}'
                    : '0',
                'km/h',
                isDark,
                Colors.blue,
              ),
              _buildStatChip(
                theme,
                Icons.route,
                _currentDistance > 0
                    ? AppConstants.formatDistance(_currentDistance)
                    : '--',
                'Remaining',
                isDark,
                Colors.green,
              ),
              _buildStatChip(
                theme,
                Icons.location_on,
                _currentAddress.isNotEmpty
                    ? _currentAddress.length > 12
                          ? '${_currentAddress.substring(0, 12)}...'
                          : _currentAddress
                    : 'Updating...',
                'Location',
                isDark,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _centerOnUser,
                  icon: Icon(
                    _isFollowingUser ? Icons.gps_fixed : Icons.gps_off,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text('Recenter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowingUser
                        ? Colors.blue
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _endNavigation,
                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                  label: const Text('End Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    bool isDark,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

extension NavigationRoute on BuildContext {
  void navigateToNavigation({required LatLng destination, RouteModel? route}) {
    go('/navigation', extra: {'destination': destination, 'route': route});
  }
}
