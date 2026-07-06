import 'package:flutter/material.dart';
import 'package:smart_route/core/utills/helpers.dart';
import '../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? bio;
  final UserRole role;
  final UserStatus status;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? metadata;
  final String? fcmToken;
  final String? deviceId;
  final String? appVersion;
  final String? platform;

  UserModel({
    String? id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.bio,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    DateTime? createdAt,
    this.lastLogin,
    this.updatedAt,
    this.preferences,
    this.metadata,
    this.fcmToken,
    this.deviceId,
    this.appVersion,
    this.platform,
  }) : id = id ?? Helpers.generateId(),
       createdAt = createdAt ?? DateTime.now();

  // ============ FACTORY CONSTRUCTORS ============

  /// Create from Firebase User
  factory UserModel.fromFirebase(dynamic firebaseUser) {
    return UserModel(
      id: firebaseUser.uid, // Firebase UID as string
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified ?? false,
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: firebaseUser.metadata?.creationTime ?? DateTime.now(),
      lastLogin: firebaseUser.metadata?.lastSignInTime,
    );
  }

  /// Create from Supabase Auth User
  factory UserModel.fromSupabase(dynamic supabaseUser) {
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName:
          supabaseUser.userMetadata?['display_name'] ??
          supabaseUser.userMetadata?['name'],
      photoUrl:
          supabaseUser.userMetadata?['avatar_url'] ??
          supabaseUser.userMetadata?['picture'],
      phoneNumber: supabaseUser.phone,
      createdAt: supabaseUser.createdAt ?? DateTime.now(),
      lastLogin: supabaseUser.updatedAt,
    );
  }

  /// Create from JSON (Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? Helpers.generateId(),
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? json['name'],
      photoUrl: json['photo_url'] ?? json['avatar_url'],
      phoneNumber: json['phone_number'],
      bio: json['bio'],
      role: _parseRole(json['role']),
      status: _parseStatus(json['status']),
      isEmailVerified: json['is_email_verified'] ?? false,
      isPhoneVerified: json['is_phone_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      preferences: json['preferences'],
      metadata: json['metadata'],
      fcmToken: json['fcm_token'],
      deviceId: json['device_id'],
      appVersion: json['app_version'],
      platform: json['platform'],
    );
  }

  /// Create from Hive map
  factory UserModel.fromHiveMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? Helpers.generateId(),
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? map['name'],
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      bio: map['bio'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == map['role'],
        orElse: () => UserRole.user,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => UserStatus.active,
      ),
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      lastLogin: map['lastLogin'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLogin'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      preferences: map['preferences'],
      metadata: map['metadata'],
      fcmToken: map['fcmToken'],
      deviceId: map['deviceId'],
      appVersion: map['appVersion'],
      platform: map['platform'],
    );
  }

  // ============ HELPER METHODS FOR PARSING ============

  static UserRole _parseRole(String? role) {
    if (role == null) return UserRole.user;
    try {
      return UserRole.values.firstWhere(
        (e) => e.name == role,
        orElse: () => UserRole.user,
      );
    } catch (_) {
      return UserRole.user;
    }
  }

  static UserStatus _parseStatus(String? status) {
    if (status == null) return UserStatus.active;
    try {
      return UserStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => UserStatus.active,
      );
    } catch (_) {
      return UserStatus.active;
    }
  }

  // ============ CONVERSION METHODS ============

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'phone_number': phoneNumber,
      'bio': bio,
      'role': role.name,
      'status': status.name,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'preferences': preferences,
      'metadata': metadata,
      'fcm_token': fcmToken,
      'device_id': deviceId,
      'app_version': appVersion,
      'platform': platform,
    };
  }

  /// Convert to Hive map
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'role': role.toString(),
      'status': status.toString(),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLogin': lastLogin?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'preferences': preferences,
      'metadata': metadata,
      'fcmToken': fcmToken,
      'deviceId': deviceId,
      'appVersion': appVersion,
      'platform': platform,
    };
  }

  // ============ COPY METHOD ============

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    UserRole? role,
    UserStatus? status,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    String? fcmToken,
    String? deviceId,
    String? appVersion,
    String? platform,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      status: status ?? this.status,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
      fcmToken: fcmToken ?? this.fcmToken,
      deviceId: deviceId ?? this.deviceId,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
    );
  }

  // ============ UPDATE METHODS ============

  /// Update last login time
  UserModel updateLastLogin() {
    return copyWith(lastLogin: DateTime.now(), updatedAt: DateTime.now());
  }

  /// Update profile
  UserModel updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
  }) {
    return copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
      phoneNumber: phoneNumber,
      bio: bio,
      updatedAt: DateTime.now(),
    );
  }

  /// Verify email
  UserModel verifyEmail() {
    return copyWith(isEmailVerified: true, updatedAt: DateTime.now());
  }

  /// Verify phone
  UserModel verifyPhone() {
    return copyWith(isPhoneVerified: true, updatedAt: DateTime.now());
  }

  /// Set user role
  UserModel setRole(UserRole newRole) {
    return copyWith(role: newRole, updatedAt: DateTime.now());
  }

  /// Set user status
  UserModel setStatus(UserStatus newStatus) {
    return copyWith(status: newStatus, updatedAt: DateTime.now());
  }

  /// Update preferences
  UserModel updatePreferences(Map<String, dynamic> newPreferences) {
    return copyWith(
      preferences: {...?preferences, ...newPreferences},
      updatedAt: DateTime.now(),
    );
  }

  /// Update FCM token
  UserModel updateFcmToken(String token) {
    return copyWith(fcmToken: token, updatedAt: DateTime.now());
  }

  /// Update device info
  UserModel updateDeviceInfo({
    String? deviceId,
    String? appVersion,
    String? platform,
  }) {
    return copyWith(
      deviceId: deviceId,
      appVersion: appVersion,
      platform: platform,
      updatedAt: DateTime.now(),
    );
  }

  // ============ GETTERS ============

  /// Get display name or email if display name is null
  String get displayNameOrEmail {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    return email.split('@').first;
  }

  /// Get initials for avatar
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      return Helpers.getInitials(displayName!);
    }
    return email.substring(0, 1).toUpperCase();
  }

  /// Get display photo URL or null
  String? get displayPhoto {
    return photoUrl;
  }

  /// Get formatted join date
  String get joinDate {
    return Helpers.formatDate(createdAt);
  }

  /// Get time since joined
  String get joinedTimeAgo {
    return Helpers.timeAgo(createdAt);
  }

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is moderator
  bool get isModerator => role == UserRole.moderator || isAdmin;

  /// Check if user is active
  bool get isActive => status == UserStatus.active;

  /// Check if user is banned
  bool get isBanned => status == UserStatus.banned;

  /// Check if user is suspended
  bool get isSuspended => status == UserStatus.suspended;

  /// Get user status color
  Color get statusColor {
    switch (status) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.inactive:
        return Colors.grey;
      case UserStatus.suspended:
        return Colors.orange;
      case UserStatus.banned:
        return Colors.red;
    }
  }

  /// Get user status label
  String get statusLabel {
    switch (status) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.banned:
        return 'Banned';
    }
  }

  /// Get user role label
  String get roleLabel {
    switch (role) {
      case UserRole.user:
        return 'User';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  /// Get user role icon
  IconData get roleIcon {
    switch (role) {
      case UserRole.user:
        return Icons.person;
      case UserRole.moderator:
        return Icons.shield;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  /// Get user role color
  Color get roleColor {
    switch (role) {
      case UserRole.user:
        return Colors.blue;
      case UserRole.moderator:
        return Colors.orange;
      case UserRole.admin:
        return Colors.red;
    }
  }

  /// Check if profile is complete
  bool get isProfileComplete {
    return displayName != null &&
        displayName!.isNotEmpty &&
        photoUrl != null &&
        photoUrl!.isNotEmpty &&
        phoneNumber != null &&
        phoneNumber!.isNotEmpty;
  }

  /// Get profile completion percentage
  double get profileCompletionPercentage {
    int completedFields = 0;
    final totalFields = 5; // name, photo, phone, bio, email verification

    if (displayName != null && displayName!.isNotEmpty) completedFields++;
    if (photoUrl != null && photoUrl!.isNotEmpty) completedFields++;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) completedFields++;
    if (bio != null && bio!.isNotEmpty) completedFields++;
    if (isEmailVerified) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  /// Get user preferences
  T? getPreference<T>(String key) {
    if (preferences == null) return null;
    final value = preferences![key];
    if (value is T) return value;
    return null;
  }

  /// Check if has preference
  bool hasPreference(String key) {
    return preferences != null && preferences!.containsKey(key);
  }

  /// Get metadata value
  T? getMetadata<T>(String key) {
    if (metadata == null) return null;
    final value = metadata![key];
    if (value is T) return value;
    return null;
  }

  /// Check if has metadata
  bool hasMetadata(String key) {
    return metadata != null && metadata!.containsKey(key);
  }

  // ============ VALIDATION ============

  /// Validate user data
  String? validate() {
    if (email.isEmpty) return 'Email is required';
    if (!Helpers.isValidEmail(email)) return 'Invalid email address';
    return null;
  }

  // ============ EQUALITY ============

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ============ TO STRING ============

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, role: $role)';
  }
}

// ============ ENUMS ============

enum UserRole { user, moderator, admin }

enum UserStatus { active, inactive, suspended, banned }

// ============ USER PREFERENCES MODEL ============

class UserPreferences {
  final bool darkMode;
  final bool notifications;
  final bool locationTracking;
  final bool saveTripHistory;
  final String mapTheme;
  final String distanceUnit;
  final String speedUnit;
  final String language;
  final bool compassEnabled;
  final bool showTraffic;
  final bool offlineMode;
  final int autoSaveInterval; // in seconds
  final Map<String, dynamic> custom;

  UserPreferences({
    this.darkMode = false,
    this.notifications = true,
    this.locationTracking = true,
    this.saveTripHistory = true,
    this.mapTheme = 'standard',
    this.distanceUnit = AppConstants.unitKilometers,
    this.speedUnit = AppConstants.speedKmh,
    this.language = 'en',
    this.compassEnabled = true,
    this.showTraffic = true,
    this.offlineMode = false,
    this.autoSaveInterval = 30,
    this.custom = const {},
  });

  /// Create from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      darkMode: json['dark_mode'] ?? false,
      notifications: json['notifications'] ?? true,
      locationTracking: json['location_tracking'] ?? true,
      saveTripHistory: json['save_trip_history'] ?? true,
      mapTheme: json['map_theme'] ?? 'standard',
      distanceUnit: json['distance_unit'] ?? AppConstants.unitKilometers,
      speedUnit: json['speed_unit'] ?? AppConstants.speedKmh,
      language: json['language'] ?? 'en',
      compassEnabled: json['compass_enabled'] ?? true,
      showTraffic: json['show_traffic'] ?? true,
      offlineMode: json['offline_mode'] ?? false,
      autoSaveInterval: json['auto_save_interval'] ?? 30,
      custom: json['custom'] ?? {},
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'dark_mode': darkMode,
      'notifications': notifications,
      'location_tracking': locationTracking,
      'save_trip_history': saveTripHistory,
      'map_theme': mapTheme,
      'distance_unit': distanceUnit,
      'speed_unit': speedUnit,
      'language': language,
      'compass_enabled': compassEnabled,
      'show_traffic': showTraffic,
      'offline_mode': offlineMode,
      'auto_save_interval': autoSaveInterval,
      'custom': custom,
    };
  }

  /// Create copy with updated fields
  UserPreferences copyWith({
    bool? darkMode,
    bool? notifications,
    bool? locationTracking,
    bool? saveTripHistory,
    String? mapTheme,
    String? distanceUnit,
    String? speedUnit,
    String? language,
    bool? compassEnabled,
    bool? showTraffic,
    bool? offlineMode,
    int? autoSaveInterval,
    Map<String, dynamic>? custom,
  }) {
    return UserPreferences(
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      locationTracking: locationTracking ?? this.locationTracking,
      saveTripHistory: saveTripHistory ?? this.saveTripHistory,
      mapTheme: mapTheme ?? this.mapTheme,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      speedUnit: speedUnit ?? this.speedUnit,
      language: language ?? this.language,
      compassEnabled: compassEnabled ?? this.compassEnabled,
      showTraffic: showTraffic ?? this.showTraffic,
      offlineMode: offlineMode ?? this.offlineMode,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      custom: custom ?? this.custom,
    );
  }

  /// Convert to preferences map
  Map<String, dynamic> toPreferencesMap() {
    return {
      'theme_mode': darkMode ? 'dark' : 'light',
      'notifications_enabled': notifications,
      'location_tracking': locationTracking,
      'save_trip_history': saveTripHistory,
      'map_theme': mapTheme,
      'distance_unit': distanceUnit,
      'speed_unit': speedUnit,
      'language': language,
      'compass_enabled': compassEnabled,
      'show_traffic': showTraffic,
      'offline_mode': offlineMode,
      'auto_save_interval': autoSaveInterval,
    };
  }

  /// Get distance unit label
  String get distanceUnitLabel {
    switch (distanceUnit) {
      case AppConstants.unitKilometers:
        return 'Kilometers';
      case AppConstants.unitMiles:
        return 'Miles';
      default:
        return 'Kilometers';
    }
  }

  /// Get speed unit label
  String get speedUnitLabel {
    switch (speedUnit) {
      case AppConstants.speedKmh:
        return 'km/h';
      case AppConstants.speedMph:
        return 'mph';
      default:
        return 'km/h';
    }
  }
}

// ============ USER STATISTICS ============

class UserStatistics {
  final int totalTrips;
  final double totalDistance;
  final double totalDuration;
  final int totalSavedPlaces;
  final int totalFavoritePlaces;
  final double averageTripDistance;
  final double averageTripDuration;
  final double? averageSpeed;
  final double? maxSpeed;
  final double? totalFuelCost;
  final int activeDays;
  final DateTime? lastTripDate;

  UserStatistics({
    required this.totalTrips,
    required this.totalDistance,
    required this.totalDuration,
    required this.totalSavedPlaces,
    required this.totalFavoritePlaces,
    required this.averageTripDistance,
    required this.averageTripDuration,
    this.averageSpeed,
    this.maxSpeed,
    this.totalFuelCost,
    required this.activeDays,
    this.lastTripDate,
  });

  /// Get formatted statistics
  Map<String, String> get formattedStats {
    return {
      'Total Trips': totalTrips.toString(),
      'Total Distance': AppConstants.formatDistance(totalDistance),
      'Total Duration': AppConstants.formatDuration(totalDuration),
      'Saved Places': totalSavedPlaces.toString(),
      'Favorite Places': totalFavoritePlaces.toString(),
      'Avg Trip Distance': AppConstants.formatDistance(averageTripDistance),
      'Avg Trip Duration': AppConstants.formatDuration(averageTripDuration),
      'Average Speed': averageSpeed != null
          ? '${averageSpeed!.toStringAsFixed(1)} km/h'
          : 'N/A',
      'Max Speed': maxSpeed != null
          ? '${maxSpeed!.toStringAsFixed(1)} km/h'
          : 'N/A',
      'Total Fuel Cost': totalFuelCost != null
          ? '\$${totalFuelCost!.toStringAsFixed(2)}'
          : 'N/A',
      'Active Days': activeDays.toString(),
      'Last Trip': lastTripDate != null
          ? Helpers.formatDate(lastTripDate!)
          : 'No trips yet',
    };
  }
}

// ============ USER COLLECTION ============

class UserCollection {
  final List<UserModel> users;

  const UserCollection({required this.users});

  /// Get active users
  List<UserModel> get activeUsers {
    return users.where((user) => user.isActive).toList();
  }

  /// Get admin users
  List<UserModel> get adminUsers {
    return users.where((user) => user.isAdmin).toList();
  }

  /// Get users by role
  List<UserModel> getByRole(UserRole role) {
    return users.where((user) => user.role == role).toList();
  }

  /// Get users by status
  List<UserModel> getByStatus(UserStatus status) {
    return users.where((user) => user.status == status).toList();
  }

  /// Search users by name or email
  List<UserModel> search(String query) {
    if (query.isEmpty) return users;
    final lowerQuery = query.toLowerCase();
    return users.where((user) {
      return user.displayName?.toLowerCase().contains(lowerQuery) == true ||
          user.email.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get user by id
  UserModel? getById(String id) {
    try {
      return users.firstWhere((user) => user.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get user by email
  UserModel? getByEmail(String email) {
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (_) {
      return null;
    }
  }

  /// Sort by join date
  List<UserModel> sortByJoinDate({bool ascending = false}) {
    final sorted = List<UserModel>.from(users);
    sorted.sort(
      (a, b) => ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt),
    );
    return sorted;
  }

  /// Sort by last login
  List<UserModel> sortByLastLogin({bool ascending = false}) {
    final sorted = List<UserModel>.from(users);
    sorted.sort((a, b) {
      final aDate = a.lastLogin ?? a.createdAt;
      final bDate = b.lastLogin ?? b.createdAt;
      return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
    });
    return sorted;
  }

  /// Get statistics
  UserStatistics getStatistics({
    int totalTrips = 0,
    double totalDistance = 0,
    double totalDuration = 0,
    int totalSavedPlaces = 0,
    int totalFavoritePlaces = 0,
    double averageSpeed = 0,
    double maxSpeed = 0,
    double totalFuelCost = 0,
    int activeDays = 0,
    DateTime? lastTripDate,
  }) {
    return UserStatistics(
      totalTrips: totalTrips,
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      totalSavedPlaces: totalSavedPlaces,
      totalFavoritePlaces: totalFavoritePlaces,
      averageTripDistance: totalTrips > 0 ? totalDistance / totalTrips : 0,
      averageTripDuration: totalTrips > 0 ? totalDuration / totalTrips : 0,
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
      totalFuelCost: totalFuelCost,
      activeDays: activeDays,
      lastTripDate: lastTripDate,
    );
  }

  /// Get total users count
  int get totalUsers => users.length;

  /// Get active users count
  int get activeUsersCount => activeUsers.length;

  /// Get admin users count
  int get adminUsersCount => adminUsers.length;

  /// Get users by role count
  int getByRoleCount(UserRole role) {
    return getByRole(role).length;
  }

  /// Get users by status count
  int getByStatusCount(UserStatus status) {
    return getByStatus(status).length;
  }
}

// ============ EXTENSION ============

extension UserModelExtension on UserModel {
  /// Check if user is authenticated
  bool get isAuthenticated => id.isNotEmpty && email.isNotEmpty;

  /// Get user display name or fallback
  String displayNameOrFallback(String fallback) {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    return fallback;
  }

  /// Get user avatar color based on email
  Color get avatarColor {
    final hash = email.hashCode;
    final hue = (hash % 360) / 360;
    return HSLColor.fromAHSL(1, hue, 0.5, 0.6).toColor();
  }

  /// Get user initials with fallback
  String initialsOrFallback(String fallback) {
    if (displayName != null && displayName!.isNotEmpty) {
      return Helpers.getInitials(displayName!);
    }
    return fallback;
  }
}
