import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'dart:convert';
import 'dart:io';

import '../models/user_model.dart';
import '../models/place_model.dart';
import '../models/trip_model.dart';
import '../models/route_model.dart';
import '../models/location_model.dart';

class StorageService {
  // ============ HIVE INITIALIZATION ============

  static const String _userBox = 'user_box';
  static const String _placesBox = 'places_box';
  static const String _tripsBox = 'trips_box';
  static const String _routesBox = 'routes_box';
  static const String _settingsBox = 'settings_box';
  static const String _cacheBox = 'cache_box';
  static const String _historyBox = 'history_box';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isInitialized = false;

  /// Initialize Hive storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      // Register adapters if needed
      // Hive.registerAdapter(UserModelAdapter());
      // Hive.registerAdapter(PlaceModelAdapter());
      // etc.

      _isInitialized = true;
      Helpers.log('Storage service initialized', tag: 'StorageService');
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.initialize');
      rethrow;
    }
  }

  // ============ BOX HELPERS ============

  Future<Box<T>> _getBox<T>(String boxName) async {
    if (!_isInitialized) {
      await initialize();
    }
    return await Hive.openBox<T>(boxName);
  }

  Future<void> _clearBox(String boxName) async {
    final box = await _getBox(boxName);
    await box.clear();
  }

  // ============ USER STORAGE ============

  /// Save user data
  Future<void> saveUser(UserModel user) async {
    try {
      final box = await _getBox(_userBox);
      await box.put('current_user', user.toJson());

      // Also save to secure storage
      await _secureStorage.write(key: 'user_id', value: user.id);
      await _secureStorage.write(
        key: 'user_data',
        value: jsonEncode(user.toJson()),
      );

      Helpers.log('User saved: ${user.id}', tag: 'StorageService');
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.saveUser');
      rethrow;
    }
  }

  /// Get user data
  Future<UserModel?> getUser() async {
    try {
      // Try secure storage first
      final userData = await _secureStorage.read(key: 'user_data');
      if (userData != null) {
        final json = jsonDecode(userData) as Map<String, dynamic>;
        return UserModel.fromJson(json);
      }

      // Try Hive
      final box = await _getBox(_userBox);
      final data = box.get('current_user');
      if (data != null) {
        return UserModel.fromJson(data as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getUser');
      return null;
    }
  }

  /// Delete user data
  Future<void> deleteUser() async {
    try {
      await _clearBox(_userBox);
      await _secureStorage.delete(key: 'user_id');
      await _secureStorage.delete(key: 'user_data');
      Helpers.log('User deleted', tag: 'StorageService');
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.deleteUser');
      rethrow;
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: 'user_id');
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getUserId');
      return null;
    }
  }

  // ============ PLACES STORAGE ============

  /// Save place
  Future<void> savePlace(PlaceModel place) async {
    try {
      final box = await _getBox(_placesBox);
      await box.put(place.id, place.toHiveMap());
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.savePlace');
      rethrow;
    }
  }

  /// Save multiple places
  Future<void> savePlaces(List<PlaceModel> places) async {
    try {
      final box = await _getBox(_placesBox);
      for (final place in places) {
        await box.put(place.id, place.toHiveMap());
      }
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.savePlaces');
      rethrow;
    }
  }

  /// Get place by ID
  Future<PlaceModel?> getPlace(String id) async {
    try {
      final box = await _getBox(_placesBox);
      final data = box.get(id);
      if (data == null) return null;
      return PlaceModel.fromHiveMap(data as Map<String, dynamic>);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getPlace');
      return null;
    }
  }

  /// Get all places
  Future<List<PlaceModel>> getAllPlaces() async {
    try {
      final box = await _getBox(_placesBox);
      final places = <PlaceModel>[];
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          places.add(PlaceModel.fromHiveMap(data as Map<String, dynamic>));
        }
      }
      return places;
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getAllPlaces');
      return [];
    }
  }

  /// Get favorite places
  Future<List<PlaceModel>> getFavoritePlaces() async {
    try {
      final all = await getAllPlaces();
      return all.where((place) => place.isFavorite).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getFavoritePlaces');
      return [];
    }
  }

  /// Get saved places
  Future<List<PlaceModel>> getSavedPlaces() async {
    try {
      final all = await getAllPlaces();
      return all.where((place) => place.isSaved).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getSavedPlaces');
      return [];
    }
  }

  /// Delete place
  Future<void> deletePlace(String id) async {
    try {
      final box = await _getBox(_placesBox);
      await box.delete(id);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.deletePlace');
      rethrow;
    }
  }

  /// Clear all places
  Future<void> clearAllPlaces() async {
    try {
      await _clearBox(_placesBox);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.clearAllPlaces');
      rethrow;
    }
  }

  // ============ TRIPS STORAGE ============

  /// Save trip
  Future<void> saveTrip(TripModel trip) async {
    try {
      final box = await _getBox(_tripsBox);
      await box.put(trip.id, trip.toHiveMap());
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.saveTrip');
      rethrow;
    }
  }

  /// Save multiple trips
  Future<void> saveTrips(List<TripModel> trips) async {
    try {
      final box = await _getBox(_tripsBox);
      for (final trip in trips) {
        await box.put(trip.id, trip.toHiveMap());
      }
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.saveTrips');
      rethrow;
    }
  }

  /// Get trip by ID
  Future<TripModel?> getTrip(String id) async {
    try {
      final box = await _getBox(_tripsBox);
      final data = box.get(id);
      if (data == null) return null;
      return TripModel.fromHiveMap(data as Map<String, dynamic>);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getTrip');
      return null;
    }
  }

  /// Get all trips
  Future<List<TripModel>> getAllTrips() async {
    try {
      final box = await _getBox(_tripsBox);
      final trips = <TripModel>[];
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          trips.add(TripModel.fromHiveMap(data as Map<String, dynamic>));
        }
      }
      // Sort by date (most recent first)
      trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return trips;
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getAllTrips');
      return [];
    }
  }

  /// Get trips by date range
  Future<List<TripModel>> getTripsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final all = await getAllTrips();
      return all
          .where(
            (trip) =>
                trip.createdAt.isAfter(start) && trip.createdAt.isBefore(end),
          )
          .toList();
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getTripsByDateRange');
      return [];
    }
  }

  /// Get trips by status
  Future<List<TripModel>> getTripsByStatus(TripStatus status) async {
    try {
      final all = await getAllTrips();
      return all.where((trip) => trip.status == status).toList();
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getTripsByStatus');
      return [];
    }
  }

  /// Delete trip
  Future<void> deleteTrip(String id) async {
    try {
      final box = await _getBox(_tripsBox);
      await box.delete(id);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.deleteTrip');
      rethrow;
    }
  }

  /// Clear all trips
  Future<void> clearAllTrips() async {
    try {
      await _clearBox(_tripsBox);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.clearAllTrips');
      rethrow;
    }
  }

  // ============ ROUTES STORAGE ============

  /// Save route
  Future<void> saveRoute(RouteModel route) async {
    try {
      final box = await _getBox(_routesBox);
      await box.put(route.id, route.toHiveMap());
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.saveRoute');
      rethrow;
    }
  }

  /// Get route by ID
  Future<RouteModel?> getRoute(String id) async {
    try {
      final box = await _getBox(_routesBox);
      final data = box.get(id);
      if (data == null) return null;
      return RouteModel.fromHiveMap(data as Map<String, dynamic>);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getRoute');
      return null;
    }
  }

  /// Get all routes
  Future<List<RouteModel>> getAllRoutes() async {
    try {
      final box = await _getBox(_routesBox);
      final routes = <RouteModel>[];
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          routes.add(RouteModel.fromHiveMap(data as Map<String, dynamic>));
        }
      }
      return routes;
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getAllRoutes');
      return [];
    }
  }

  /// Delete route
  Future<void> deleteRoute(String id) async {
    try {
      final box = await _getBox(_routesBox);
      await box.delete(id);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.deleteRoute');
      rethrow;
    }
  }

  // ============ LOCATION HISTORY STORAGE ============

  /// Save location history
  Future<void> saveLocationHistory(List<LocationModel> locations) async {
    try {
      final box = await _getBox(_historyBox);
      final data = locations.map((loc) => loc.toJson()).toList();
      await box.put('location_history', jsonEncode(data));
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.saveLocationHistory');
      rethrow;
    }
  }

  /// Get location history
  Future<List<LocationModel>> getLocationHistory() async {
    try {
      final box = await _getBox(_historyBox);
      final data = box.get('location_history');
      if (data == null) return [];

      final List<dynamic> list = jsonDecode(data as String);
      return list
          .map((item) => LocationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getLocationHistory');
      return [];
    }
  }

  /// Clear location history
  Future<void> clearLocationHistory() async {
    try {
      final box = await _getBox(_historyBox);
      await box.delete('location_history');
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.clearLocationHistory');
      rethrow;
    }
  }

  // ============ SETTINGS STORAGE ============

  /// Save settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      final box = await _getBox(_settingsBox);
      for (final entry in settings.entries) {
        await box.put(entry.key, entry.value);
      }
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.saveSettings');
      rethrow;
    }
  }

  /// Get setting
  Future<dynamic> getSetting(String key) async {
    try {
      final box = await _getBox(_settingsBox);
      return box.get(key);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getSetting');
      return null;
    }
  }

  /// Get all settings
  Future<Map<String, dynamic>> getAllSettings() async {
    try {
      final box = await _getBox(_settingsBox);
      final settings = <String, dynamic>{};
      for (final key in box.keys) {
        settings[key as String] = box.get(key);
      }
      return settings;
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getAllSettings');
      return {};
    }
  }

  /// Delete setting
  Future<void> deleteSetting(String key) async {
    try {
      final box = await _getBox(_settingsBox);
      await box.delete(key);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.deleteSetting');
      rethrow;
    }
  }

  // ============ CACHE STORAGE ============

  /// Cache data
  Future<void> cacheData(String key, dynamic data) async {
    try {
      final box = await _getBox(_cacheBox);
      final encoded = jsonEncode(data);
      await box.put(key, encoded);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.cacheData');
      rethrow;
    }
  }

  /// Get cached data
  Future<dynamic> getCachedData(String key) async {
    try {
      final box = await _getBox(_cacheBox);
      final data = box.get(key);
      if (data == null) return null;
      return jsonDecode(data as String);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getCachedData');
      return null;
    }
  }

  /// Delete cached data
  Future<void> deleteCachedData(String key) async {
    try {
      final box = await _getBox(_cacheBox);
      await box.delete(key);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.deleteCachedData');
      rethrow;
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      await _clearBox(_cacheBox);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.clearCache');
      rethrow;
    }
  }

  // ============ GENERIC DATA STORAGE ============

  /// Save generic data (for active trips, temporary data, etc.)
  Future<void> saveData(String key, dynamic data) async {
    try {
      final box = await _getBox(_settingsBox);
      await box.put(key, data);
      Helpers.log('Data saved: $key', tag: 'StorageService');
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.saveData');
      rethrow;
    }
  }

  /// Get generic data
  Future<dynamic> getData(String key) async {
    try {
      final box = await _getBox(_settingsBox);
      return box.get(key);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getData');
      return null;
    }
  }

  /// Delete generic data
  Future<void> deleteData(String key) async {
    try {
      final box = await _getBox(_settingsBox);
      await box.delete(key);
      Helpers.log('Data deleted: $key', tag: 'StorageService');
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.deleteData');
      rethrow;
    }
  }

  // ============ SECURE STORAGE ============

  /// Save secure data
  Future<void> saveSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.saveSecureData');
      rethrow;
    }
  }

  /// Get secure data
  Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getSecureData');
      return null;
    }
  }

  /// Delete secure data
  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.deleteSecureData');
      rethrow;
    }
  }

  /// Clear all secure data
  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.clearAllSecureData');
      rethrow;
    }
  }

  // ============ FILE STORAGE ============

  /// Save file to local storage
  Future<String> saveFile(File file, String directory) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/$directory');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final fileName = file.path.split('/').last;
      final newPath = '${dir.path}/$fileName';
      await file.copy(newPath);
      return newPath;
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.saveFile');
      return '';
    }
  }

  /// Get file from local storage
  Future<File?> getFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getFile');
      return null;
    }
  }

  /// Delete file from local storage
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.deleteFile');
      rethrow;
    }
  }

  /// Get application documents directory
  Future<Directory> getApplicationDocumentsDirectory() async {
    return await Directory('.').absolute;
  }

  // ============ CLEANUP ============

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await _clearBox(_userBox);
      await _clearBox(_placesBox);
      await _clearBox(_tripsBox);
      await _clearBox(_routesBox);
      await _clearBox(_settingsBox);
      await _clearBox(_cacheBox);
      await _clearBox(_historyBox);
      await _secureStorage.deleteAll();
      Helpers.log('All data cleared', tag: 'StorageService');
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.clearAllData');
      rethrow;
    }
  }

  /// Get storage statistics
  Future<StorageStats> getStorageStats() async {
    try {
      final userBox = await _getBox(_userBox);
      final placesBox = await _getBox(_placesBox);
      final tripsBox = await _getBox(_tripsBox);
      final routesBox = await _getBox(_routesBox);
      final settingsBox = await _getBox(_settingsBox);
      final cacheBox = await _getBox(_cacheBox);
      final historyBox = await _getBox(_historyBox);

      return StorageStats(
        userCount: userBox.length,
        placesCount: placesBox.length,
        tripsCount: tripsBox.length,
        routesCount: routesBox.length,
        settingsCount: settingsBox.length,
        cacheCount: cacheBox.length,
        historyCount: historyBox.length,
        totalSize: await _getTotalBoxSize(),
      );
    } catch (e) {
      Helpers.logError(e, tag: 'StorageService.getStorageStats');
      return StorageStats.empty();
    }
  }

  Future<int> _getTotalBoxSize() async {
    // This is a simplified version - in production, you'd calculate actual size
    return 0;
  }
}

// ============ STORAGE STATS ============

class StorageStats {
  final int userCount;
  final int placesCount;
  final int tripsCount;
  final int routesCount;
  final int settingsCount;
  final int cacheCount;
  final int historyCount;
  final int totalSize;

  StorageStats({
    this.userCount = 0,
    this.placesCount = 0,
    this.tripsCount = 0,
    this.routesCount = 0,
    this.settingsCount = 0,
    this.cacheCount = 0,
    this.historyCount = 0,
    this.totalSize = 0,
  });

  factory StorageStats.empty() {
    return StorageStats();
  }

  int get totalItems =>
      userCount +
      placesCount +
      tripsCount +
      routesCount +
      settingsCount +
      cacheCount +
      historyCount;

  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1048576)
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    if (totalSize < 1073741824)
      return '${(totalSize / 1048576).toStringAsFixed(1)} MB';
    return '${(totalSize / 1073741824).toStringAsFixed(1)} GB';
  }
}

// ============ STORAGE PROVIDER ============

class StorageProvider extends InheritedWidget {
  final StorageService storageService;

  const StorageProvider({
    super.key,
    required this.storageService,
    required super.child,
  });

  static StorageProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StorageProvider>();
  }

  static StorageService getService(BuildContext context) {
    final provider = of(context);
    if (provider == null) {
      throw Exception('StorageProvider not found in widget tree');
    }
    return provider.storageService;
  }

  @override
  bool updateShouldNotify(StorageProvider oldWidget) {
    return storageService != oldWidget.storageService;
  }
}

// ============ STORAGE EXTENSIONS ============

extension StorageExtensions on BuildContext {
  StorageService get storage => StorageProvider.getService(this);
  StorageService get storageService => StorageProvider.getService(this);
}
