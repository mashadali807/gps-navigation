import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:smart_route/services/storage_services.dart';
import 'package:smart_route/services/supabase_services.dart';
import 'dart:async';

import '../models/trip_model.dart';
import '../models/route_model.dart';
import '../models/place_model.dart';
import '../models/location_model.dart';

import '../core/constants/app_constants.dart';

class TripProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final SupabaseService _supabaseService = SupabaseService();

  // ============ STATE VARIABLES ============

  List<TripModel> _trips = [];
  List<TripModel> _filteredTrips = [];
  TripModel? _currentTrip;
  TripModel? _activeTrip;

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;

  String _currentFilter = AppConstants.filterToday;
  TripStatus? _statusFilter;
  TripType? _typeFilter;

  TripStatistics? _statistics;

  // ============ GETTERS ============

  List<TripModel> get trips => _filteredTrips;
  List<TripModel> get allTrips => _trips;
  TripModel? get currentTrip => _currentTrip;
  TripModel? get activeTrip => _activeTrip;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  String get currentFilter => _currentFilter;
  TripStatus? get statusFilter => _statusFilter;
  TripType? get typeFilter => _typeFilter;
  TripStatistics? get statistics => _statistics;

  int get totalTrips => _trips.length;
  int get filteredTripsCount => _filteredTrips.length;
  bool get hasTrips => _trips.isNotEmpty;
  bool get hasActiveTrip => _activeTrip != null;

  // ============ INITIALIZATION ============

  // Empty constructor - no notifyListeners() here
  TripProvider() {
    // Initialize without calling notifyListeners
  }

  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      await loadTrips();
      await _loadActiveTrip();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  // ============ TRIP LOADING ============

  /// Load all trips from local storage and sync with Supabase
  Future<void> loadTrips() async {
    try {
      _setLoading(true);
      _clearError();

      // Load from local storage first
      final localTrips = await _storageService.getAllTrips();
      _trips = localTrips;
      _applyFilters();

      // Sync with Supabase in background
      _syncTripsWithSupabase();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Sync trips with Supabase
  Future<void> _syncTripsWithSupabase() async {
    try {
      _isSyncing = true;
      notifyListeners();

      // Get trips from Supabase
      final supabaseTrips = await _supabaseService.getTrips();

      // Merge with local trips
      final mergedTrips = _mergeTrips(_trips, supabaseTrips);

      // Save merged trips locally
      await _storageService.saveTrips(mergedTrips);

      _trips = mergedTrips;
      _applyFilters();

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      Helpers.logError(e, tag: 'TripProvider._syncTripsWithSupabase');
      _isSyncing = false;
    }
  }

  /// Merge local and Supabase trips
  List<TripModel> _mergeTrips(
    List<TripModel> localTrips,
    List<TripModel> supabaseTrips,
  ) {
    final merged = <TripModel>[];
    final localMap = {for (var t in localTrips) t.id: t};
    final supabaseMap = {for (var t in supabaseTrips) t.id: t};

    final allIds = {...localMap.keys, ...supabaseMap.keys};

    for (final id in allIds) {
      final local = localMap[id];
      final supabase = supabaseMap[id];

      if (local != null && supabase != null) {
        if (local.updatedAt != null && supabase.updatedAt != null) {
          merged.add(
            local.updatedAt!.isAfter(supabase.updatedAt!) ? local : supabase,
          );
        } else if (local.updatedAt != null) {
          merged.add(local);
        } else if (supabase.updatedAt != null) {
          merged.add(supabase);
        } else {
          merged.add(supabase);
        }
      } else if (local != null) {
        merged.add(local);
      } else if (supabase != null) {
        merged.add(supabase);
      }
    }

    merged.sort((a, b) => b.startTime.compareTo(a.startTime));
    return merged;
  }

  // ============ ACTIVE TRIP ============

  /// Load active trip from storage
  Future<void> _loadActiveTrip() async {
    try {
      final activeTrip = await _storageService.getData('active_trip');
      if (activeTrip != null) {
        _activeTrip = TripModel.fromHiveMap(activeTrip as Map<String, dynamic>);
      }
    } catch (e) {
      Helpers.logError(e, tag: 'TripProvider._loadActiveTrip');
    }
  }

  /// Start a new trip
  Future<void> startTrip({
    required PlaceModel origin,
    required PlaceModel destination,
    required double distance,
    required double duration,
    TripType type = TripType.driving,
    List<TripWaypoint>? waypoints,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final trip = TripModel.currentTrip(
        origin: origin,
        destination: destination,
        distance: distance,
        duration: duration,
        type: type,
      );

      if (waypoints != null) {
        for (final waypoint in waypoints) {
          trip.addWaypoint(waypoint);
        }
      }

      _activeTrip = trip;
      await _storageService.saveData('active_trip', trip.toHiveMap());

      _trips.insert(0, trip);
      await _storageService.saveTrip(trip);
      await _supabaseService.saveTrip(trip);

      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Update active trip
  Future<void> updateActiveTrip(TripModel trip) async {
    try {
      _activeTrip = trip;
      await _storageService.saveData('active_trip', trip.toHiveMap());

      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
        await _storageService.saveTrip(trip);
        await _supabaseService.updateTrip(trip);
      }

      _applyFilters();
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Complete active trip
  Future<void> completeActiveTrip({
    LocationModel? endLocation,
    double? averageSpeed,
    double? maxSpeed,
    double? fuelConsumed,
    double? fuelCost,
    double? tollCost,
  }) async {
    if (_activeTrip == null) return;

    try {
      _setLoading(true);
      _clearError();

      final completedTrip = _activeTrip!.completeTrip(
        endLocation: endLocation,
        averageSpeed: averageSpeed,
        maxSpeed: maxSpeed,
        fuelConsumed: fuelConsumed,
        fuelCost: fuelCost,
        tollCost: tollCost,
      );

      final index = _trips.indexWhere((t) => t.id == completedTrip.id);
      if (index != -1) {
        _trips[index] = completedTrip;
        await _storageService.saveTrip(completedTrip);
        await _supabaseService.updateTrip(completedTrip);
      }

      _activeTrip = null;
      await _storageService.deleteData('active_trip');

      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Cancel active trip
  Future<void> cancelActiveTrip({String? reason}) async {
    if (_activeTrip == null) return;

    try {
      final cancelledTrip = _activeTrip!.cancelTrip(reason: reason);

      final index = _trips.indexWhere((t) => t.id == cancelledTrip.id);
      if (index != -1) {
        _trips[index] = cancelledTrip;
        await _storageService.saveTrip(cancelledTrip);
        await _supabaseService.updateTrip(cancelledTrip);
      }

      _activeTrip = null;
      await _storageService.deleteData('active_trip');

      _applyFilters();
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  // ============ TRIP CRUD OPERATIONS ============

  /// Get trip by ID
  Future<TripModel?> getTripById(String id) async {
    try {
      final localTrip = _trips.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Trip not found'),
      );

      try {
        final supabaseTrip = await _supabaseService.getTrip(id);
        if (supabaseTrip != null) {
          final index = _trips.indexWhere((t) => t.id == id);
          if (index != -1) {
            _trips[index] = supabaseTrip;
            await _storageService.saveTrip(supabaseTrip);
          }
          _applyFilters();
          notifyListeners();
          return supabaseTrip;
        }
      } catch (e) {
        return localTrip;
      }

      return localTrip;
    } catch (e) {
      Helpers.logError(e, tag: 'TripProvider.getTripById');
      return null;
    }
  }

  /// Save trip
  Future<void> saveTrip(TripModel trip) async {
    try {
      _setLoading(true);
      _clearError();

      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
      } else {
        _trips.insert(0, trip);
      }

      await _storageService.saveTrip(trip);
      await _supabaseService.saveTrip(trip);

      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Save multiple trips
  Future<void> saveTrips(List<TripModel> trips) async {
    try {
      _setLoading(true);
      _clearError();

      for (final trip in trips) {
        final index = _trips.indexWhere((t) => t.id == trip.id);
        if (index != -1) {
          _trips[index] = trip;
        } else {
          _trips.add(trip);
        }
      }

      await _storageService.saveTrips(trips);

      for (final trip in trips) {
        await _supabaseService.saveTrip(trip);
      }

      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Update trip
  Future<void> updateTrip(TripModel trip) async {
    try {
      _setLoading(true);
      _clearError();

      final index = _trips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _trips[index] = trip;
        await _storageService.saveTrip(trip);
        await _supabaseService.updateTrip(trip);
      }

      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Delete trip
  Future<void> deleteTrip(String id) async {
    try {
      _setLoading(true);
      _clearError();

      _trips.removeWhere((t) => t.id == id);
      await _storageService.deleteTrip(id);
      await _supabaseService.deleteTrip(id);

      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Delete multiple trips
  Future<void> deleteTrips(List<String> ids) async {
    try {
      _setLoading(true);
      _clearError();

      _trips.removeWhere((t) => ids.contains(t.id));

      for (final id in ids) {
        await _storageService.deleteTrip(id);
        await _supabaseService.deleteTrip(id);
      }

      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Clear all trips
  Future<void> clearAllTrips() async {
    try {
      _setLoading(true);
      _clearError();

      _trips.clear();
      _filteredTrips.clear();
      await _storageService.clearAllTrips();
      await _supabaseService.clearTrips();

      _applyFilters();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  // ============ FILTERING ============

  void _applyFilters() {
    var filtered = List<TripModel>.from(_trips);

    final now = DateTime.now();
    switch (_currentFilter) {
      case AppConstants.filterToday:
        filtered = filtered
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
        filtered = filtered
            .where((trip) => trip.startTime.isAfter(weekAgo))
            .toList();
        break;

      case AppConstants.filterMonth:
        final monthAgo = now.subtract(const Duration(days: 30));
        filtered = filtered
            .where((trip) => trip.startTime.isAfter(monthAgo))
            .toList();
        break;

      case AppConstants.filterYear:
        final yearAgo = now.subtract(const Duration(days: 365));
        filtered = filtered
            .where((trip) => trip.startTime.isAfter(yearAgo))
            .toList();
        break;

      default:
        break;
    }

    if (_statusFilter != null) {
      filtered = filtered
          .where((trip) => trip.status == _statusFilter!)
          .toList();
    }

    if (_typeFilter != null) {
      filtered = filtered.where((trip) => trip.type == _typeFilter!).toList();
    }

    filtered.sort((a, b) => b.startTime.compareTo(a.startTime));

    _filteredTrips = filtered;
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setStatusFilter(TripStatus? status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  void setTypeFilter(TripType? type) {
    _typeFilter = type;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _currentFilter = AppConstants.filterToday;
    _statusFilter = null;
    _typeFilter = null;
    _applyFilters();
    notifyListeners();
  }

  // ============ STATISTICS ============

  void calculateStatistics() {
    _statistics = TripStatistics.fromTrips(_trips);
    notifyListeners();
  }

  TripStatistics? getFilteredStatistics() {
    if (_filteredTrips.isEmpty) return null;
    return TripStatistics.fromTrips(_filteredTrips);
  }

  TripStatistics? getStatisticsByDateRange(DateTime from, DateTime to) {
    final filtered = _trips
        .where(
          (trip) => trip.startTime.isAfter(from) && trip.startTime.isBefore(to),
        )
        .toList();
    if (filtered.isEmpty) return null;
    return TripStatistics.fromTrips(filtered);
  }

  // ============ TRIP FROM ROUTE ============

  Future<TripModel?> createTripFromRoute({
    required RouteModel route,
    required DateTime startTime,
    DateTime? endTime,
    double? averageSpeed,
    double? maxSpeed,
    double? fuelConsumed,
    double? fuelCost,
    double? tollCost,
    String? notes,
  }) async {
    try {
      final trip = TripModel.fromRoute(
        route,
        startTime: startTime,
        endTime: endTime,
        averageSpeed: averageSpeed,
        maxSpeed: maxSpeed,
        fuelConsumed: fuelConsumed,
        fuelCost: fuelCost,
        tollCost: tollCost,
        notes: notes,
      );

      await saveTrip(trip);
      return trip;
    } catch (e) {
      _handleError(e);
      return null;
    }
  }

  // ============ SEARCH ============

  List<TripModel> searchTrips(String query) {
    if (query.isEmpty) return _filteredTrips;

    final lowerQuery = query.toLowerCase();
    return _filteredTrips
        .where(
          (trip) =>
              trip.tripName?.toLowerCase().contains(lowerQuery) == true ||
              trip.originName.toLowerCase().contains(lowerQuery) ||
              trip.destinationName.toLowerCase().contains(lowerQuery) ||
              trip.notes?.toLowerCase().contains(lowerQuery) == true,
        )
        .toList();
  }

  // ============ EXPORT ============

  Future<String> exportTrips() async {
    try {
      final jsonList = _trips.map((trip) => trip.toJson()).toList();
      return jsonList.toString();
    } catch (e) {
      _handleError(e);
      return '';
    }
  }

  Future<String> exportTripsToCsv() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln(
        'ID,Name,Origin,Destination,Distance,Duration,Status,Type,StartTime,EndTime',
      );

      for (final trip in _trips) {
        buffer.writeln(
          '${trip.id},'
          '${trip.tripName ?? ''},'
          '${trip.originName},'
          '${trip.destinationName},'
          '${trip.distance},'
          '${trip.duration},'
          '${trip.status},'
          '${trip.type},'
          '${trip.startTime.toIso8601String()},'
          '${trip.endTime?.toIso8601String() ?? ''}',
        );
      }

      return buffer.toString();
    } catch (e) {
      _handleError(e);
      return '';
    }
  }

  // ============ PRIVATE HELPERS ============

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
    Helpers.logError(error, tag: 'TripProvider');
  }

  // ============ DISPOSE ============

  @override
  void dispose() {
    super.dispose();
  }
}

// ============ TRIP PROVIDER EXTENSIONS ============

extension TripProviderExtension on BuildContext {
  TripProvider get trip => Provider.of<TripProvider>(this, listen: false);

  TripProvider get watchTrip => Provider.of<TripProvider>(this, listen: true);

  List<TripModel> get trips => watchTrip.trips;
  TripModel? get activeTrip => watchTrip.activeTrip;
  bool get hasTrips => watchTrip.hasTrips;
  bool get hasActiveTrip => watchTrip.hasActiveTrip;
  int get totalTrips => watchTrip.totalTrips;
}

// ============ TRIP PROVIDER CONSUMER ============

class TripProviderConsumer extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    TripProvider provider,
    List<TripModel> trips,
    bool isLoading,
    String? error,
  )
  builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;

  const TripProviderConsumer({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return errorWidget ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadTrips(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
        }

        if (provider.trips.isEmpty) {
          return emptyWidget ??
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No trips found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
        }

        return builder(
          context,
          provider,
          provider.trips,
          provider.isLoading,
          provider.error,
        );
      },
    );
  }
}
