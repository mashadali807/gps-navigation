import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_route/services/map_services.dart';

import '../../providers/navigation_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/route_model.dart';
import 'navigation_screen.dart';

class RoutePreviewScreen extends StatefulWidget {
  final RouteModel route;
  final List<RouteModel>? alternativeRoutes;

  const RoutePreviewScreen({
    super.key,
    required this.route,
    this.alternativeRoutes,
  });

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  late RouteModel _selectedRoute;
  int _selectedRouteIndex = 0;
  bool _isLoading = false;
  bool _showAlternatives = false;

  @override
  void initState() {
    super.initState();
    _selectedRoute = widget.route;

    // Add route to map
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = context.read<MapProvider>();
      mapProvider.setRoutePolyline(_selectedRoute.polyline);

      // Zoom to fit route
      if (_selectedRoute.points.isNotEmpty) {
        final bounds = _getRouteBounds(_selectedRoute.points);
        mapProvider.zoomToFitBounds(bounds);
      }
    });
  }

  LatLngBounds _getRouteBounds(List<LatLng> points) {
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

    // Add padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding), // southWest
      LatLng(maxLat + latPadding, maxLng + lngPadding), // northEast
    );
  }

  void _selectRoute(int index) {
    setState(() {
      _selectedRouteIndex = index;
      _selectedRoute = widget.alternativeRoutes![index];
      _showAlternatives = false;
    });

    final mapProvider = context.read<MapProvider>();
    mapProvider.setRoutePolyline(_selectedRoute.polyline);

    if (_selectedRoute.points.isNotEmpty) {
      final bounds = _getRouteBounds(_selectedRoute.points);
      mapProvider.zoomToFitBounds(bounds);
    }
  }

  void _startNavigation() {
    final navigationProvider = context.read<NavigationProvider>();
    navigationProvider.selectRoute(_selectedRoute);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(
          destination: _selectedRoute.destination != null
              ? LatLng(
                  _selectedRoute.destination!.latitude,
                  _selectedRoute.destination!.longitude,
                )
              : _selectedRoute.points.last,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(theme, isDark),

          // Back Button
          Positioned(top: 40, left: 16, child: _buildBackButton(theme, isDark)),

          // Route Info Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildRouteInfoCard(theme, isDark, size),
          ),

          // Alternative Routes Button
          if (widget.alternativeRoutes != null &&
              widget.alternativeRoutes!.length > 1 &&
              !_showAlternatives)
            Positioned(
              top: 40,
              right: 16,
              child: _buildAlternativesButton(theme, isDark),
            ),

          // Alternative Routes List
          if (_showAlternatives)
            Positioned(
              top: 80,
              right: 16,
              left: 16,
              child: _buildAlternativesList(theme, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(ThemeData theme, bool isDark) {
    final locationProvider = context.watch<LocationProvider>();
    final mapProvider = context.watch<MapProvider>();

    return FlutterMap(
      options: MapOptions(
        initialCenter: locationProvider.currentLatLng,
        initialZoom: 12,
        maxZoom: AppConstants.maxMapZoom,
        minZoom: AppConstants.minMapZoom,
      ),
      children: [
        MapService.getTileLayer(darkMode: isDark),

        // User Marker
        if (locationProvider.currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  locationProvider.currentPosition!.latitude,
                  locationProvider.currentPosition!.longitude,
                ),
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

        // Route Polyline
        if (mapProvider.routePolyline != null)
          PolylineLayer(polylines: [mapProvider.routePolyline!]),

        // Destination Marker
        if (_selectedRoute.points.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedRoute.points.last,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flag, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBackButton(ThemeData theme, bool isDark) {
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
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAlternativesButton(ThemeData theme, bool isDark) {
    return Container(
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
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _showAlternatives = !_showAlternatives;
          });
        },
        icon: Icon(
          _showAlternatives ? Icons.close : Icons.route,
          color: theme.primaryColor,
          size: 18,
        ),
        label: Text(
          _showAlternatives ? 'Close' : 'Alternatives',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAlternativesList(ThemeData theme, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
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
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        shrinkWrap: true,
        children: [
          const Text(
            'Alternative Routes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ...widget.alternativeRoutes!.asMap().entries.map((entry) {
            final index = entry.key;
            final route = entry.value;
            final isSelected = index == _selectedRouteIndex;

            return _buildAlternativeItem(
              theme,
              isDark,
              route,
              index,
              isSelected,
            );
          }),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildAlternativeItem(
    ThemeData theme,
    bool isDark,
    RouteModel route,
    int index,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _selectRoute(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : isDark
              ? Colors.grey[800]
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : isDark
                ? Colors.grey[700]!
                : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? theme.primaryColor
                    : isDark
                    ? Colors.grey[700]
                    : Colors.grey[300],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name ?? 'Route ${index + 1}',
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        route.formattedDistance,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        route.formattedDuration,
                        style: theme.textTheme.bodySmall,
                      ),
                      if (route.trafficDelay != null) ...[
                        const SizedBox(width: AppConstants.paddingSmall),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Icon(Icons.traffic, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '+${route.trafficDelay!.toStringAsFixed(0)} min',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard(ThemeData theme, bool isDark, Size size) {
    return Container(
      width: size.width,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

          const SizedBox(height: AppConstants.paddingLarge),

          // Route Summary
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  theme,
                  Icons.place,
                  'From',
                  _selectedRoute.origin?.name ?? 'Current Location',
                  isDark,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              Expanded(
                child: _buildInfoItem(
                  theme,
                  Icons.flag,
                  'To',
                  _selectedRoute.destination?.name ?? 'Destination',
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Route Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                theme,
                Icons.route,
                _selectedRoute.formattedDistance,
                'Distance',
                isDark,
              ),
              _buildStatItem(
                theme,
                Icons.timer,
                _selectedRoute.formattedDuration,
                'Est. Time',
                isDark,
              ),
              if (_selectedRoute.estimatedArrival != null)
                _buildStatItem(
                  theme,
                  Icons.alarm,
                  _selectedRoute.formattedArrivalTime ?? 'N/A',
                  'ETA',
                  isDark,
                ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Start Navigation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startNavigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.navigation),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Text(
                    'Start Navigation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
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
}
