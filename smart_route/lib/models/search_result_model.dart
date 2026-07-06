import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'place_model.dart';

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

  LatLng get position => LatLng(latitude, longitude);

  PlaceModel toPlaceModel() {
    return PlaceModel.fromOSM({
      'display_name': displayName,
      'lat': latitude,
      'lon': longitude,
      'place_id': placeId,
      'type': type,
    });
  }

  @override
  String toString() {
    return 'SearchResult(displayName: $displayName, lat: $latitude, lng: $longitude)';
  }
}
