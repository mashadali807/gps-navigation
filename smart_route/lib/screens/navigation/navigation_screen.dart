import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_route/services/map_services.dart';

import '../../providers/navigation_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
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
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  bool _isFollowingUser = true;
  bool _isLoading = false;
  bool _showStepInstructions = false;
  String? _error;
  bool _isMuted = false;
  bool _isInitialized = false;

  // Live tracking data
  double _currentSpeed = 0.0;
  double _currentDistance = 0.0;
  String _currentAddress = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

    // Use addPostFrameCallback to avoid setState during build
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

      if (widget.route != null) {
        // Use provided route
        navigationProvider.selectRoute(widget.route!);
        navigationProvider.startNavigation();
      } else {
        // Calculate route if not provided
        final origin = locationProvider.currentLatLng;
        await navigationProvider.calculateRoute(
          origin: origin,
          destination: widget.destination,
        );
        navigationProvider.startNavigation();
      }

      // Start listening to position updates
      _listenToPositionUpdates();

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

  void _listenToPositionUpdates() {
    final locationProvider = context.read<LocationProvider>();
    locationProvider.addListener(_onLocationUpdate);
  }

  void _onLocationUpdate() {
    final locationProvider = context.read<LocationProvider>();
    final navigationProvider = context.read<NavigationProvider>();

    if (locationProvider.currentPosition != null) {
      final position = LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );

      _currentSpeed = locationProvider.speed;
      _currentDistance = navigationProvider.remainingDistance;
      _currentAddress = locationProvider.currentAddress ?? 'Current Location';

      navigationProvider.updatePosition(position, speed: _currentSpeed);

      if (_isFollowingUser) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mapController.camera != null && mounted) {
            _mapController.move(position, 15);
          }
        });
      }
    }
  }

  void _centerOnUser() {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition != null) {
      setState(() {
        _isFollowingUser = true;
      });
      final position = LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mapController.camera != null && mounted) {
          _mapController.move(position, 15);
        }
      });
    }
  }

  void _toggleStepInstructions() {
    setState(() {
      _showStepInstructions = !_showStepInstructions;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _endNavigation() {
    final navigationProvider = context.read<NavigationProvider>();
    navigationProvider.stopNavigation();
    context.go('/home');
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navigationProvider = context.watch<NavigationProvider>();
    final locationProvider = context.watch<LocationProvider>();

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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Navigation Error', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Stack(
        children: [
          // Map
          _buildMap(theme, isDark, navigationProvider, locationProvider),

          // Top Navigation Info
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: _buildTopNavigationInfo(theme, isDark, navigationProvider),
          ),

          // Live Tracking Info (Center)
          Positioned(
            top: 140,
            left: 16,
            right: 16,
            child: _buildLiveTrackingInfo(theme, isDark, navigationProvider),
          ),

          // Step Instructions
          if (_showStepInstructions && navigationProvider.currentStep != null)
            Positioned(
              bottom: 200,
              left: 16,
              right: 16,
              child: _buildStepCard(theme, isDark, navigationProvider),
            ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(theme, isDark, navigationProvider),
          ),

          // Compass/Recenter Button
          Positioned(
            bottom: 240,
            right: 16,
            child: _buildRecenterButton(theme, isDark),
          ),

          // Step Toggle Button
          Positioned(
            bottom: 300,
            right: 16,
            child: _buildStepToggleButton(theme, isDark),
          ),

          // Speed Dial
          Positioned(
            bottom: 340,
            left: 16,
            child: _buildSpeedDial(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
    ThemeData theme,
    bool isDark,
    NavigationProvider navigationProvider,
    LocationProvider locationProvider,
  ) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: locationProvider.currentLatLng,
        initialZoom: 15,
        maxZoom: AppConstants.maxMapZoom,
        minZoom: AppConstants.minMapZoom,
        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            setState(() {
              _isFollowingUser = false;
            });
          }
        },
      ),
      children: [
        MapService.getTileLayer(darkMode: isDark),

        // User Marker with Pulse Animation
        if (locationProvider.currentPosition != null)
          MarkerLayer(markers: [_buildUserMarker(locationProvider)]),

        // Route Polyline
        if (navigationProvider.currentRoute != null)
          PolylineLayer(polylines: [navigationProvider.currentRoute!.polyline]),

        // Destination Marker
        MarkerLayer(markers: [_buildDestinationMarker()]),
      ],
    );
  }

  Marker _buildUserMarker(LocationProvider locationProvider) {
    return Marker(
      point: LatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      ),
      width: 80,
      height: 80,
      key: const Key('user_marker'),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Container(
                width: 60 * _pulseAnimation.value,
                height: 60 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
              // Center marker
              Container(
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
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Marker _buildDestinationMarker() {
    return Marker(
      point: widget.destination,
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

  Widget _buildTopNavigationInfo(
    ThemeData theme,
    bool isDark,
    NavigationProvider navigationProvider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTopInfoItem(
            theme,
            Icons.route,
            navigationProvider.formattedRemainingDistance,
            'Distance',
            isDark,
          ),
          _buildTopInfoItem(
            theme,
            Icons.timer,
            navigationProvider.formattedRemainingTime,
            'Time',
            isDark,
          ),
          if (navigationProvider.estimatedArrivalTime != null)
            _buildTopInfoItem(
              theme,
              Icons.alarm,
              navigationProvider.formattedEstimatedArrival,
              'ETA',
              isDark,
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildTopInfoItem(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveTrackingInfo(
    ThemeData theme,
    bool isDark,
    NavigationProvider navigationProvider,
  ) {
    final locationProvider = context.watch<LocationProvider>();

    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          // Progress Bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: navigationProvider.progress,
                        backgroundColor: isDark
                            ? Colors.grey[700]
                            : Colors.grey[200],
                        color: theme.primaryColor,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${navigationProvider.progressPercentage.toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLiveStat(
                theme,
                isDark,
                Icons.speed,
                _currentSpeed > 0
                    ? '${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h'
                    : '0 km/h',
                'Speed',
              ),
              _buildLiveStat(
                theme,
                isDark,
                Icons.route,
                navigationProvider.formattedRemainingDistance,
                'Remaining',
              ),
              _buildLiveStat(
                theme,
                isDark,
                Icons.location_on,
                _currentAddress.isNotEmpty
                    ? _currentAddress.length > 20
                          ? '${_currentAddress.substring(0, 20)}...'
                          : _currentAddress
                    : 'Updating...',
                'Location',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildLiveStat(
    ThemeData theme,
    bool isDark,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(
    ThemeData theme,
    bool isDark,
    NavigationProvider navigationProvider,
  ) {
    final step = navigationProvider.currentStep;
    if (step == null) return const SizedBox.shrink();

    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(step.icon, color: theme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.instruction,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.route,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                step.formattedDistance,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.timer,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                step.formattedDuration,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildBottomControls(
    ThemeData theme,
    bool isDark,
    NavigationProvider navigationProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusExtraLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Next instruction
          if (navigationProvider.nextInstruction != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: Row(
                children: [
                  Icon(Icons.turn_right, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      navigationProvider.nextInstruction!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (navigationProvider.nextInstructionDistance > 0)
                    Text(
                      AppConstants.formatDistance(
                        navigationProvider.nextInstructionDistance,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Control buttons
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  theme,
                  Icons.close,
                  'End',
                  _endNavigation,
                  isDark,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlButton(
                  theme,
                  Icons.location_searching,
                  'Recenter',
                  _centerOnUser,
                  isDark,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlButton(
                  theme,
                  Icons.info_outline,
                  'Steps',
                  _toggleStepInstructions,
                  isDark,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlButton(
                  theme,
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  _isMuted ? 'Unmute' : 'Mute',
                  _toggleMute,
                  isDark,
                  color: _isMuted ? Colors.grey : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onPressed,
    bool isDark, {
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color ?? theme.primaryColor),
      label: Text(
        label,
        style: TextStyle(
          color: color ?? theme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: (color ?? theme.primaryColor).withOpacity(0.1),
        foregroundColor: color ?? theme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.paddingSmall,
          horizontal: AppConstants.paddingSmall,
        ),
        minimumSize: const Size(0, 40),
      ),
    );
  }

  Widget _buildRecenterButton(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _centerOnUser,
        icon: Icon(
          _isFollowingUser ? Icons.gps_fixed : Icons.gps_off,
          color: _isFollowingUser ? Colors.blue : null,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildStepToggleButton(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _toggleStepInstructions,
        icon: Icon(
          _showStepInstructions ? Icons.close : Icons.info_outline,
          color: isDark ? Colors.white : Colors.black87,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSpeedDial(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.speed, color: theme.primaryColor, size: 20),
          const SizedBox(height: 2),
          Text(
            _currentSpeed > 0
                ? '${(_currentSpeed * 3.6).toStringAsFixed(1)}'
                : '0',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'km/h',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ NAVIGATION ROUTE EXTENSION ============

extension NavigationRoute on BuildContext {
  void navigateToNavigation({required LatLng destination, RouteModel? route}) {
    go('/navigation', extra: {'destination': destination, 'route': route});
  }
}
