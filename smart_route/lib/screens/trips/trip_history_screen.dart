import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/trip_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/trip_model.dart';
import 'trip_detail_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  String _selectedFilter = AppConstants.filterToday;
  bool _isLoading = false;
  String? _error;

  List<TripModel> _trips = [];
  List<TripModel> _filteredTrips = [];

  final List<String> _filters = [
    AppConstants.filterToday,
    AppConstants.filterWeek,
    AppConstants.filterMonth,
    AppConstants.filterYear,
  ];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tripProvider = context.read<TripProvider>();

      // Load trips using the provider's load method
      await tripProvider.loadTrips();

      // Get trips from the provider using the getter
      setState(() {
        _trips = tripProvider.trips;
        _filterTrips();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTrips() {
    final now = DateTime.now();

    setState(() {
      switch (_selectedFilter) {
        case AppConstants.filterToday:
          _filteredTrips = _trips
              .where(
                (trip) =>
                    trip.startTime.year == now.year &&
                    trip.startTime.month == now.month &&
                    trip.startTime.day == now.day,
              )
              .toList();
          break;

        case AppConstants.filterWeek:
          final weekAgo = now.subtract(const Duration(days: 7));
          _filteredTrips = _trips
              .where((trip) => trip.startTime.isAfter(weekAgo))
              .toList();
          break;

        case AppConstants.filterMonth:
          final monthAgo = now.subtract(const Duration(days: 30));
          _filteredTrips = _trips
              .where((trip) => trip.startTime.isAfter(monthAgo))
              .toList();
          break;

        case AppConstants.filterYear:
          final yearAgo = now.subtract(const Duration(days: 365));
          _filteredTrips = _trips
              .where((trip) => trip.startTime.isAfter(yearAgo))
              .toList();
          break;

        default:
          _filteredTrips = _trips;
      }

      // Sort by date (most recent first)
      _filteredTrips.sort((a, b) => b.startTime.compareTo(a.startTime));
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterTrips();
    });
  }

  void _navigateToTripDetail(TripModel trip) {
    context.go('/trip/${trip.id}', extra: {'trip': trip});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Trip History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            // Check if there's a previous route to go back to
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If no previous route, go to home
              context.go('/home');
            }
          },
        ),
        actions: [
          if (_trips.isNotEmpty)
            IconButton(onPressed: _loadTrips, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(theme, isDark),

          // Content
          Expanded(child: _buildContent(theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingMedium,
      ),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = filter == _selectedFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectFilter(filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingSmall,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor
                      : isDark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return Center(
        child: LoadingWidget(
          message: 'Loading trips...',
          style: LoadingStyle.spinner,
        ),
      );
    }

    if (_error != null) {
      return Center(
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
            ElevatedButton(onPressed: _loadTrips, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_trips.isEmpty) {
      return _buildEmptyState(theme, isDark);
    }

    if (_filteredTrips.isEmpty) {
      return _buildNoTripsForFilter(theme, isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      itemCount: _filteredTrips.length,
      itemBuilder: (context, index) {
        final trip = _filteredTrips[index];
        return _buildTripItem(theme, isDark, trip, index);
      },
    );
  }

  Widget _buildTripItem(
    ThemeData theme,
    bool isDark,
    TripModel trip,
    int index,
  ) {
    return GlassmorphicCard(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          onTap: () => _navigateToTripDetail(trip),
          child: Column(
            children: [
              Row(
                children: [
                  // Trip Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: trip.typeColor.withOpacity(0.1),
                    ),
                    child: Icon(trip.icon, color: trip.typeColor, size: 22),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),

                  // Trip Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.tripName ?? 'Trip',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.route,
                              size: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip.formattedDistance,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip.formattedDuration,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip.tripDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              trip.tripTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: trip.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: trip.statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      trip.status.toString().split('.').last,
                      style: TextStyle(
                        color: trip.statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // From/To
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.originName,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.destinationName,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: AppConstants.durationMedium,
          delay: Duration(milliseconds: index * 50),
        )
        .slideX(
          begin: 0.2,
          end: 0,
          duration: AppConstants.durationMedium,
          delay: Duration(milliseconds: index * 50),
        );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            'No Trips Yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Your trip history will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton.icon(
            onPressed: _loadTrips,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTripsForFilter(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_off,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            'No Trips for $_selectedFilter',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Try selecting a different filter',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton.icon(
            onPressed: () => _selectFilter(AppConstants.filterToday),
            icon: const Icon(Icons.clear),
            label: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }
}
