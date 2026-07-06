import 'package:flutter/material.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';

class PlaceModel {
  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? category;
  final String? icon;
  final bool isFavorite;
  final bool isSaved;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final String? userId;

  PlaceModel({
    String? id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.category,
    this.icon,
    this.isFavorite = false,
    this.isSaved = true,
    DateTime? createdAt,
    this.updatedAt,
    this.metadata,
    this.userId,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // ============ FACTORY CONSTRUCTORS ============

  /// Create from JSON (Supabase)
  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? json['place_name'] ?? 'Unknown Place',
      address: json['address'] ?? json['formatted_address'],
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0.0)
          .toDouble(),
      placeId: json['place_id'] ?? json['placeId'],
      category: json['category'] ?? json['place_category'],
      icon: json['icon'] ?? json['place_icon'],
      isFavorite: json['is_favorite'] ?? json['isFavorite'] ?? false,
      isSaved: json['is_saved'] ?? json['isSaved'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      metadata: json['metadata'] ?? json['extra_data'],
      userId: json['user_id'] ?? json['userId'],
    );
  }

  /// Create from OSM search result
  factory PlaceModel.fromOSM(Map<String, dynamic> osmData) {
    final lat = double.tryParse(osmData['lat']?.toString() ?? '0') ?? 0;
    final lon = double.tryParse(osmData['lon']?.toString() ?? '0') ?? 0;
    final displayName = osmData['display_name'] ?? osmData['name'] ?? 'Unknown';

    // Extract address components
    final address = osmData['address'] as Map<String, dynamic>?;
    final city = address?['city'] ?? address?['town'] ?? address?['village'];
    final country = address?['country'];
    final road = address?['road'] ?? address?['street'];

    String name = osmData['name'] ?? road ?? displayName;
    String fullAddress = displayName;

    return PlaceModel(
      name: name,
      address: fullAddress,
      latitude: lat,
      longitude: lon,
      placeId: osmData['place_id']?.toString(),
      category: osmData['type'] ?? osmData['category'],
      metadata: {
        'osm_id': osmData['osm_id'],
        'osm_type': osmData['osm_type'],
        'class': osmData['class'],
        'display_name': displayName,
        'address': address,
        'city': city,
        'country': country,
        'road': road,
      },
    );
  }

  /// Create from Geocoding result
  factory PlaceModel.fromGeocoding(Map<String, dynamic> data) {
    return PlaceModel(
      name: data['name'] ?? data['formatted_address'] ?? 'Location',
      address: data['formatted_address'] ?? data['address'],
      latitude: (data['latitude'] ?? data['lat'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? data['lng'] ?? data['lon'] ?? 0.0)
          .toDouble(),
      placeId: data['place_id']?.toString(),
      category: data['type'],
      metadata: data['address_components'] != null
          ? {'address_components': data['address_components']}
          : null,
    );
  }

  /// Create current location placeholder
  factory PlaceModel.currentLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    return PlaceModel(
      id: 'current_location',
      name: 'Current Location',
      address: address ?? 'Your current position',
      latitude: latitude,
      longitude: longitude,
      isFavorite: false,
      isSaved: false,
      category: 'Current Location',
      icon: '📍',
    );
  }

  /// Create home place
  factory PlaceModel.home({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? userId,
  }) {
    return PlaceModel(
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      category: 'Home',
      isFavorite: true,
      isSaved: true,
      userId: userId,
      icon: '🏠',
    );
  }

  /// Create office place
  factory PlaceModel.office({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? userId,
  }) {
    return PlaceModel(
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      category: 'Office',
      isFavorite: true,
      isSaved: true,
      userId: userId,
      icon: '🏢',
    );
  }

  // ============ CONVERSION METHODS ============

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'place_id': placeId,
      'category': category,
      'icon': icon,
      'is_favorite': isFavorite,
      'is_saved': isSaved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'user_id': userId,
    };
  }

  /// Convert to Map for Hive storage
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'category': category,
      'icon': icon,
      'isFavorite': isFavorite,
      'isSaved': isSaved,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'metadata': metadata,
      'userId': userId,
    };
  }

  /// Create from Hive map
  factory PlaceModel.fromHiveMap(Map<String, dynamic> map) {
    return PlaceModel(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? 'Unknown',
      address: map['address'],
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      placeId: map['placeId'],
      category: map['category'],
      icon: map['icon'],
      isFavorite: map['isFavorite'] ?? false,
      isSaved: map['isSaved'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      metadata: map['metadata'],
      userId: map['userId'],
    );
  }

  // ============ COPY METHODS ============

  /// Create a copy with updated fields
  PlaceModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
    String? category,
    String? icon,
    bool? isFavorite,
    bool? isSaved,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? userId,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      isFavorite: isFavorite ?? this.isFavorite,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      userId: userId ?? this.userId,
    );
  }

  /// Mark as favorite
  PlaceModel toggleFavorite() {
    return copyWith(isFavorite: !isFavorite, updatedAt: DateTime.now());
  }

  /// Mark as saved
  PlaceModel toggleSaved() {
    return copyWith(isSaved: !isSaved, updatedAt: DateTime.now());
  }

  // ============ GETTERS ============

  /// Get formatted address
  String get formattedAddress {
    return address ?? '$latitude, $longitude';
  }

  /// Get short name for display
  String get displayName {
    if (name.length > 30) {
      return '${name.substring(0, 27)}...';
    }
    return name;
  }

  /// Get category color
  Color get categoryColor {
    return AppConstants.getCategoryColor(category ?? 'Other');
  }

  /// Get category icon
  IconData get categoryIcon {
    return AppConstants.getCategoryIcon(category ?? 'Other');
  }

  /// Get distance from current location
  double? distanceFrom(double lat, double lng) {
    return Helpers.calculateDistance(
      lat1: latitude,
      lon1: longitude,
      lat2: lat,
      lon2: lng,
    );
  }

  /// Check if place has coordinates
  bool get hasCoordinates {
    return latitude != 0 && longitude != 0;
  }

  /// Get location string for map
  String get locationString {
    return '$latitude,$longitude';
  }

  /// Get time since creation
  String get timeAgo {
    return Helpers.timeAgo(createdAt);
  }

  /// Check if place is current location
  bool get isCurrentLocation {
    return id == 'current_location';
  }

  /// Get icon emoji
  String get iconEmoji {
    return icon ?? '📍';
  }

  // ============ EQUALITY & HASHCODE ============

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceModel &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return id.hashCode ^ latitude.hashCode ^ longitude.hashCode;
  }

  // ============ COMPARISON METHODS ============

  /// Compare two places by distance
  static int compareByDistance(
    PlaceModel a,
    PlaceModel b,
    double lat,
    double lng,
  ) {
    final distA = a.distanceFrom(lat, lng) ?? double.infinity;
    final distB = b.distanceFrom(lat, lng) ?? double.infinity;
    return distA.compareTo(distB);
  }

  /// Compare two places by name
  static int compareByName(PlaceModel a, PlaceModel b) {
    return a.name.compareTo(b.name);
  }

  /// Compare two places by date
  static int compareByDate(PlaceModel a, PlaceModel b) {
    return a.createdAt.compareTo(b.createdAt);
  }

  // ============ VALIDATION ============

  /// Validate place data
  bool get isValid {
    return name.isNotEmpty &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Validate for saving
  String? validate() {
    if (name.isEmpty) return 'Place name is required';
    if (latitude < -90 || latitude > 90) return 'Invalid latitude';
    if (longitude < -180 || longitude > 180) return 'Invalid longitude';
    return null;
  }
}

// ============ PLACE CATEGORY MODEL ============

class PlaceCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String? emoji;

  const PlaceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.emoji,
  });

  // Predefined categories
  static const List<PlaceCategory> categories = [
    PlaceCategory(
      id: 'home',
      name: 'Home',
      icon: Icons.home,
      color: Colors.green,
      emoji: '🏠',
    ),
    PlaceCategory(
      id: 'office',
      name: 'Office',
      icon: Icons.work,
      color: Colors.blue,
      emoji: '🏢',
    ),
    PlaceCategory(
      id: 'university',
      name: 'University',
      icon: Icons.school,
      color: Colors.purple,
      emoji: '🎓',
    ),
    PlaceCategory(
      id: 'gym',
      name: 'Gym',
      icon: Icons.fitness_center,
      color: Colors.orange,
      emoji: '💪',
    ),
    PlaceCategory(
      id: 'restaurant',
      name: 'Restaurant',
      icon: Icons.restaurant,
      color: Colors.red,
      emoji: '🍽️',
    ),
    PlaceCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Colors.pink,
      emoji: '🛍️',
    ),
    PlaceCategory(
      id: 'parking',
      name: 'Parking',
      icon: Icons.local_parking,
      color: Colors.grey,
      emoji: '🅿️',
    ),
    PlaceCategory(
      id: 'other',
      name: 'Other',
      icon: Icons.place,
      color: Colors.blueGrey,
      emoji: '📍',
    ),
  ];

  /// Get category by id
  static PlaceCategory? getById(String id) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get category by name
  static PlaceCategory? getByName(String name) {
    try {
      return categories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Get category from place
  static PlaceCategory fromPlace(PlaceModel place) {
    return getByName(place.category ?? '') ?? categories.last;
  }

  /// Get all category names
  static List<String> get categoryNames {
    return categories.map((category) => category.name).toList();
  }

  /// Get all category ids
  static List<String> get categoryIds {
    return categories.map((category) => category.id).toList();
  }
}

// ============ PLACE COLLECTION ============

class PlaceCollection {
  final List<PlaceModel> places;
  final String? userId;
  final DateTime updatedAt;

  PlaceCollection({required this.places, this.userId, DateTime? updatedAt})
    : updatedAt = updatedAt ?? DateTime.now();

  /// Create from list of place JSON
  factory PlaceCollection.fromJsonList(
    List<Map<String, dynamic>> jsonList, {
    String? userId,
  }) {
    return PlaceCollection(
      places: jsonList.map((json) => PlaceModel.fromJson(json)).toList(),
      userId: userId,
    );
  }

  /// Convert to JSON list
  List<Map<String, dynamic>> toJsonList() {
    return places.map((place) => place.toJson()).toList();
  }

  /// Get favorite places
  List<PlaceModel> get favorites {
    return places.where((place) => place.isFavorite).toList();
  }

  /// Get saved places
  List<PlaceModel> get saved {
    return places.where((place) => place.isSaved).toList();
  }

  /// Get places by category
  List<PlaceModel> getByCategory(String category) {
    return places.where((place) => place.category == category).toList();
  }

  /// Search places by name
  List<PlaceModel> search(String query) {
    if (query.isEmpty) return places;
    final lowerQuery = query.toLowerCase();
    return places.where((place) {
      return place.name.toLowerCase().contains(lowerQuery) ||
          (place.address?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Sort places by distance from location
  List<PlaceModel> sortByDistance(double lat, double lng) {
    final sorted = List<PlaceModel>.from(places);
    sorted.sort((a, b) => PlaceModel.compareByDistance(a, b, lat, lng));
    return sorted;
  }

  /// Get place by id
  PlaceModel? getById(String id) {
    try {
      return places.firstWhere((place) => place.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add place
  PlaceCollection addPlace(PlaceModel place) {
    final newPlaces = List<PlaceModel>.from(places)..add(place);
    return PlaceCollection(
      places: newPlaces,
      userId: userId,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove place
  PlaceCollection removePlace(String id) {
    final newPlaces = List<PlaceModel>.from(places)
      ..removeWhere((place) => place.id == id);
    return PlaceCollection(
      places: newPlaces,
      userId: userId,
      updatedAt: DateTime.now(),
    );
  }

  /// Update place
  PlaceCollection updatePlace(PlaceModel updatedPlace) {
    final index = places.indexWhere((place) => place.id == updatedPlace.id);
    if (index == -1) return this;
    final newPlaces = List<PlaceModel>.from(places);
    newPlaces[index] = updatedPlace;
    return PlaceCollection(
      places: newPlaces,
      userId: userId,
      updatedAt: DateTime.now(),
    );
  }
}
