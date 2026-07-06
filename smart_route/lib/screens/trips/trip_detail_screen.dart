import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:smart_route/services/map_services.dart';

import '../../providers/trip_provider.dart';
import '../../providers/map_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../models/trip_model.dart';
import '../../models/place_model.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  final TripModel? trip;

  const TripDetailScreen({super.key, required this.tripId, this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  TripModel? _trip;
  bool _isLoading = false;
  String? _error;
  bool _showMap = true;
  bool _showWaypoints = true;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  Future<void> _loadTrip() async {
    if (widget.trip != null) {
      setState(() {
        _trip = widget.trip;
      });
      _displayTripOnMap();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tripProvider = context.read<TripProvider>();
      final trip = await tripProvider.getTripById(widget.tripId);

      setState(() {
        _trip = trip;
        _isLoading = false;
      });

      if (trip != null) {
        _displayTripOnMap();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _displayTripOnMap() {
    if (_trip == null) return;

    final mapProvider = context.read<MapProvider>();

    // Clear previous markers and polylines
    mapProvider.clearMarkers();
    mapProvider.clearPolylines();

    // Add origin marker
    if (_trip!.origin != null) {
      final originMarker = Marker(
        point: LatLng(_trip!.origin!.latitude, _trip!.origin!.longitude),
        width: 40,
        height: 40,
        key: const Key('origin'),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
      );
      mapProvider.addMarker(originMarker);
    }

    // Add destination marker
    if (_trip!.destination != null) {
      final destMarker = Marker(
        point: LatLng(
          _trip!.destination!.latitude,
          _trip!.destination!.longitude,
        ),
        width: 40,
        height: 40,
        key: const Key('destination'),
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
      );
      mapProvider.addMarker(destMarker);
    }

    // Add waypoint markers
    for (int i = 0; i < _trip!.waypoints.length; i++) {
      final waypoint = _trip!.waypoints[i];
      final marker = Marker(
        point: LatLng(waypoint.latitude, waypoint.longitude),
        width: 40,
        height: 40,
        key: Key('waypoint_${waypoint.id}'),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
      mapProvider.addMarker(marker);
    }

    // Create route polyline from points
    if (_trip!.metadata?['route_points'] != null) {
      final points = (_trip!.metadata!['route_points'] as List)
          .map((p) => LatLng(p['lat'] ?? 0, p['lng'] ?? 0))
          .toList();

      if (points.isNotEmpty) {
        final polyline = Polyline(
          points: points,
          color: Colors.blue,
          strokeWidth: 4,
          borderStrokeWidth: 1,
          borderColor: Colors.white.withOpacity(0.3),
        );
        mapProvider.addPolyline(polyline);
      }
    }

    // Zoom to fit all points
    final allPoints = <LatLng>[];
    if (_trip!.origin != null) {
      allPoints.add(LatLng(_trip!.origin!.latitude, _trip!.origin!.longitude));
    }
    if (_trip!.destination != null) {
      allPoints.add(
        LatLng(_trip!.destination!.latitude, _trip!.destination!.longitude),
      );
    }
    for (final waypoint in _trip!.waypoints) {
      allPoints.add(LatLng(waypoint.latitude, waypoint.longitude));
    }

    if (allPoints.isNotEmpty) {
      final bounds = _getBounds(allPoints);
      mapProvider.zoomToFitBounds(bounds);
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
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

    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    return LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }

  void _toggleMap() {
    setState(() {
      _showMap = !_showMap;
    });
  }

  void _toggleWaypoints() {
    setState(() {
      _showWaypoints = !_showWaypoints;
    });
  }

  Future<void> _deleteTrip() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final tripProvider = context.read<TripProvider>();
        await tripProvider.deleteTrip(widget.tripId);

        if (mounted) {
          context.go('/trips');
        }
      } catch (e) {
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

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading trip details...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
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
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadTrip, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_trip == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Trip not found', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'The trip you\'re looking for doesn\'t exist',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/trips'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _trip!.tripName ?? 'Trip Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/trips');
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: _toggleMap,
            icon: Icon(_showMap ? Icons.map_rounded : Icons.map_outlined),
          ),
          IconButton(
            onPressed: _toggleWaypoints,
            icon: Icon(
              _showWaypoints ? Icons.timeline_outlined : Icons.timeline,
            ),
          ),
          IconButton(
            onPressed: _deleteTrip,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map (if shown)
          if (_showMap) _buildMap(theme, isDark),

          // Trip Info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                children: [
                  // Trip Summary Card
                  _buildTripSummary(theme, isDark),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Route Details
                  _buildRouteDetails(theme, isDark),

                  const SizedBox(height: AppConstants.paddingLarge),

                  // Waypoints
                  if (_showWaypoints && _trip!.waypoints.isNotEmpty)
                    _buildWaypoints(theme, isDark),

                  if (_showWaypoints && _trip!.waypoints.isNotEmpty)
                    const SizedBox(height: AppConstants.paddingLarge),

                  // Trip Notes
                  if (_trip!.notes != null && _trip!.notes!.isNotEmpty)
                    _buildNotes(theme, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(ThemeData theme, bool isDark) {
    final mapProvider = context.watch<MapProvider>();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCenter:
              mapProvider.currentCenter ??
              const LatLng(
                AppConstants.defaultMapLatitude,
                AppConstants.defaultMapLongitude,
              ),
          initialZoom: mapProvider.currentZoom,
          maxZoom: AppConstants.maxMapZoom,
          minZoom: AppConstants.minMapZoom,
        ),
        children: [
          MapService.getTileLayer(darkMode: isDark),

          if (mapProvider.markers.isNotEmpty)
            MarkerLayer(markers: mapProvider.markers),

          if (mapProvider.polylines.isNotEmpty)
            PolylineLayer(polylines: mapProvider.polylines),
        ],
      ),
    );
  }

  Widget _buildTripSummary(ThemeData theme, bool isDark) {
    return GlassmorphicCard(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            children: [
              // Trip Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_trip!.icon, color: _trip!.typeColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _trip!.typeDisplayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _trip!.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _trip!.statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _trip!.statusIcon,
                          color: _trip!.statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _trip!.status.toString().split('.').last,
                          style: TextStyle(
                            color: _trip!.statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Route
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _trip!.originName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _trip!.destinationName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    theme,
                    Icons.route,
                    _trip!.formattedDistance,
                    'Distance',
                    isDark,
                  ),
                  _buildStatItem(
                    theme,
                    Icons.timer,
                    _trip!.formattedDuration,
                    'Duration',
                    isDark,
                  ),
                  _buildStatItem(
                    theme,
                    Icons.calendar_today,
                    _trip!.tripDate,
                    'Date',
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium)
        .slideY(begin: 0.2, end: 0, duration: AppConstants.durationMedium);
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
        Icon(icon, color: theme.primaryColor, size: 20),
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

  Widget _buildRouteDetails(ThemeData theme, bool isDark) {
    return GlassmorphicCard(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Route Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              if (_trip!.averageSpeed != null)
                _buildDetailRow(
                  theme,
                  isDark,
                  'Average Speed',
                  _trip!.formattedAverageSpeed ?? 'N/A',
                  Icons.speed,
                ),

              if (_trip!.maxSpeed != null)
                _buildDetailRow(
                  theme,
                  isDark,
                  'Max Speed',
                  _trip!.formattedMaxSpeed ?? 'N/A',
                  Icons.speed,
                ),

              if (_trip!.fuelConsumed != null)
                _buildDetailRow(
                  theme,
                  isDark,
                  'Fuel Consumed',
                  '${_trip!.fuelConsumed!.toStringAsFixed(1)} L',
                  Icons.local_gas_station,
                ),

              if (_trip!.fuelEfficiency != null)
                _buildDetailRow(
                  theme,
                  isDark,
                  'Fuel Efficiency',
                  _trip!.formattedFuelEfficiency ?? 'N/A',
                  Icons.speed,
                ),

              if (_trip!.fuelCost != null)
                _buildDetailRow(
                  theme,
                  isDark,
                  'Fuel Cost',
                  _trip!.formattedFuelCost ?? 'N/A',
                  Icons.attach_money,
                ),

              if (_trip!.tollCost != null)
                _buildDetailRow(
                  theme,
                  isDark,
                  'Toll Cost',
                  _trip!.formattedTollCost ?? 'N/A',
                  Icons.toll,
                ),

              if (_trip!.totalCost != null)
                _buildDetailRow(
                  theme,
                  isDark,
                  'Total Cost',
                  _trip!.formattedTotalCost ?? 'N/A',
                  Icons.payments,
                ),

              _buildDetailRow(
                theme,
                isDark,
                'Start Time',
                _trip!.tripTime,
                Icons.play_arrow,
              ),

              if (_trip!.endTime != null)
                _buildDetailRow(
                  theme,
                  isDark,
                  'End Time',
                  Helpers.formatTime(_trip!.endTime!),
                  Icons.stop,
                ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 200.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: AppConstants.durationMedium,
          delay: 200.ms,
        );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    bool isDark,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaypoints(ThemeData theme, bool isDark) {
    return GlassmorphicCard(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Waypoints (${_trip!.waypoints.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              ..._trip!.waypoints.asMap().entries.map((entry) {
                final index = entry.key;
                final waypoint = entry.value;
                return _buildWaypointItem(
                  theme,
                  isDark,
                  waypoint,
                  index,
                  index == _trip!.waypoints.length - 1,
                );
              }),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 400.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: AppConstants.durationMedium,
          delay: 400.ms,
        );
  }

  Widget _buildWaypointItem(
    ThemeData theme,
    bool isDark,
    TripWaypoint waypoint,
    int index,
    bool isLast,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Index circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: waypoint.isVisited ? Colors.green : theme.primaryColor,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    waypoint.name ?? 'Waypoint ${index + 1}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (waypoint.address != null)
                    Text(
                      waypoint.address!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Arrival: ${waypoint.formattedArrivalTime}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      if (waypoint.stopDuration != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.pause,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stop: ${waypoint.stopDurationString}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (waypoint.isVisited)
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Visited at ${waypoint.formattedDepartureTime ?? 'N/A'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Container(
              height: 20,
              width: 1,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
          ),
        if (!isLast) const SizedBox(height: AppConstants.paddingSmall),
      ],
    );
  }

  Widget _buildNotes(ThemeData theme, bool isDark) {
    return GlassmorphicCard(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.note, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Notes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                child: Text(_trip!.notes!, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 600.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: AppConstants.durationMedium,
          delay: 600.ms,
        );
  }
}
