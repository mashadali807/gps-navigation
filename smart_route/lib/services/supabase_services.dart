import 'package:flutter/material.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/place_model.dart';
import '../models/trip_model.dart';
import '../models/route_model.dart';

class SupabaseService {
  final SupabaseClient _client = SupabaseConfig.client;

  // ============ TABLES ============

  static const String _usersTable = 'users';
  static const String _placesTable = 'saved_places';
  static const String _tripsTable = 'trip_history';
  static const String _routesTable = 'routes';
  static const String _settingsTable = 'user_settings';
  static const String _favoritesTable = 'favorite_locations';

  // Channel references for realtime subscriptions
  RealtimeChannel? _userChannel;
  RealtimeChannel? _tripsChannel;
  RealtimeChannel? _placesChannel;
  RealtimeChannel? _routesChannel;
  RealtimeChannel? _favoritesChannel;

  // ============ AUTHENTICATION ============

  /// Get current user from Supabase
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // ============ USER OPERATIONS ============

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final response = await _client
          .from(_usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getUser');
      rethrow;
    }
  }

  /// Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _client
          .from(_usersTable)
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getUserByEmail');
      rethrow;
    }
  }

  /// Save user
  Future<void> saveUser(UserModel user) async {
    try {
      await _client.from(_usersTable).upsert(user.toJson());
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.saveUser');
      rethrow;
    }
  }

  /// Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _client.from(_usersTable).update(user.toJson()).eq('id', user.id);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.updateUser');
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _client.from(_usersTable).delete().eq('id', userId);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.deleteUser');
      rethrow;
    }
  }

  /// Update user last login
  Future<void> updateLastLogin(String userId) async {
    try {
      await _client
          .from(_usersTable)
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.updateLastLogin');
      // Don't rethrow as this is not critical
    }
  }

  // ============ PLACES OPERATIONS ============

  /// Get all places for a user
  Future<List<PlaceModel>> getPlaces(String userId) async {
    try {
      final response = await _client
          .from(_placesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => PlaceModel.fromJson(json)).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getPlaces');
      return [];
    }
  }

  /// Get place by ID
  Future<PlaceModel?> getPlace(String placeId) async {
    try {
      final response = await _client
          .from(_placesTable)
          .select()
          .eq('id', placeId)
          .maybeSingle();

      if (response == null) return null;
      return PlaceModel.fromJson(response);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getPlace');
      return null;
    }
  }

  /// Save place
  Future<void> savePlace(PlaceModel place) async {
    try {
      await _client.from(_placesTable).upsert(place.toJson());
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.savePlace');
      rethrow;
    }
  }

  /// Save multiple places
  Future<void> savePlaces(List<PlaceModel> places) async {
    try {
      final jsonList = places.map((place) => place.toJson()).toList();
      await _client.from(_placesTable).upsert(jsonList);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.savePlaces');
      rethrow;
    }
  }

  /// Update place
  Future<void> updatePlace(PlaceModel place) async {
    try {
      await _client
          .from(_placesTable)
          .update(place.toJson())
          .eq('id', place.id);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.updatePlace');
      rethrow;
    }
  }

  /// Delete place
  Future<void> deletePlace(String placeId) async {
    try {
      await _client.from(_placesTable).delete().eq('id', placeId);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.deletePlace');
      rethrow;
    }
  }

  /// Delete multiple places
  Future<void> deletePlaces(List<String> placeIds) async {
    try {
      await _client.from(_placesTable).delete().filter('id', 'in', placeIds);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.deletePlaces');
      rethrow;
    }
  }

  /// Get favorite places
  Future<List<PlaceModel>> getFavoritePlaces(String userId) async {
    try {
      final response = await _client
          .from(_placesTable)
          .select()
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .order('created_at', ascending: false);

      return response.map((json) => PlaceModel.fromJson(json)).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getFavoritePlaces');
      return [];
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String placeId, bool isFavorite) async {
    try {
      await _client
          .from(_placesTable)
          .update({'is_favorite': isFavorite})
          .eq('id', placeId);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.toggleFavorite');
      rethrow;
    }
  }

  // ============ TRIPS OPERATIONS ============

  /// Get all trips for a user
  Future<List<TripModel>> getTrips() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from(_tripsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => TripModel.fromJson(json)).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getTrips');
      return [];
    }
  }

  /// Get trip by ID
  Future<TripModel?> getTrip(String tripId) async {
    try {
      final response = await _client
          .from(_tripsTable)
          .select()
          .eq('id', tripId)
          .maybeSingle();

      if (response == null) return null;
      return TripModel.fromJson(response);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getTrip');
      return null;
    }
  }

  /// Get trips by date range
  Future<List<TripModel>> getTripsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from(_tripsTable)
          .select()
          .eq('user_id', userId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false);

      return response.map((json) => TripModel.fromJson(json)).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getTripsByDateRange');
      return [];
    }
  }

  /// Get trips by status
  Future<List<TripModel>> getTripsByStatus(TripStatus status) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from(_tripsTable)
          .select()
          .eq('user_id', userId)
          .eq('status', status.toString())
          .order('created_at', ascending: false);

      return response.map((json) => TripModel.fromJson(json)).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getTripsByStatus');
      return [];
    }
  }

  /// Get trips by type
  Future<List<TripModel>> getTripsByType(TripType type) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from(_tripsTable)
          .select()
          .eq('user_id', userId)
          .eq('type', type.toString())
          .order('created_at', ascending: false);

      return response.map((json) => TripModel.fromJson(json)).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getTripsByType');
      return [];
    }
  }

  /// Save trip
  Future<void> saveTrip(TripModel trip) async {
    try {
      final json = trip.toJson();
      json['user_id'] = currentUser?.id;
      await _client.from(_tripsTable).upsert(json);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.saveTrip');
      rethrow;
    }
  }

  /// Save multiple trips
  Future<void> saveTrips(List<TripModel> trips) async {
    try {
      final userId = currentUser?.id;
      final jsonList = trips.map((trip) {
        final json = trip.toJson();
        json['user_id'] = userId;
        return json;
      }).toList();

      await _client.from(_tripsTable).upsert(jsonList);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.saveTrips');
      rethrow;
    }
  }

  /// Update trip
  Future<void> updateTrip(TripModel trip) async {
    try {
      await _client.from(_tripsTable).update(trip.toJson()).eq('id', trip.id);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.updateTrip');
      rethrow;
    }
  }

  /// Delete trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _client.from(_tripsTable).delete().eq('id', tripId);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.deleteTrip');
      rethrow;
    }
  }

  /// Delete multiple trips
  Future<void> deleteTrips(List<String> tripIds) async {
    try {
      await _client.from(_tripsTable).delete().filter('id', 'in', tripIds);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.deleteTrips');
      rethrow;
    }
  }

  /// Clear all trips
  Future<void> clearTrips() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;

      await _client.from(_tripsTable).delete().eq('user_id', userId);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.clearTrips');
      rethrow;
    }
  }

  // ============ ROUTES OPERATIONS ============

  /// Get all routes for a user
  Future<List<RouteModel>> getRoutes() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from(_routesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => RouteModel.fromJson(json)).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getRoutes');
      return [];
    }
  }

  /// Get route by ID
  Future<RouteModel?> getRoute(String routeId) async {
    try {
      final response = await _client
          .from(_routesTable)
          .select()
          .eq('id', routeId)
          .maybeSingle();

      if (response == null) return null;
      return RouteModel.fromJson(response);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getRoute');
      return null;
    }
  }

  /// Save route
  Future<void> saveRoute(RouteModel route) async {
    try {
      final json = route.toJson();
      json['user_id'] = currentUser?.id;
      await _client.from(_routesTable).upsert(json);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.saveRoute');
      rethrow;
    }
  }

  /// Delete route
  Future<void> deleteRoute(String routeId) async {
    try {
      await _client.from(_routesTable).delete().eq('id', routeId);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.deleteRoute');
      rethrow;
    }
  }

  // ============ SETTINGS OPERATIONS ============

  /// Get user settings
  Future<Map<String, dynamic>?> getSettings(String userId) async {
    try {
      final response = await _client
          .from(_settingsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return response;
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getSettings');
      return null;
    }
  }

  /// Save user settings
  Future<void> saveSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      final data = {
        'user_id': userId,
        ...settings,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from(_settingsTable).upsert(data);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.saveSettings');
      rethrow;
    }
  }

  /// Update settings
  Future<void> updateSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _client.from(_settingsTable).update(settings).eq('user_id', userId);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.updateSettings');
      rethrow;
    }
  }

  // ============ REALTIME SUBSCRIPTIONS ============

  /// Subscribe to user data changes
  void subscribeToUser(String userId, Function(UserModel) onData) {
    _userChannel = _client
        .channel('user_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _usersTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            final changes = payload.newRecord;
            if (changes != null && changes.isNotEmpty) {
              onData(UserModel.fromJson(changes));
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to trips changes
  void subscribeToTrips(String userId, Function(List<TripModel>) onData) {
    _tripsChannel = _client
        .channel('trips_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _tripsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            getTrips().then(onData);
          },
        )
        .subscribe();
  }

  /// Subscribe to places changes
  void subscribeToPlaces(String userId, Function(List<PlaceModel>) onData) {
    _placesChannel = _client
        .channel('places_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _placesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            getPlaces(userId).then(onData);
          },
        )
        .subscribe();
  }

  /// Subscribe to routes changes
  void subscribeToRoutes(String userId, Function(List<RouteModel>) onData) {
    _routesChannel = _client
        .channel('routes_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _routesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            getRoutes().then(onData);
          },
        )
        .subscribe();
  }

  /// Subscribe to favorites changes
  void subscribeToFavorites(String userId, Function(List<PlaceModel>) onData) {
    _favoritesChannel = _client
        .channel('favorites_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _favoritesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            getFavoritePlaces(userId).then(onData);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from all channels
  void unsubscribeAll() {
    _client.removeAllChannels();
    _userChannel = null;
    _tripsChannel = null;
    _placesChannel = null;
    _routesChannel = null;
    _favoritesChannel = null;
  }

  /// Unsubscribe from a specific channel by name
  void unsubscribe(String channelName) {
    switch (channelName) {
      case 'user_updates':
        if (_userChannel != null) {
          _client.removeChannel(_userChannel!);
          _userChannel = null;
        }
        break;
      case 'trips_updates':
        if (_tripsChannel != null) {
          _client.removeChannel(_tripsChannel!);
          _tripsChannel = null;
        }
        break;
      case 'places_updates':
        if (_placesChannel != null) {
          _client.removeChannel(_placesChannel!);
          _placesChannel = null;
        }
        break;
      case 'routes_updates':
        if (_routesChannel != null) {
          _client.removeChannel(_routesChannel!);
          _routesChannel = null;
        }
        break;
      case 'favorites_updates':
        if (_favoritesChannel != null) {
          _client.removeChannel(_favoritesChannel!);
          _favoritesChannel = null;
        }
        break;
      default:
        print('Unknown channel: $channelName');
    }
  }

  // ============ BATCH OPERATIONS ============

  /// Get all user data
  Future<Map<String, dynamic>> getAllUserData(String userId) async {
    try {
      final results = await Future.wait([
        getUser(userId),
        getPlaces(userId),
        getTrips(),
        getSettings(userId),
      ]);

      return {
        'user': results[0],
        'places': results[1],
        'trips': results[2],
        'settings': results[3],
      };
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.getAllUserData');
      rethrow;
    }
  }

  /// Sync all local data to Supabase
  Future<void> syncAllData({
    required UserModel user,
    required List<PlaceModel> places,
    required List<TripModel> trips,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await Future.wait([
        saveUser(user),
        savePlaces(places),
        saveTrips(trips),
        saveSettings(user.id, settings),
      ]);
    } catch (e) {
      Helpers.logError(e, tag: 'SupabaseService.syncAllData');
      rethrow;
    }
  }

  // ============ UTILITY METHODS ============

  /// Check if table exists
  Future<bool> tableExists(String tableName) async {
    try {
      await _client.from(tableName).select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get database size
  Future<int> getDatabaseSize() async {
    try {
      // This is a simplified version - actual implementation may vary
      final response = await _client.from(_tripsTable).select('count');
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  /// Ping database
  Future<bool> ping() async {
    try {
      await _client.from(_usersTable).select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============ DISPOSE ============

  void dispose() {
    unsubscribeAll();
  }
}

// ============ SUPABASE SERVICE EXTENSIONS ============

extension SupabaseServiceExtension on BuildContext {
  SupabaseService get supabase => SupabaseService();
}

// ============ SUPABASE STREAM BUILDER ============

class SupabaseStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot)
  builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const SupabaseStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return errorWidget ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
        }

        return builder(context, snapshot);
      },
    );
  }
}
