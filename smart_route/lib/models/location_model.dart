import 'dart:math';
import 'package:latlong2/latlong.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;
  final String? address;
  final String? city;
  final String? country;
  final DateTime timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
    this.address,
    this.city,
    this.country,
    required this.timestamp,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      accuracy: json['accuracy']?.toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      altitude: json['altitude']?.toDouble(),
      address: json['address'],
      city: json['city'],
      country: json['country'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
      'address': address,
      'city': city,
      'country': country,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // ============ COPY METHOD ============

  /// Create a copy of this LocationModel with updated fields
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    double? heading,
    double? altitude,
    String? address,
    String? city,
    String? country,
    DateTime? timestamp,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      altitude: altitude ?? this.altitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // ============ HELPER METHODS ============

  /// Check if location is valid
  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Get formatted location string
  String get formattedLocation {
    return '$latitude, $longitude';
  }

  /// Get formatted address or coordinates if address is null
  String get displayAddress {
    return address ?? formattedLocation;
  }

  /// Check if location has address
  bool get hasAddress => address != null && address!.isNotEmpty;

  /// Check if location has city
  bool get hasCity => city != null && city!.isNotEmpty;

  /// Check if location has country
  bool get hasCountry => country != null && country!.isNotEmpty;

  /// Get full address with city and country
  String? get fullAddress {
    if (!hasAddress) return null;
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    if (country != null) parts.add(country!);
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  // ============ EQUALITY ============

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^ longitude.hashCode ^ timestamp.hashCode;
  }

  @override
  String toString() {
    return 'LocationModel(latitude: $latitude, longitude: $longitude, address: $address, timestamp: $timestamp)';
  }
}

// ============ EXTENSIONS ============

extension LocationModelExtension on LocationModel {
  /// Convert to LatLng
  LatLng get toLatLng => LatLng(latitude, longitude);

  /// Get distance to another location in kilometers
  double distanceTo(LocationModel other) {
    return distanceBetween(
      lat1: latitude,
      lon1: longitude,
      lat2: other.latitude,
      lon2: other.longitude,
    );
  }

  /// Calculate distance between two coordinates using Haversine formula
  double distanceBetween({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double radius = 6371; // Earth's radius in km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  /// Convert degrees to radians
  double _degToRad(double deg) => deg * pi / 180;
}
