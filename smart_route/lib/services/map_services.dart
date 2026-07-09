import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:smart_route/core/utills/helpers.dart';
import 'dart:convert';
import 'dart:math';

import '../core/constants/app_constants.dart';
import '../models/place_model.dart';
import '../models/route_model.dart';

class MapService {
  // ============ TILE LAYERS ============

  /// Get tile layer for map - FIXED for flutter_map compatibility
  static TileLayer getTileLayer({
    bool darkMode = false,
    bool satellite = false,
    String? customUrl,
  }) {
    String urlTemplate;

    if (customUrl != null) {
      urlTemplate = customUrl;
    } else if (satellite) {
      // Use Stadia Maps for satellite-like view
      urlTemplate =
          'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png';
    } else if (darkMode) {
      // Use Stadia Maps dark theme
      urlTemplate =
          'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png';
    } else {
      // FIXED: Use the new OSM URL without subdomains
      urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }

    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: AppConstants.packageName,
      maxZoom: AppConstants.maxMapZoom,
      minZoom: AppConstants.minMapZoom,
      tileProvider: NetworkTileProvider(),
      // FIXED: Remove subdomains to avoid warning
      // subdomains: ['a', 'b', 'c'], // <-- REMOVED
      retinaMode: true,
      additionalOptions: {
        'attribution': '© OpenStreetMap contributors',
        'attributionUrl': 'https://www.openstreetmap.org/copyright',
      },
    );
  }

  /// Get tile layer with custom attribution - FIXED
  static TileLayer getCustomTileLayer({
    required String urlTemplate,
    String? attribution,
    double maxZoom = AppConstants.maxMapZoom,
    double minZoom = AppConstants.minMapZoom,
    List<String>? subdomains,
  }) {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: AppConstants.packageName,
      maxZoom: maxZoom,
      minZoom: minZoom,
      tileProvider: NetworkTileProvider(),
      subdomains:
          subdomains ??
          const ['a', 'b', 'c'], // Provide default if null // Only if provided
      retinaMode: true,
      additionalOptions: {'attribution': attribution ?? '© OpenStreetMap'},
    );
  }

  /// Get tile layer with Stadia Maps - FIXED (removed unsupported parameters)
  static TileLayer getStadiaTileLayer({bool darkMode = false, String? apiKey}) {
    // Stadia Maps is free for open-source projects
    // Get a free API key at: https://stadiamaps.com/
    final urlTemplate = darkMode
        ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
        : 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png';

    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: AppConstants.packageName,
      maxZoom: 20,
      minZoom: AppConstants.minMapZoom,
      tileProvider: NetworkTileProvider(),
      retinaMode: true,
      additionalOptions: {
        'attribution':
            '&copy; <a href="https://stadiamaps.com/">Stadia Maps</a>',
      },
      // Removed: maxRetries, retryDelay, useCache, cacheKey, cacheMaxAge
    );
  }

  /// Get tile layer with MapBox (requires API key) - FIXED
  static TileLayer getMapBoxTileLayer({
    required String apiKey,
    bool darkMode = false,
    String? style,
  }) {
    final styleId = style ?? (darkMode ? 'dark-v11' : 'streets-v12');
    final urlTemplate =
        'https://api.mapbox.com/styles/v1/mapbox/$styleId/tiles/{z}/{x}/{y}?access_token=$apiKey';

    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: AppConstants.packageName,
      maxZoom: 20,
      minZoom: AppConstants.minMapZoom,
      tileProvider: NetworkTileProvider(),
      retinaMode: true,
      additionalOptions: {
        'attribution': '&copy; <a href="https://mapbox.com/">MapBox</a>',
      },
    );
  }

  // ============ SEARCH LOCATION ============

  /// Search locations by query using OSM Nominatim
  static Future<List<SearchResult>> searchLocation(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      // URL encode the query
      final encodedQuery = Uri.encodeComponent(query.trim());

      // Use OSM Nominatim API with proper parameters
      final url =
          'https://nominatim.openstreetmap.org/search'
          '?q=$encodedQuery'
          '&format=json'
          '&addressdetails=1'
          '&limit=20'
          '&accept-language=en';

      print('🔍 Searching for: $query');
      print('🌐 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SmartRoute/1.0 (flutter app)',
          'Accept': 'application/json',
        },
      );

      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('📊 Found ${data.length} results');

        if (data.isEmpty) {
          print('⚠️ No results found for: $query');
          return [];
        }

        final results = <SearchResult>[];
        for (final item in data) {
          try {
            results.add(_parseOSMResult(item));
          } catch (e) {
            print('❌ Error parsing result: $e');
          }
        }

        print('✅ Successfully parsed ${results.length} results');
        return results;
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Search error: $e');
      Helpers.logError(e, tag: 'MapService.searchLocation');
      return [];
    }
  }

  /// Parse OSM result manually (more reliable)
  static SearchResult _parseOSMResult(Map<String, dynamic> json) {
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
      street: address?['road'] ?? address?['street'] ?? address?['pedestrian'],
      city:
          address?['city'] ??
          address?['town'] ??
          address?['village'] ??
          address?['hamlet'],
      state: address?['state'] ?? address?['province'],
      country: address?['country'],
      postalCode: address?['postcode'],
    );
  }

  static Future<List<SearchSuggestion>> searchAutocomplete(String query) async {
    if (query.isEmpty) return [];

    try {
      final results = await searchLocation(query);
      return results
          .map((result) => SearchSuggestion.fromResult(result))
          .toList();
    } catch (e) {
      Helpers.logError(e, tag: 'MapService.searchAutocomplete');
      return [];
    }
  }

  // ============ ROUTE SERVICES ============

  /// Get route between two points using OSRM
  static Future<RouteData> getRoute({
    required LatLng start,
    required LatLng end,
    String? profile,
    bool alternatives = false,
    bool steps = true,
  }) async {
    try {
      final profileType = profile ?? 'driving';
      final url =
          'https://router.project-osrm.org/route/v1/$profileType/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson'
          '&alternatives=$alternatives'
          '&steps=$steps';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseRouteResponse(data);
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      Helpers.logError(e, tag: 'MapService.getRoute');
      rethrow;
    }
  }

  /// Get route with waypoints
  static Future<List<RouteData>> getRouteWithWaypoints({
    required List<LatLng> waypoints,
    String? profile,
    bool alternatives = false,
  }) async {
    if (waypoints.length < 2) {
      throw Exception('At least 2 waypoints required');
    }

    try {
      final profileType = profile ?? 'driving';
      final coordinates = waypoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      final url =
          'https://router.project-osrm.org/route/v1/$profileType/$coordinates'
          '?overview=full&geometries=geojson'
          '&alternatives=$alternatives'
          '&steps=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes == null || routes.isEmpty) {
          throw Exception('No routes found');
        }

        return routes
            .map((route) => _parseRouteData(route, data['waypoints']))
            .toList();
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      Helpers.logError(e, tag: 'MapService.getRouteWithWaypoints');
      rethrow;
    }
  }

  /// Parse route response
  static RouteData _parseRouteResponse(Map<String, dynamic> data) {
    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No routes found');
    }
    return _parseRouteData(routes.first, data['waypoints']);
  }

  static RouteData _parseRouteData(
    Map<String, dynamic> route,
    List? waypoints,
  ) {
    final geometry = route['geometry'];
    final distance = (route['distance'] ?? 0) / 1000;
    final duration = (route['duration'] ?? 0) / 60;

    List<LatLng> points = [];
    if (geometry != null) {
      if (geometry is Map && geometry.containsKey('coordinates')) {
        final coords = geometry['coordinates'] as List;
        points = coords.map((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList();
      } else if (geometry is String) {
        points = decodePolyline(geometry);
      }
    }

    List<RouteStep> steps = [];
    final legs = route['legs'] as List?;
    if (legs != null && legs.isNotEmpty) {
      final leg = legs.first;
      final legSteps = leg['steps'] as List?;
      if (legSteps != null) {
        steps = legSteps.map((step) {
          final stepPoints = step['geometry'] != null
              ? _decodeStepGeometry(step['geometry'])
              : [];
          return RouteStep(
            instruction:
                step['maneuver']?['instruction'] ?? step['name'] ?? 'Continue',
            distance: (step['distance'] ?? 0) / 1000,
            duration: (step['duration'] ?? 0) / 60,
            points: stepPoints.cast<LatLng>(),
            type: _getStepType(step['maneuver']?['type'] ?? ''),
            street: step['name'],
            exitNumber: step['maneuver']?['exit'],
          );
        }).toList();
      }
    }

    return RouteData(
      points: points,
      distance: distance,
      duration: duration,
      polyline: Polyline(
        points: points,
        color: const Color(0xFF2196F3),
        strokeWidth: 5,
        borderStrokeWidth: 1,
        borderColor: Colors.white.withOpacity(0.3),
        isDotted: false,
      ),
      steps: steps,
      summary: route['summary'] as String?,
    );
  }

  static List<LatLng> _decodeStepGeometry(dynamic geometry) {
    if (geometry is Map && geometry.containsKey('coordinates')) {
      final coords = geometry['coordinates'] as List;
      return coords.map((coord) => LatLng(coord[1], coord[0])).toList();
    }
    if (geometry is String) {
      return decodePolyline(geometry);
    }
    return [];
  }

  static RouteStepType _getStepType(String type) {
    switch (type.toLowerCase()) {
      case 'turn':
      case 'turn left':
      case 'turn right':
        return RouteStepType.turn;
      case 'merge':
        return RouteStepType.merge;
      case 'fork':
        return RouteStepType.fork;
      case 'exit':
        return RouteStepType.exit;
      case 'roundabout':
        return RouteStepType.roundabout;
      case 'depart':
        return RouteStepType.depart;
      case 'arrive':
        return RouteStepType.arrive;
      default:
        return RouteStepType.continue_straight;
    }
  }

  // ============ POLYLINE ENCODING/DECODING ============

  static List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];

    final List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  static String encodePolyline(List<LatLng> points) {
    if (points.isEmpty) return '';

    late int lastLat, lastLng;
    StringBuffer result = StringBuffer();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      int lat = (point.latitude * 1e5).round();
      int lng = (point.longitude * 1e5).round();

      if (i == 0) {
        lastLat = lat;
        lastLng = lng;
        result.write(_encodeNumber(lat));
        result.write(_encodeNumber(lng));
      } else {
        result.write(_encodeNumber(lat - lastLat));
        result.write(_encodeNumber(lng - lastLng));
        lastLat = lat;
        lastLng = lng;
      }
    }

    return result.toString();
  }

  static String _encodeNumber(int num) {
    int n = num < 0 ? ~(num << 1) : (num << 1);
    StringBuffer result = StringBuffer();
    while (n >= 0x20) {
      result.writeCharCode((0x20 | (n & 0x1f)) + 63);
      n >>= 5;
    }
    result.writeCharCode(n + 63);
    return result.toString();
  }

  // ============ GEOCODING SERVICES ============

  /// Reverse geocoding - get address from coordinates
  static Future<String> getAddressFromCoordinates(LatLng position) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=${position.latitude}'
          '&lon=${position.longitude}'
          '&format=json'
          '&zoom=18'
          '&addressdetails=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SmartRoute/1.0 (flutter app)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'];
        }
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          return _buildAddressFromComponents(address);
        }
      }
      return 'Unknown Location';
    } catch (e) {
      Helpers.logError(e, tag: 'MapService.getAddressFromCoordinates');
      return 'Unknown Location';
    }
  }

  /// Build address from address components
  static String _buildAddressFromComponents(Map<String, dynamic> address) {
    final parts = <String>[];
    final road = address['road'] ?? address['street'] ?? address['pedestrian'];
    final city =
        address['city'] ??
        address['town'] ??
        address['village'] ??
        address['hamlet'];
    final state = address['state'] ?? address['province'];
    final country = address['country'];
    final postcode = address['postcode'];

    if (road != null && road.isNotEmpty) parts.add(road);
    if (city != null && city.isNotEmpty) parts.add(city);
    if (state != null && state.isNotEmpty) parts.add(state);
    if (country != null && country.isNotEmpty) parts.add(country);
    if (postcode != null && postcode.isNotEmpty) parts.add(postcode);

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
  }

  // ============ PLACE SERVICES ============

  /// Get place details by ID
  static Future<PlaceModel?> getPlaceDetails(String placeId) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/lookup'
          '?osm_ids=$placeId'
          '&format=json'
          '&addressdetails=1';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SmartRoute/1.0 (flutter app)'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return PlaceModel.fromOSM(data.first);
        }
      }
      return null;
    } catch (e) {
      Helpers.logError(e, tag: 'MapService.getPlaceDetails');
      return null;
    }
  }

  /// Get nearby places
  static Future<List<SearchResult>> getNearbyPlaces({
    required LatLng center,
    double radius = 1000,
    int limit = 20,
  }) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=${center.latitude}'
          '&lon=${center.longitude}'
          '&format=json'
          '&zoom=18'
          '&addressdetails=1'
          '&polygon_geojson=1'
          '&radius=$radius'
          '&limit=$limit';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'SmartRoute/1.0 (flutter app)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final nearby = <SearchResult>[];
          final address = data['address'] as Map<String, dynamic>;
          return nearby;
        }
      }
      return [];
    } catch (e) {
      Helpers.logError(e, tag: 'MapService.getNearbyPlaces');
      return [];
    }
  }

  // ============ MAP STYLES ============

  static Map<String, dynamic> getMapStyle(String theme) {
    switch (theme) {
      case 'dark':
        return {
          'version': 8,
          'sources': {
            'osm': {
              'type': 'raster',
              'tiles': [
                'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png',
              ],
              'tileSize': 256,
              'attribution': '© OpenStreetMap',
              'maxzoom': 19,
            },
          },
          'layers': [
            {'id': 'osm', 'type': 'raster', 'source': 'osm'},
          ],
        };
      case 'satellite':
        return {
          'version': 8,
          'sources': {
            'satellite': {
              'type': 'raster',
              'tiles': ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
              'tileSize': 256,
              'attribution': '© OpenStreetMap',
              'maxzoom': 19,
            },
          },
          'layers': [
            {'id': 'satellite', 'type': 'raster', 'source': 'satellite'},
          ],
        };
      case 'terrain':
        return {
          'version': 8,
          'sources': {
            'terrain': {
              'type': 'raster',
              'tiles': ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
              'tileSize': 256,
              'attribution': '© OpenStreetMap',
              'maxzoom': 19,
            },
          },
          'layers': [
            {'id': 'terrain', 'type': 'raster', 'source': 'terrain'},
          ],
        };
      default:
        return {
          'version': 8,
          'sources': {
            'osm': {
              'type': 'raster',
              'tiles': ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
              'tileSize': 256,
              'attribution': '© OpenStreetMap',
              'maxzoom': 19,
            },
          },
          'layers': [
            {'id': 'osm', 'type': 'raster', 'source': 'osm'},
          ],
        };
    }
  }

  // ============ UTILITY METHODS ============

  static double calculateDistance(LatLng p1, LatLng p2) {
    const double radius = 6371;
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLng = _degToRad(p2.longitude - p1.longitude);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(p1.latitude)) *
            cos(_degToRad(p2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  static double _degToRad(double deg) => deg * pi / 180;

  static double calculateBearing(LatLng p1, LatLng p2) {
    final dLng = _degToRad(p2.longitude - p1.longitude);
    final y = sin(dLng) * cos(_degToRad(p2.latitude));
    final x =
        cos(_degToRad(p1.latitude)) * sin(_degToRad(p2.latitude)) -
        sin(_degToRad(p1.latitude)) * cos(_degToRad(p2.latitude)) * cos(dLng);
    return (_degToRad(atan2(y, x)) + 2 * pi) % (2 * pi);
  }

  static LatLng getMidpoint(LatLng p1, LatLng p2) {
    return LatLng(
      (p1.latitude + p2.latitude) / 2,
      (p1.longitude + p2.longitude) / 2,
    );
  }

  static bool isWithinBounds(LatLng point, LatLngBounds bounds) {
    return point.latitude >= bounds.southWest.latitude &&
        point.latitude <= bounds.northEast.latitude &&
        point.longitude >= bounds.southWest.longitude &&
        point.longitude <= bounds.northEast.longitude;
  }

  static LatLngBounds getBoundsFromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));
    }

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

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  static LatLng getBoundsCenter(LatLngBounds bounds) {
    return LatLng(
      (bounds.northEast.latitude + bounds.southWest.latitude) / 2,
      (bounds.northEast.longitude + bounds.southWest.longitude) / 2,
    );
  }

  static double getZoomToFitBounds(
    LatLngBounds bounds,
    Size mapSize, {
    double padding = 50,
  }) {
    final latSpan = bounds.northEast.latitude - bounds.southWest.latitude;
    final lngSpan = bounds.northEast.longitude - bounds.southWest.longitude;

    if (latSpan <= 0 || lngSpan <= 0) return 15;

    final width = mapSize.width - padding * 2;
    final height = mapSize.height - padding * 2;

    final latZoom = log(180 / latSpan) / ln2;
    final lngZoom = log(360 / lngSpan) / ln2;
    final zoom = min(latZoom, lngZoom) - 1;

    return zoom.clamp(3, 19).toDouble();
  }

  // ============ OVERPASS API ============

  static Future<List<Map<String, dynamic>>> queryOverpass({
    required LatLng center,
    required double radius,
    required String query,
  }) async {
    try {
      final overpassQuery =
          '''
        [out:json];
        (
          node["name"]["amenity"~"$query"](
            around:$radius,${center.latitude},${center.longitude}
          );
          way["name"]["amenity"~"$query"](
            around:$radius,${center.latitude},${center.longitude}
          );
        );
        out body;
      ''';

      final url =
          'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List? ?? [];
        return elements.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      Helpers.logError(e, tag: 'MapService.queryOverpass');
      return [];
    }
  }

  static Future<List<SearchResult>> getNearbyAmenities({
    required LatLng center,
    double radius = 1000,
    List<String>? amenityTypes,
  }) async {
    final types = amenityTypes ?? ['restaurant', 'cafe', 'hotel', 'parking'];
    final results = <SearchResult>[];

    for (final type in types) {
      final data = await queryOverpass(
        center: center,
        radius: radius,
        query: type,
      );

      for (final item in data) {
        final lat = item['lat'] as double? ?? 0;
        final lon = item['lon'] as double? ?? 0;
        if (lat != 0 && lon != 0) {
          results.add(
            SearchResult(
              displayName: item['tags']?['name'] ?? type,
              latitude: lat,
              longitude: lon,
              type: type,
              category: 'amenity',
              name: item['tags']?['name'],
            ),
          );
        }
      }
    }

    return results;
  }
}

// ============ SEARCH RESULT MODEL ============

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

  @override
  String toString() {
    return 'SearchResult(displayName: $displayName, lat: $latitude, lng: $longitude)';
  }
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
      subtitle: result.city ?? result.street,
      icon: Icons.place,
      result: result,
    );
  }

  factory SearchSuggestion.recent(String text) {
    return SearchSuggestion(text: text, type: 'Recent', icon: Icons.history);
  }
}

// ============ ROUTE DATA ============

class RouteData {
  final List<LatLng> points;
  final double distance;
  final double duration;
  final Polyline polyline;
  final List<RouteStep> steps;
  final String? summary;

  RouteData({
    required this.points,
    required this.distance,
    required this.duration,
    required this.polyline,
    this.steps = const [],
    this.summary,
  });

  String get formattedDistance => AppConstants.formatDistance(distance);
  String get formattedDuration => AppConstants.formatDuration(duration);
}

// ============ MAP MARKER BUILDER ============

class MapMarkerBuilder {
  static Marker buildLocationMarker({
    required LatLng point,
    required String id,
    Color color = Colors.blue,
    double size = 40,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      key: Key(id),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.location_on, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }

  static Marker buildDestinationMarker({
    required LatLng point,
    required String id,
    double size = 40,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      key: Key(id),
      child: GestureDetector(
        onTap: onTap,
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
          child: Icon(Icons.flag, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }

  static Marker buildTextMarker({
    required LatLng point,
    required String id,
    required String label,
    Color color = Colors.blue,
    double size = 40,
    VoidCallback? onTap,
  }) {
    return Marker(
      point: point,
      width: size,
      height: size,
      key: Key(id),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ EXTENSIONS ============

extension LatLngExtension on LatLng {
  double distanceTo(LatLng other) {
    return MapService.calculateDistance(this, other);
  }

  double bearingTo(LatLng other) {
    return MapService.calculateBearing(this, other);
  }

  LatLng midpointTo(LatLng other) {
    return MapService.getMidpoint(this, other);
  }

  bool isWithinBounds(LatLngBounds bounds) {
    return MapService.isWithinBounds(this, bounds);
  }

  String get formatted =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

extension LatLngBoundsExtension on LatLngBounds {
  LatLng get center => MapService.getBoundsCenter(this);
  double get width => northEast.longitude - southWest.longitude;
  double get height => northEast.latitude - southWest.latitude;
  bool contains(LatLng point) => MapService.isWithinBounds(point, this);
}

extension PolylineExtension on Polyline {
  double get totalDistance {
    if (points.isEmpty) return 0.0;
    double distance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      distance += points[i].distanceTo(points[i + 1]);
    }
    return distance;
  }

  String get formattedDistance => AppConstants.formatDistance(totalDistance);
}
