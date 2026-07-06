import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_route/models/place_model.dart';
import 'dart:math';

class SearchResult {
  final String? id;
  final String displayName;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? type;
  final String? category;
  final Map<String, dynamic>? address;
  final double? importance;
  final String? icon;
  final String? osmId;
  final String? osmType;
  final String? name;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  SearchResult({
    this.id,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.type,
    this.category,
    this.address,
    this.importance,
    this.icon,
    this.osmId,
    this.osmType,
    this.name,
    this.street,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  // ============ FACTORY CONSTRUCTORS ============

  /// Create from OSM Nominatim response
  factory SearchResult.fromOSM(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>?;

    return SearchResult(
      id: json['place_id']?.toString(),
      displayName: json['display_name'] ?? json['name'] ?? 'Unknown Location',
      latitude: double.tryParse(json['lat']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['lon']?.toString() ?? '0') ?? 0,
      placeId: json['place_id']?.toString(),
      type: json['type'] ?? json['category'],
      category: json['category'] ?? json['class'],
      address: address,
      importance: json['importance']?.toDouble(),
      icon: json['icon'],
      osmId: json['osm_id']?.toString(),
      osmType: json['osm_type'],
      name: json['name'],
      street: address?['road'] ?? address?['street'],
      city: address?['city'] ?? address?['town'] ?? address?['village'],
      state: address?['state'] ?? address?['province'],
      country: address?['country'],
      postalCode: address?['postcode'],
    );
  }

  /// Create from Google Places response
  factory SearchResult.fromGoogle(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;

    return SearchResult(
      id: json['place_id'],
      displayName:
          json['name'] ?? json['formatted_address'] ?? 'Unknown Location',
      latitude: location?['lat']?.toDouble() ?? 0,
      longitude: location?['lng']?.toDouble() ?? 0,
      placeId: json['place_id'],
      type: json['types']?.isNotEmpty == true ? json['types'][0] : null,
      address: json['address_components'] != null
          ? {'address_components': json['address_components']}
          : null,
      icon: json['icon'],
    );
  }

  /// Create from MapBox response
  factory SearchResult.fromMapBox(Map<String, dynamic> json) {
    final context = json['context'] as List?;
    final address = json['address'] as String?;
    final placeName = json['place_name'] ?? json['text'] ?? 'Unknown Location';

    // Extract place info from context
    String? city, state, country, postalCode;
    if (context != null) {
      for (final item in context) {
        final id = item['id'] as String? ?? '';
        if (id.contains('place')) {
          city = item['text'];
        } else if (id.contains('region')) {
          state = item['text'];
        } else if (id.contains('country')) {
          country = item['text'];
        } else if (id.contains('postcode')) {
          postalCode = item['text'];
        }
      }
    }

    return SearchResult(
      id: json['id'],
      displayName: address != null ? '$address, $placeName' : placeName,
      latitude: json['center']?[1]?.toDouble() ?? 0,
      longitude: json['center']?[0]?.toDouble() ?? 0,
      placeId: json['id'],
      type: json['type'],
      category: json['type'],
      name: json['text'],
      street: address,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
    );
  }

  /// Create from JSON (generic)
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] ?? json['place_id']?.toString(),
      displayName: json['display_name'] ?? json['name'] ?? 'Unknown Location',
      latitude:
          double.tryParse(
            json['latitude']?.toString() ?? json['lat']?.toString() ?? '0',
          ) ??
          0,
      longitude:
          double.tryParse(
            json['longitude']?.toString() ?? json['lon']?.toString() ?? '0',
          ) ??
          0,
      placeId: json['place_id']?.toString(),
      type: json['type'] ?? json['category'],
      category: json['category'] ?? json['class'],
      address: json['address'],
      importance: json['importance']?.toDouble(),
      icon: json['icon'],
      osmId: json['osm_id']?.toString(),
      osmType: json['osm_type'],
      name: json['name'],
      street: json['street'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
    );
  }

  // ============ CONVERSION METHODS ============

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'place_id': placeId,
      'type': type,
      'category': category,
      'address': address,
      'importance': importance,
      'icon': icon,
      'osm_id': osmId,
      'osm_type': osmType,
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
    };
  }

  /// Convert to PlaceModel
  PlaceModel toPlaceModel() {
    return PlaceModel.fromOSM({
      'display_name': displayName,
      'lat': latitude,
      'lon': longitude,
      'place_id': placeId,
      'type': type,
      'category': category,
      'address': address,
      'name': name,
    });
  }

  /// Convert to Hive map for storage
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'displayName': displayName,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      'type': type,
      'category': category,
      'address': address,
      'importance': importance,
      'icon': icon,
      'osmId': osmId,
      'osmType': osmType,
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }

  /// Create from Hive map
  factory SearchResult.fromHiveMap(Map<String, dynamic> map) {
    return SearchResult(
      id: map['id'],
      displayName: map['displayName'] ?? 'Unknown Location',
      latitude: map['latitude'] ?? 0,
      longitude: map['longitude'] ?? 0,
      placeId: map['placeId'],
      type: map['type'],
      category: map['category'],
      address: map['address'],
      importance: map['importance']?.toDouble(),
      icon: map['icon'],
      osmId: map['osmId'],
      osmType: map['osmType'],
      name: map['name'],
      street: map['street'],
      city: map['city'],
      state: map['state'],
      country: map['country'],
      postalCode: map['postalCode'],
    );
  }

  // ============ COPY METHODS ============

  SearchResult copyWith({
    String? id,
    String? displayName,
    double? latitude,
    double? longitude,
    String? placeId,
    String? type,
    String? category,
    Map<String, dynamic>? address,
    double? importance,
    String? icon,
    String? osmId,
    String? osmType,
    String? name,
    String? street,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) {
    return SearchResult(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      type: type ?? this.type,
      category: category ?? this.category,
      address: address ?? this.address,
      importance: importance ?? this.importance,
      icon: icon ?? this.icon,
      osmId: osmId ?? this.osmId,
      osmType: osmType ?? this.osmType,
      name: name ?? this.name,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  // ============ GETTERS ============

  /// Get location as LatLng
  LatLng get position => LatLng(latitude, longitude);

  /// Get formatted location string
  String get locationString => '$latitude, $longitude';

  /// Get short display name
  String get shortName {
    if (displayName.length <= 40) return displayName;
    return '${displayName.substring(0, 37)}...';
  }

  /// Get display icon based on type
  IconData get iconData {
    return _getIconForType(type ?? category);
  }

  /// Get color based on type
  Color get color {
    return _getColorForType(type ?? category);
  }

  /// Get formatted address without display name
  String? get formattedAddress {
    if (street != null && city != null) {
      return '$street, $city';
    }
    if (city != null && state != null) {
      return '$city, $state';
    }
    if (city != null) {
      return city;
    }
    return null;
  }

  /// Check if result has complete address
  bool get hasCompleteAddress {
    return street != null && city != null && state != null && country != null;
  }

  /// Get full address with all components
  String? get fullAddress {
    final parts = <String>[];
    if (street != null) parts.add(street!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (country != null) parts.add(country!);
    if (postalCode != null) parts.add(postalCode!);
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  // ============ STATIC HELPERS ============

  static IconData _getIconForType(String? type) {
    if (type == null) return Icons.place;

    final lowerType = type.toLowerCase();
    if (lowerType.contains('city') ||
        lowerType.contains('town') ||
        lowerType.contains('village') ||
        lowerType.contains('municipality')) {
      return Icons.location_city;
    }
    if (lowerType.contains('street') ||
        lowerType.contains('road') ||
        lowerType.contains('avenue') ||
        lowerType.contains('boulevard')) {
      return Icons.streetview;
    }
    if (lowerType.contains('building') ||
        lowerType.contains('house') ||
        lowerType.contains('residential') ||
        lowerType.contains('apartment')) {
      return Icons.business_center;
    }
    if (lowerType.contains('park') ||
        lowerType.contains('garden') ||
        lowerType.contains('nature')) {
      return Icons.park;
    }
    if (lowerType.contains('restaurant') ||
        lowerType.contains('cafe') ||
        lowerType.contains('bar') ||
        lowerType.contains('pub')) {
      return Icons.local_cafe;
    }
    if (lowerType.contains('hotel') ||
        lowerType.contains('motel') ||
        lowerType.contains('hostel') ||
        lowerType.contains('lodging')) {
      return Icons.hotel;
    }
    if (lowerType.contains('hospital') ||
        lowerType.contains('clinic') ||
        lowerType.contains('doctor') ||
        lowerType.contains('health')) {
      return Icons.local_hospital;
    }
    if (lowerType.contains('school') ||
        lowerType.contains('university') ||
        lowerType.contains('college') ||
        lowerType.contains('academy')) {
      return Icons.school;
    }
    if (lowerType.contains('museum') ||
        lowerType.contains('gallery') ||
        lowerType.contains('exhibition')) {
      return Icons.museum;
    }
    if (lowerType.contains('church') ||
        lowerType.contains('cathedral') ||
        lowerType.contains('chapel') ||
        lowerType.contains('basilica')) {
      return Icons.church;
    }
    if (lowerType.contains('mosque') || lowerType.contains('masjid')) {
      return Icons.mosque;
    }
    if (lowerType.contains('temple') ||
        lowerType.contains('pagoda') ||
        lowerType.contains('shrine')) {
      return Icons.temple_buddhist;
    }
    if (lowerType.contains('shop') ||
        lowerType.contains('store') ||
        lowerType.contains('mall') ||
        lowerType.contains('market')) {
      return Icons.shopping_bag;
    }
    if (lowerType.contains('cafe') || lowerType.contains('coffee')) {
      return Icons.local_cafe;
    }
    if (lowerType.contains('airport')) {
      return Icons.local_airport;
    }
    if (lowerType.contains('station') ||
        lowerType.contains('transit') ||
        lowerType.contains('bus') ||
        lowerType.contains('train')) {
      return Icons.directions_transit;
    }
    if (lowerType.contains('landmark') ||
        lowerType.contains('monument') ||
        lowerType.contains('attraction') ||
        lowerType.contains('tourist')) {
      return Icons.history;
    }
    if (lowerType.contains('beach') ||
        lowerType.contains('coast') ||
        lowerType.contains('shore')) {
      return Icons.beach_access;
    }
    if (lowerType.contains('mountain') ||
        lowerType.contains('hill') ||
        lowerType.contains('peak')) {
      return Icons.terrain;
    }
    if (lowerType.contains('lake') ||
        lowerType.contains('river') ||
        lowerType.contains('ocean') ||
        lowerType.contains('water')) {
      return Icons.water;
    }
    if (lowerType.contains('gym') || lowerType.contains('fitness')) {
      return Icons.fitness_center;
    }
    if (lowerType.contains('parking')) {
      return Icons.local_parking;
    }
    if (lowerType.contains('gas') || lowerType.contains('fuel')) {
      return Icons.local_gas_station;
    }
    if (lowerType.contains('bank') || lowerType.contains('atm')) {
      return Icons.account_balance;
    }
    if (lowerType.contains('pharmacy') || lowerType.contains('drugstore')) {
      return Icons.local_pharmacy;
    }

    return Icons.place;
  }

  static Color _getColorForType(String? type) {
    if (type == null) return Colors.blue;

    final lowerType = type.toLowerCase();
    if (lowerType.contains('city') || lowerType.contains('town')) {
      return Colors.deepPurple;
    }
    if (lowerType.contains('street') || lowerType.contains('road')) {
      return Colors.grey;
    }
    if (lowerType.contains('building')) {
      return Colors.orange;
    }
    if (lowerType.contains('park') || lowerType.contains('garden')) {
      return Colors.green;
    }
    if (lowerType.contains('restaurant') || lowerType.contains('cafe')) {
      return Colors.red;
    }
    if (lowerType.contains('hotel')) {
      return Colors.amber;
    }
    if (lowerType.contains('hospital')) {
      return Colors.pink;
    }
    if (lowerType.contains('school') || lowerType.contains('university')) {
      return Colors.blue;
    }
    if (lowerType.contains('museum') || lowerType.contains('gallery')) {
      return Colors.deepOrange;
    }
    if (lowerType.contains('church') ||
        lowerType.contains('mosque') ||
        lowerType.contains('temple')) {
      return Colors.indigo;
    }
    if (lowerType.contains('shop') || lowerType.contains('store')) {
      return Colors.teal;
    }
    if (lowerType.contains('airport')) {
      return Colors.lightBlue;
    }
    if (lowerType.contains('station') || lowerType.contains('transit')) {
      return Colors.deepPurple;
    }
    if (lowerType.contains('landmark') || lowerType.contains('monument')) {
      return Colors.brown;
    }
    if (lowerType.contains('beach')) {
      return Colors.yellow.shade700;
    }
    if (lowerType.contains('mountain')) {
      return Colors.green.shade700;
    }
    if (lowerType.contains('lake') ||
        lowerType.contains('river') ||
        lowerType.contains('ocean')) {
      return Colors.blue.shade700;
    }
    if (lowerType.contains('gym') || lowerType.contains('fitness')) {
      return Colors.orange.shade700;
    }
    if (lowerType.contains('parking')) {
      return Colors.grey.shade700;
    }
    if (lowerType.contains('gas') || lowerType.contains('fuel')) {
      return Colors.red.shade700;
    }
    if (lowerType.contains('bank')) {
      return Colors.green.shade700;
    }
    if (lowerType.contains('pharmacy')) {
      return Colors.green.shade600;
    }

    return Colors.blue;
  }

  // ============ VALIDATION ============

  /// Check if search result is valid
  bool get isValid {
    return displayName.isNotEmpty &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  // ============ COMPARISON ============

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.id == id &&
        other.placeId == placeId &&
        other.displayName == displayName;
  }

  @override
  int get hashCode {
    return id.hashCode ^ placeId.hashCode ^ displayName.hashCode;
  }

  @override
  String toString() {
    return 'SearchResult(displayName: $displayName, lat: $latitude, lng: $longitude, type: $type)';
  }
}

// ============ SEARCH RESULT COLLECTION ============

class SearchResultCollection {
  final List<SearchResult> results;
  final String? query;
  final DateTime timestamp;

  SearchResultCollection({
    required this.results,
    this.query,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from JSON list
  factory SearchResultCollection.fromJsonList(
    List<Map<String, dynamic>> jsonList, {
    String? query,
  }) {
    return SearchResultCollection(
      results: jsonList.map((json) => SearchResult.fromJson(json)).toList(),
      query: query,
    );
  }

  /// Convert to JSON list
  List<Map<String, dynamic>> toJsonList() {
    return results.map((result) => result.toJson()).toList();
  }

  /// Filter results by type
  List<SearchResult> filterByType(String type) {
    return results.where((result) => result.type == type).toList();
  }

  /// Filter results by category
  List<SearchResult> filterByCategory(String category) {
    return results.where((result) => result.category == category).toList();
  }

  /// Filter results by keyword
  List<SearchResult> filterByKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return results
        .where(
          (result) =>
              result.displayName.toLowerCase().contains(lowerKeyword) ||
              result.name?.toLowerCase().contains(lowerKeyword) == true ||
              result.street?.toLowerCase().contains(lowerKeyword) == true ||
              result.city?.toLowerCase().contains(lowerKeyword) == true,
        )
        .toList();
  }

  /// Sort by importance
  List<SearchResult> sortByImportance({bool descending = true}) {
    final sorted = List<SearchResult>.from(results);
    sorted.sort((a, b) {
      final impA = a.importance ?? 0;
      final impB = b.importance ?? 0;
      return descending ? impB.compareTo(impA) : impA.compareTo(impB);
    });
    return sorted;
  }

  /// Sort by distance from location
  List<SearchResult> sortByDistance(double lat, double lng) {
    final sorted = List<SearchResult>.from(results);
    sorted.sort((a, b) {
      final distA = _calculateDistance(lat, lng, a.latitude, a.longitude);
      final distB = _calculateDistance(lat, lng, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    return sorted;
  }

  /// Get unique results (remove duplicates)
  SearchResultCollection unique() {
    final seen = <String>{};
    final uniqueResults = results.where((result) {
      final key = result.placeId ?? result.displayName;
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
    return SearchResultCollection(
      results: uniqueResults,
      query: query,
      timestamp: timestamp,
    );
  }

  /// Get nearby results
  List<SearchResult> getNearby(double lat, double lng, double radiusInKm) {
    return results.where((result) {
      final distance = _calculateDistance(
        lat,
        lng,
        result.latitude,
        result.longitude,
      );
      return distance <= radiusInKm;
    }).toList();
  }

  /// Get cities
  List<SearchResult> get cities {
    return results
        .where(
          (result) =>
              result.type?.toLowerCase().contains('city') == true ||
              result.type?.toLowerCase().contains('town') == true ||
              result.category?.toLowerCase().contains('city') == true ||
              result.category?.toLowerCase().contains('town') == true,
        )
        .toList();
  }

  /// Get streets
  List<SearchResult> get streets {
    return results
        .where(
          (result) =>
              result.type?.toLowerCase().contains('street') == true ||
              result.type?.toLowerCase().contains('road') == true ||
              result.category?.toLowerCase().contains('highway') == true,
        )
        .toList();
  }

  /// Get landmarks
  List<SearchResult> get landmarks {
    return results
        .where(
          (result) =>
              result.type?.toLowerCase().contains('landmark') == true ||
              result.type?.toLowerCase().contains('monument') == true ||
              result.type?.toLowerCase().contains('attraction') == true ||
              result.category?.toLowerCase().contains('tourism') == true,
        )
        .toList();
  }

  /// Get businesses
  List<SearchResult> get businesses {
    return results
        .where(
          (result) =>
              result.type?.toLowerCase().contains('shop') == true ||
              result.type?.toLowerCase().contains('restaurant') == true ||
              result.type?.toLowerCase().contains('cafe') == true ||
              result.type?.toLowerCase().contains('hotel') == true ||
              result.category?.toLowerCase().contains('commercial') == true,
        )
        .toList();
  }

  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double radius = 6371; // Earth's radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  static double _degToRad(double deg) => deg * pi / 180;
}

// ============ SEARCH SUGGESTION MODEL ============

class SearchSuggestion {
  final String text;
  final String? type;
  final String? subtitle;
  final IconData? icon;
  final SearchResult? result;

  SearchSuggestion({
    required this.text,
    this.type,
    this.subtitle,
    this.icon,
    this.result,
  });

  factory SearchSuggestion.fromResult(SearchResult result) {
    return SearchSuggestion(
      text: result.displayName,
      type: result.type ?? 'Location',
      subtitle: result.formattedAddress,
      icon: result.iconData,
      result: result,
    );
  }

  factory SearchSuggestion.recent(String text) {
    return SearchSuggestion(text: text, type: 'Recent', icon: Icons.history);
  }

  factory SearchSuggestion.favorite(String text) {
    return SearchSuggestion(text: text, type: 'Favorite', icon: Icons.favorite);
  }
}

// ============ SEARCH HISTORY MODEL ============

class SearchHistory {
  final String id;
  final String query;
  final SearchResult? selectedResult;
  final DateTime timestamp;

  SearchHistory({
    String? id,
    required this.query,
    this.selectedResult,
    required this.timestamp,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'],
      query: json['query'] ?? '',
      selectedResult: json['selected_result'] != null
          ? SearchResult.fromJson(json['selected_result'])
          : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'selected_result': selectedResult?.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
