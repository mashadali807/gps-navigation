import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Helpers {
  // ============ DATE TIME HELPERS ============

  /// Format DateTime to string with specified format
  static String formatDateTime(
    DateTime dateTime, {
    String format = AppConstants.dateTimeFormat,
  }) {
    return DateFormat(format).format(dateTime);
  }

  /// Format DateTime to date only
  static String formatDate(DateTime dateTime) {
    return DateFormat(AppConstants.dateFormat).format(dateTime);
  }

  /// Format DateTime to time only
  static String formatTime(DateTime dateTime) {
    return DateFormat(AppConstants.timeFormat).format(dateTime);
  }

  /// Get time ago string (e.g., "5 minutes ago")
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Get start of day
  static DateTime getStartOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Get end of day
  static DateTime getEndOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59);
  }

  // ============ STRING HELPERS ============

  /// Capitalize first letter of string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Capitalize each word in string
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Check if string is empty or null
  static bool isNullOrEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// Get initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Convert string to slug
  static String toSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  // ============ NUMBER HELPERS ============

  /// Format number with commas
  static String formatNumber(double number) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(number);
  }

  /// Format currency
  static String formatCurrency(double amount, {String currencySymbol = '\$'}) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Clamp value between min and max
  static double clamp(double value, double min, double max) {
    return value.clamp(min, max);
  }

  /// Convert degrees to radians
  static double degToRad(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Convert radians to degrees
  static double radToDeg(double radians) {
    return radians * 180.0 / pi;
  }

  /// Calculate percentage
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  // ============ VALIDATION HELPERS ============

  /// Validate email
  static bool isValidEmail(String email) {
    return AppConstants.emailRegex.hasMatch(email);
  }

  /// Validate phone number
  static bool isValidPhone(String phone) {
    return AppConstants.phoneRegex.hasMatch(phone);
  }

  /// Validate password
  static bool isValidPassword(String password) {
    return AppConstants.passwordRegex.hasMatch(password);
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============ DISTANCE HELPERS ============

  /// Calculate distance between two coordinates using Haversine formula
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371; // kilometers

    final dLat = degToRad(lat2 - lat1);
    final dLon = degToRad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(degToRad(lat1)) *
            cos(degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Get bearing between two coordinates
  static double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = degToRad(lon2 - lon1);
    final y = sin(dLon) * cos(degToRad(lat2));
    final x =
        cos(degToRad(lat1)) * sin(degToRad(lat2)) -
        sin(degToRad(lat1)) * cos(degToRad(lat2)) * cos(dLon);
    return radToDeg(atan2(y, x));
  }

  /// Format distance based on unit preference
  static String formatDistance(
    double distanceInKm, {
    String unit = AppConstants.unitKilometers,
  }) {
    return AppConstants.formatDistance(distanceInKm, unit: unit);
  }

  /// Convert between distance units
  static double convertDistance(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    if (fromUnit == AppConstants.unitKilometers &&
        toUnit == AppConstants.unitMiles) {
      return value / 1.60934;
    } else if (fromUnit == AppConstants.unitMiles &&
        toUnit == AppConstants.unitKilometers) {
      return value * 1.60934;
    }
    return value;
  }

  // ============ TIME HELPERS ============

  /// Format duration in minutes to readable string
  static String formatDuration(double minutes) {
    return AppConstants.formatDuration(minutes);
  }

  /// Format speed
  static String formatSpeed(
    double speedInMps, {
    String unit = AppConstants.speedKmh,
  }) {
    return AppConstants.formatSpeed(speedInMps, unit: unit);
  }

  /// Convert speed between units
  static double convertSpeed(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    // Convert to m/s first
    double inMps;
    if (fromUnit == AppConstants.speedKmh) {
      inMps = value / 3.6;
    } else if (fromUnit == AppConstants.speedMph) {
      inMps = value / 2.23694;
    } else {
      inMps = value;
    }

    // Convert from m/s to target unit
    if (toUnit == AppConstants.speedKmh) {
      return inMps * 3.6;
    } else if (toUnit == AppConstants.speedMph) {
      return inMps * 2.23694;
    }
    return inMps;
  }

  // ============ FILE HELPERS ============

  /// Get file extension from filename
  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return '';
    return parts.last;
  }

  /// Get file size in human readable format
  static String formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    var size = bytes.toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  // ============ COLOR HELPERS ============

  /// Generate random color
  static Color getRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1.0,
    );
  }

  /// Darken color
  static Color darkenColor(Color color, [double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Lighten color
  static Color lightenColor(Color color, [double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Get contrast color (black or white) for better visibility
  static Color getContrastColor(Color color) {
    final luminance =
        (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // ============ DEVICE HELPERS ============

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.portrait;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive font size
  static double responsiveFontSize(BuildContext context, double size) {
    final scale = MediaQuery.of(context).textScaleFactor;
    return size * scale;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600;
  }

  // ============ PERMISSION HELPERS ============

  /// Show permission dialog
  static Future<bool> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Allow'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ============ CONSOLE HELPERS ============

  /// Print debug log with timestamp
  static void log(String message, {String? tag}) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final prefix = tag != null ? '[$tag]' : '[LOG]';
    print('$prefix $timestamp - $message');
  }

  /// Print error log
  static void logError(dynamic error, {String? tag}) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final prefix = tag != null ? '[ERROR:$tag]' : '[ERROR]';
    print('$prefix $timestamp - $error');
  }

  // ============ MISC HELPERS ============

  /// Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Get platform-specific route name
  static String getPlatformRoute(String route) {
    final isWeb = identical(0, 0.0) && !identical(0, 0.0);
    return isWeb ? '/$route' : route;
  }

  /// Check if value is numeric
  static bool isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  /// Safely parse double
  static double? safeParseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  /// Safely parse int
  static int? safeParseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// Get difference between two lists
  static List<T> getListDifference<T>(List<T> list1, List<T> list2) {
    return list1.where((item) => !list2.contains(item)).toList();
  }

  /// Check if two lists are equal (regardless of order)
  static bool listsEqualUnordered<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    final sorted1 = List<T>.from(list1)..sort();
    final sorted2 = List<T>.from(list2)..sort();
    return sorted1.toString() == sorted2.toString();
  }

  /// Get safe value from map with default
  static T? getSafeValue<T>(
    Map<String, dynamic> map,
    String key, {
    T? defaultValue,
  }) {
    return map.containsKey(key) ? map[key] as T? : defaultValue;
  }

  /// Retry operation with exponential backoff
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    var delay = initialDelay;
    var attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      }
    }
    throw Exception('Operation failed after $maxRetries attempts');
  }

  /// Get greeting based on time of day
  static String getGreeting(DateTime time) {
    return AppConstants.getGreeting(time);
  }

  /// Get month name
  static String getMonthName(int month) {
    return AppConstants.getMonthName(month);
  }

  /// Get day name
  static String getDayName(int day) {
    return AppConstants.getDayName(day);
  }

  /// Check if app is in debug mode
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  /// Get current timestamp as string
  static String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }
}
