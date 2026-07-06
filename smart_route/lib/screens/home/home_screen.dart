import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:smart_route/services/map_services.dart';

import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/auth_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/place_model.dart';
import '../../models/route_model.dart';

import 'widget/map_controls.dart';
import 'widget/location_info.dart';
import 'widget/quick_action.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isFollowingUser = true;
  bool _isMapReady = false;
  bool _showQuickActions = true;
  bool _showLocationInfo = true;
  bool _isLoading = false;

  // Destination tracking
  LatLng? _destination;
  PlaceModel? _destinationPlace;
  bool _hasDestination = false;

  // Route calculation
  bool _isCalculatingRoute = false;
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
      _checkForDestination();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _initializeMap() async {
    final locationProvider = context.read<LocationProvider>();
    final mapProvider = context.read<MapProvider>();

    setState(() => _isLoading = true);

    try {
      if (!locationProvider.isLocationAvailable) {
        await locationProvider.initialize();
      }

      await mapProvider.initialize(center: locationProvider.currentLatLng);

      if (locationProvider.isLocationAvailable &&
          !locationProvider.isTracking) {
        await locationProvider.startTracking();
      }

      setState(() {
        _isMapReady = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize map: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkForDestination() {
    final mapProvider = context.read<MapProvider>();
    final selectedPlace = mapProvider.selectedPlace;

    if (selectedPlace != null && selectedPlace.hasCoordinates) {
      setState(() {
        _destination = LatLng(selectedPlace.latitude, selectedPlace.longitude);
        _destinationPlace = selectedPlace;
        _hasDestination = true;
        _isFollowingUser = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mapController.camera != null) {
          _mapController.move(_destination!, 15);
        }
      });

      _calculateRouteMetrics();
    }
  }

  Future<void> _calculateRouteMetrics() async {
    if (_destination == null) return;

    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition == null) return;

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final origin = LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );

      final routeData = await MapService.getRoute(
        start: origin,
        end: _destination!,
        profile: 'driving',
      );

      setState(() {
        _routeDistance = routeData.distance;
        _routeDuration = routeData.duration;
        _isCalculatingRoute = false;
      });
    } catch (e) {
      final distance = Helpers.calculateDistance(
        lat1: locationProvider.currentPosition!.latitude,
        lon1: locationProvider.currentPosition!.longitude,
        lat2: _destination!.latitude,
        lon2: _destination!.longitude,
      );

      final avgSpeed = 30.0;
      final duration = (distance / avgSpeed) * 60;

      setState(() {
        _routeDistance = distance;
        _routeDuration = duration;
        _isCalculatingRoute = false;
      });
    }
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _isFollowingUser = false;
      });
    }
  }

  void _centerOnUser() {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition != null) {
      setState(() {
        _isFollowingUser = true;
        _hasDestination = false;
        _destination = null;
        _destinationPlace = null;
        _routeDistance = 0.0;
        _routeDuration = 0.0;
      });
      context.read<MapProvider>().clearSelection();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mapController.camera != null) {
          _mapController.move(
            LatLng(
              locationProvider.currentPosition!.latitude,
              locationProvider.currentPosition!.longitude,
            ),
            15,
          );
        }
      });
    }
  }

  void _navigateToSearch() {
    context.go('/search');
  }

  void _navigateToProfile() {
    context.go('/profile');
  }

  void _navigateToTrips() {
    context.go('/trips');
  }

  void _showSavedPlaces() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved places feature coming soon!')),
    );
  }

  void _onQuickActionTap(QuickAction action) {
    switch (action) {
      case QuickAction.search:
        _navigateToSearch();
        break;
      case QuickAction.saved:
        _showSavedPlaces();
        break;
      case QuickAction.trips:
        _navigateToTrips();
        break;
      case QuickAction.profile:
        _navigateToProfile();
        break;
    }
  }

  void _startNavigation() {
    if (_destination == null) return;

    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final origin = LatLng(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude,
    );

    final originPlace = PlaceModel.currentLocation(
      latitude: origin.latitude,
      longitude: origin.longitude,
      address: locationProvider.currentAddress,
    );

    final route = RouteModel(
      points: [origin, _destination!],
      distance: _routeDistance > 0 ? _routeDistance : 0,
      duration: _routeDuration > 0 ? _routeDuration : 0,
      origin: originPlace,
      destination:
          _destinationPlace ??
          PlaceModel(
            name: 'Destination',
            latitude: _destination!.latitude,
            longitude: _destination!.longitude,
          ),
    );

    context.go('/route-preview', extra: {'route': route});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locationProvider = context.watch<LocationProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          if (_isMapReady)
            _buildMap(theme, locationProvider)
          else
            _buildLoadingState(theme),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(theme, isDark, authProvider),
          ),

          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: _buildSearchBar(theme, isDark),
          ),

          Positioned(bottom: 180, right: 16, child: _buildMapControls(theme)),

          if (_showLocationInfo && locationProvider.isLocationAvailable)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildLocationInfo(theme, isDark, locationProvider),
            ),

          if (_showQuickActions)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: _buildQuickActions(theme, isDark),
            ),

          Positioned(bottom: 240, left: 16, child: _buildNavigationFab(theme)),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: LoadingWidget(
                  message: 'Loading map...',
                  style: LoadingStyle.spinner,
                ),
              ),
            ),

          // Destination Info Banner (when destination is set)
          if (_hasDestination && _destination != null)
            Positioned(
              top: 140,
              left: 16,
              right: 16,
              child: _buildDestinationBanner(theme, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(ThemeData theme, LocationProvider locationProvider) {
    final mapProvider = context.watch<MapProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: locationProvider.currentLatLng,
        initialZoom: AppConstants.defaultMapZoom,
        maxZoom: AppConstants.maxMapZoom,
        minZoom: AppConstants.minMapZoom,
        onPositionChanged: _onMapPositionChanged,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        MapService.getTileLayer(darkMode: isDark),

        if (locationProvider.currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  locationProvider.currentPosition!.latitude,
                  locationProvider.currentPosition!.longitude,
                ),
                width: 60,
                height: 60,
                child: _buildUserMarker(),
              ),
            ],
          ),

        if (_hasDestination && _destination != null)
          MarkerLayer(markers: [_buildDestinationMarker()]),

        if (mapProvider.routePolyline != null)
          PolylineLayer(polylines: [mapProvider.routePolyline!]),

        if (mapProvider.markers.isNotEmpty)
          MarkerLayer(markers: mapProvider.markers),
      ],
    );
  }

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.my_location, color: Colors.white, size: 24),
    );
  }

  Marker _buildDestinationMarker() {
    return Marker(
      point: _destination!,
      width: 50,
      height: 50,
      key: const Key('destination_marker'),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.flag, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildDestinationBanner(ThemeData theme, bool isDark) {
    final locationProvider = context.watch<LocationProvider>();

    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Flag Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.2),
            ),
            child: const Icon(Icons.flag, color: Colors.red, size: 16),
          ),
          const SizedBox(width: 8),

          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _destinationPlace?.name ?? 'Destination Set',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (locationProvider.currentPosition != null) ...[
                  const SizedBox(height: 1),
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.route,
                        size: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      Text(
                        _isCalculatingRoute
                            ? 'Calculating...'
                            : _routeDistance > 0
                            ? AppConstants.formatDistance(_routeDistance)
                            : '--',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      Icon(
                        Icons.timer,
                        size: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      Text(
                        _isCalculatingRoute
                            ? 'Calculating...'
                            : _routeDuration > 0
                            ? AppConstants.formatDuration(_routeDuration)
                            : '--',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Navigate Button
          ElevatedButton(
            onPressed: _isCalculatingRoute ? null : _startNavigation,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: _isCalculatingRoute
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Go',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
          ),

          const SizedBox(width: 2),

          // Close Button
          IconButton(
            onPressed: () {
              setState(() {
                _hasDestination = false;
                _destination = null;
                _destinationPlace = null;
                _routeDistance = 0.0;
                _routeDuration = 0.0;
                _isFollowingUser = true;
              });
              context.read<MapProvider>().clearSelection();
              _centerOnUser();
            },
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white70 : Colors.black54,
              size: 16,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingWidget(size: 50, style: LoadingStyle.spinner),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            'Loading map...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool isDark, AuthProvider authProvider) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark
                      ? Colors.black.withOpacity(0.8)
                      : Colors.white.withOpacity(0.9),
                  isDark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.white.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: Icon(
                    Icons.menu,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                GestureDetector(
                  onTap: _navigateToProfile,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.primaryColor.withOpacity(0.2),
                    backgroundImage: authProvider.currentUser?.photoUrl != null
                        ? NetworkImage(authProvider.currentUser!.photoUrl!)
                        : null,
                    child: authProvider.currentUser?.photoUrl == null
                        ? Text(
                            authProvider.currentUser?.initials ?? 'U',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: GlassmorphicCard(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            borderRadius: AppConstants.radiusLarge,
            isAnimated: false,
            child: GestureDetector(
              onTap: _navigateToSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(
                      Icons.search,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search destination...',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: AppConstants.fontSizeMedium,
                        ),
                      ),
                    ),
                    if (context.watch<LocationProvider>().isLocationAvailable)
                      IconButton(
                        onPressed: _centerOnUser,
                        icon: Icon(
                          _isFollowingUser ? Icons.gps_fixed : Icons.gps_off,
                          color: _isFollowingUser
                              ? theme.primaryColor
                              : isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapControls(ThemeData theme) {
    return Column(
      children: [
        MapControls(
          onLocateMe: _centerOnUser,
          onCompass: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_mapController.camera != null) {
                _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom,
                );
                _mapController.rotate(0);
              }
            });
          },
          onZoomIn: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_mapController.camera != null) {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                  _mapController.camera.center,
                  currentZoom + 1,
                );
              }
            });
          },
          onZoomOut: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_mapController.camera != null) {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                  _mapController.camera.center,
                  currentZoom - 1,
                );
              }
            });
          },
          isFollowing: _isFollowingUser,
        ),
      ],
    );
  }

  Widget _buildLocationInfo(
    ThemeData theme,
    bool isDark,
    LocationProvider locationProvider,
  ) {
    return AnimatedOpacity(
      opacity: _showLocationInfo ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: LocationInfoWidget(
        location: locationProvider.currentLocation,
        address: locationProvider.currentAddress,
        speed: locationProvider.speed,
        accuracy: locationProvider.accuracy,
        onTap: () {
          setState(() {
            _showLocationInfo = !_showLocationInfo;
          });
        },
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: QuickActionsWidget(
            onActionTap: _onQuickActionTap,
            onShowMore: () {
              // Show more actions
            },
          ),
        );
      },
    );
  }

  Widget _buildNavigationFab(ThemeData theme) {
    final mapProvider = context.watch<MapProvider>();

    if (mapProvider.currentRoute == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          if (mapProvider.currentRoute != null) {
            context.go(
              '/route-preview',
              extra: {'route': mapProvider.currentRoute!},
            );
          }
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.navigation, color: Colors.white),
      ),
    );
  }
}

// ============ ROUTE NAVIGATION EXTENSIONS ============

extension HomeRoute on BuildContext {
  void navigateToHome() {
    go('/home');
  }

  void navigateToHomeAndClearStack() {
    go('/home');
  }
}
