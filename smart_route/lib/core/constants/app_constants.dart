import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'GPS Navigation Pro';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.gps.navigation.app';

  // API Keys & URLs
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmRoutingUrl =
      'https://router.project-osrm.org/route/v1/driving/';
  static const String osmGeocodingUrl = 'https://nominatim.openstreetmap.org';

  // Map Defaults
  static const double defaultMapLatitude = 40.7128; // New York
  static const double defaultMapLongitude = -74.0060;
  static const double defaultMapZoom = 14.0;
  static const double minMapZoom = 3.0;
  static const double maxMapZoom = 19.0;
  static const int animationDuration = 500; // milliseconds

  // Location Settings
  static const int locationUpdateInterval = 2; // seconds
  static const int locationDistanceFilter = 1; // meters
  static const int locationAccuracy = 100; // meters

  // Cache Keys
  static const String hiveBoxName = 'gps_navigation_box';
  static const String savedPlacesKey = 'saved_places';
  static const String favoritePlacesKey = 'favorite_places';
  static const String tripHistoryKey = 'trip_history';
  static const String userSettingsKey = 'user_settings';
  static const String cachedLocationsKey = 'cached_locations';

  // Shared Preferences Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefUnits = 'units';
  static const String prefShowNotifications = 'show_notifications';
  static const String prefOfflineMode = 'offline_mode';
  static const String prefFirstLaunch = 'first_launch';

  // Trip History Filters
  static const String filterToday = 'Today';
  static const String filterWeek = 'This Week';
  static const String filterMonth = 'This Month';
  static const String filterYear = 'This Year';

  // Place Categories
  static const List<String> placeCategories = [
    'Home',
    'Office',
    'University',
    'Gym',
    'Restaurant',
    'Shopping',
    'Parking',
    'Other',
  ];

  // Distance Units
  static const String unitKilometers = 'Kilometers';
  static const String unitMiles = 'Miles';

  // Speed Units
  static const String speedKmh = 'km/h';
  static const String speedMph = 'mph';

  // Map Tiles
  static const String tileStyleLight = 'light';
  static const String tileStyleDark = 'dark';
  static const String tileStyleSatellite = 'satellite';

  // Error Messages
  static const String errorLocationPermission =
      'Location permission is required to use this app.';
  static const String errorLocationService =
      'Please enable location services to use this app.';
  static const String errorNoInternet =
      'No internet connection. Please check your network.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorAuth = 'Authentication failed. Please try again.';
  static const String errorRoute =
      'Could not find a route to your destination.';
  static const String errorSearch =
      'Could not find the location. Please try another search.';
  static const String errorSavePlace =
      'Failed to save place. Please try again.';

  // Success Messages
  static const String successLogin = 'Logged in successfully!';
  static const String successRegister = 'Account created successfully!';
  static const String successLogout = 'Logged out successfully!';
  static const String successSavePlace = 'Place saved successfully!';
  static const String successDeletePlace = 'Place deleted successfully!';

  // Animation Durations
  static const Duration durationShort = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 400);
  static const Duration durationLong = Duration(milliseconds: 600);
  static const Duration durationExtraLong = Duration(milliseconds: 800);

  // Screen Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;
  static const double radiusCircular = 50.0;

  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeExtraLarge = 20.0;
  static const double fontSizeHeading = 24.0;
  static const double fontSizeDisplay = 32.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;

  // Elevation
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationExtraLarge = 16.0;

  // Duration Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String timeFormat24 = 'HH:mm';
  static const String dateFormatShort = 'dd/MM/yyyy';

  // Validation Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[0-9]{10,15}$';
  static const String passwordPattern =
      r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,}$';

  // Map Style
  static const List<Map<String, dynamic>> mapStyleLight = [
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {"color": "#e9e9e9"},
        {"lightness": 17},
      ],
    },
    {
      "featureType": "landscape",
      "elementType": "geometry",
      "stylers": [
        {"color": "#f5f5f5"},
        {"lightness": 20},
      ],
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {"color": "#ffffff"},
        {"lightness": 0},
      ],
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [
        {"color": "#ffffff"},
        {"lightness": 0},
      ],
    },
    {
      "featureType": "road.local",
      "elementType": "geometry",
      "stylers": [
        {"color": "#ffffff"},
        {"lightness": 0},
      ],
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {"color": "#e5e5e5"},
        {"lightness": 0},
      ],
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [
        {"color": "#e5e5e5"},
        {"lightness": 0},
      ],
    },
  ];

  static const List<Map<String, dynamic>> mapStyleDark = [
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {"color": "#1a1a2e"},
        {"lightness": -20},
      ],
    },
    {
      "featureType": "landscape",
      "elementType": "geometry",
      "stylers": [
        {"color": "#16213e"},
        {"lightness": -30},
      ],
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {"color": "#2c3e50"},
        {"lightness": -10},
      ],
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [
        {"color": "#34495e"},
        {"lightness": -10},
      ],
    },
    {
      "featureType": "road.local",
      "elementType": "geometry",
      "stylers": [
        {"color": "#2c3e50"},
        {"lightness": -5},
      ],
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {"color": "#2c3e50"},
        {"lightness": -10},
      ],
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [
        {"color": "#34495e"},
        {"lightness": -15},
      ],
    },
  ];

  // Regular Expressions
  static RegExp emailRegex = RegExp(emailPattern);
  static RegExp phoneRegex = RegExp(phonePattern);
  static RegExp passwordRegex = RegExp(passwordPattern);

  // Method to get formatted distance
  static String formatDistance(
    double distanceInKm, {
    String unit = unitKilometers,
  }) {
    if (distanceInKm < 0.1) {
      final meters = (distanceInKm * 1000).round();
      return '$meters m';
    }

    if (unit == unitMiles) {
      final miles = distanceInKm / 1.609;
      return '${miles.toStringAsFixed(1)} mi';
    }

    return '${distanceInKm.toStringAsFixed(1)} km';
  }

  // Method to get formatted duration
  static String formatDuration(double durationInMinutes) {
    final hours = durationInMinutes ~/ 60;
    final minutes = (durationInMinutes % 60).round();

    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }

  // Method to get formatted speed
  static String formatSpeed(double speedInMps, {String unit = speedKmh}) {
    if (unit == speedKmh) {
      final kmh = speedInMps * 3.6;
      return '${kmh.toStringAsFixed(1)} km/h';
    } else {
      final mph = speedInMps * 2.237;
      return '${mph.toStringAsFixed(1)} mph';
    }
  }

  // Method to get greeting based on time
  static String getGreeting(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  // Method to get month name
  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // Method to get day name
  static String getDayName(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[day - 1];
  }

  // Get color based on place category
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Home':
        return Colors.green;
      case 'Office':
        return Colors.blue;
      case 'University':
        return Colors.purple;
      case 'Gym':
        return Colors.orange;
      case 'Restaurant':
        return Colors.red;
      case 'Shopping':
        return Colors.pink;
      case 'Parking':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  // Get icon based on place category
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Home':
        return Icons.home;
      case 'Office':
        return Icons.work;
      case 'University':
        return Icons.school;
      case 'Gym':
        return Icons.fitness_center;
      case 'Restaurant':
        return Icons.restaurant;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Parking':
        return Icons.local_parking;
      default:
        return Icons.place;
    }
  }

  // Get traffic color based on speed
  static Color getTrafficColor(double speed, double speedLimit) {
    final ratio = speed / speedLimit;
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
