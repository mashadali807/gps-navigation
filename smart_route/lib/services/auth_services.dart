import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ============ AUTH STATE STREAMS ============

  /// Stream of auth state changes from Firebase
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Stream of ID token changes
  Stream<User?> get idTokenChanges => _firebaseAuth.idTokenChanges();

  /// Get current Firebase user
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentFirebaseUser != null;

  // ============ AUTHENTICATION METHODS ============

  /// Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update user profile with name
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      // Create user in Supabase
      final userModel = UserModel.fromFirebase(userCredential.user!);
      await _createUserInSupabase(userModel);

      // Save user locally
      await _saveUserLocally(userModel);

      return userCredential;
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.registerWithEmail');
      rethrow;
    }
  }

  /// Login with email and password
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update last login
      await _updateLastLogin(userCredential.user!);

      // Load user from Supabase
      await _loadUserFromFirebase(userCredential.user!);

      return userCredential;
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.loginWithEmail');
      rethrow;
    }
  }

  /// Login with Google
  Future<UserCredential> loginWithGoogle() async {
    try {
      // Sign out from Google to ensure fresh sign-in
      await _googleSignIn.signOut();

      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Get authentication details
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Check if user exists in Supabase, if not create
      await _loadUserFromFirebase(userCredential.user!);

      return userCredential;
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.loginWithGoogle');
      rethrow;
    }
  }

  /// Login as guest (anonymous)
  Future<UserCredential> loginAsGuest() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();

      // Create guest user in local storage
      final guestUser = UserModel(
        id: userCredential.user!.uid,
        email: 'guest@example.com',
        displayName: 'Guest User',
        isEmailVerified: false,
        role: UserRole.user,
        status: UserStatus.active,
      );

      await _saveUserLocally(guestUser);

      return userCredential;
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.loginAsGuest');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.sendPasswordResetEmail');
      rethrow;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      await user.sendEmailVerification();
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.sendEmailVerification');
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear local data
      await _clearUserData();
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.logout');
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Delete from Supabase
      await _supabaseClient.from('users').delete().eq('id', user.uid);

      // Delete from Firebase
      await user.delete();

      // Clear local data
      await _clearUserData();
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.deleteAccount');
      rethrow;
    }
  }

  // ============ PROFILE MANAGEMENT ============

  /// Update user profile
  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Update in Firebase
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload();

      // Get current user model
      final currentUser = await _getCurrentUserModel();

      // Update in Supabase
      // Check if currentUser is not null first
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final updatedUser = currentUser!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        bio: bio,
        updatedAt: DateTime.now(),
      );

      await _supabaseClient
          .from('users')
          .update(updatedUser.toJson())
          .eq('id', user.uid);

      // Update local
      await _saveUserLocally(updatedUser);

      return updatedUser;
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.updateProfile');
      rethrow;
    }
  }

  Future<UserModel?> _getCurrentUserModel() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await _getUserModel(user.uid);
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.changePassword');
      rethrow;
    }
  }

  /// Update email (requires re-authentication)
  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updateEmail(newEmail);

      // Update in Supabase
      await _supabaseClient
          .from('users')
          .update({'email': newEmail})
          .eq('id', user.uid);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.updateEmail');
      rethrow;
    }
  }

  // ============ USER DATA MANAGEMENT ============

  /// Get current user model from Supabase or local
  Future<UserModel?> getCurrentUserModel() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      return await _getUserModel(user.uid);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.getCurrentUserModel');
      return null;
    }
  }

  /// Get user model by ID
  Future<UserModel?> getUserModel(String userId) async {
    return await _getUserModel(userId);
  }

  Future<UserModel?> _getUserModel(String userId) async {
    try {
      // Try to get from Supabase
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }

      // Try local storage
      return await _getUserFromLocal();
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService._getUserModel');
      return null;
    }
  }

  Future<void> _loadUserFromFirebase(User firebaseUser) async {
    try {
      // Try to get user from Supabase
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('id', firebaseUser.uid)
          .maybeSingle();

      if (response != null) {
        // User exists in Supabase
        final userModel = UserModel.fromJson(response);
        await _saveUserLocally(userModel);
      } else {
        // Create user in Supabase
        final userModel = UserModel.fromFirebase(firebaseUser);
        await _createUserInSupabase(userModel);
        await _saveUserLocally(userModel);
      }

      // Update last login
      await _updateLastLogin(firebaseUser);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService._loadUserFromFirebase');
      rethrow;
    }
  }

  Future<void> _createUserInSupabase(UserModel user) async {
    try {
      await _supabaseClient
          .from('users')
          .upsert(user.toJson(), onConflict: 'id');
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService._createUserInSupabase');
      rethrow;
    }
  }

  Future<void> _updateLastLogin(User user) async {
    try {
      await _supabaseClient
          .from('users')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', user.uid);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService._updateLastLogin');
    }
  }

  // ============ LOCAL STORAGE ============

  Future<void> _saveUserLocally(UserModel user) async {
    try {
      await _secureStorage.write(
        key: 'user_data',
        value: user.toJson().toString(),
      );
      await _secureStorage.write(key: 'user_id', value: user.id);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService._saveUserLocally');
    }
  }

  Future<UserModel?> _getUserFromLocal() async {
    try {
      final userId = await _secureStorage.read(key: 'user_id');
      if (userId == null) return null;

      final userData = await _secureStorage.read(key: 'user_data');
      if (userData == null) return null;

      final Map<String, dynamic> json = Map<String, dynamic>.from(
        userData as Map,
      );
      return UserModel.fromJson(json);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService._getUserFromLocal');
      return null;
    }
  }

  Future<void> _clearUserData() async {
    try {
      await _secureStorage.delete(key: 'user_data');
      await _secureStorage.delete(key: 'user_id');
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService._clearUserData');
    }
  }

  // ============ REAUTHENTICATION ============

  /// Re-authenticate user
  Future<void> reauthenticateUser(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.reauthenticateUser');
      rethrow;
    }
  }

  /// Re-authenticate with Google
  Future<void> reauthenticateWithGoogle() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.reauthenticateWithGoogle');
      rethrow;
    }
  }

  // ============ TOKEN MANAGEMENT ============

  /// Get Firebase ID token
  Future<String?> getFirebaseToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.getFirebaseToken');
      return null;
    }
  }

  /// Refresh Firebase token
  Future<String?> refreshFirebaseToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(true);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.refreshFirebaseToken');
      return null;
    }
  }

  // ============ SUPABASE AUTH ============

  /// Get Supabase session
  Session? getSupabaseSession() {
    return _supabaseClient.auth.currentSession;
  }

  /// Get Supabase user
  supabase.User? getSupabaseUser() {
    return _supabaseClient.auth.currentUser;
  }

  // ============ USER PREFERENCES ============

  /// Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _supabaseClient
          .from('users')
          .update({'preferences': preferences})
          .eq('id', user.uid);
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.saveUserPreferences');
      rethrow;
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final response = await _supabaseClient
          .from('users')
          .select('preferences')
          .eq('id', user.uid)
          .maybeSingle();

      return response?['preferences'] as Map<String, dynamic>?;
    } catch (e) {
      Helpers.logError(e, tag: 'AuthService.getUserPreferences');
      return null;
    }
  }

  // ============ ERROR HANDLING ============

  /// Get user-friendly error message from Firebase exception
  String getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'network-request-failed':
        return AppConstants.errorNoInternet;
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // ============ CLEANUP ============

  /// Dispose and cleanup
  void dispose() {
    // Nothing to dispose
  }
}

// ============ AUTH SERVICE EXTENSIONS ============

extension AuthServiceExtensions on BuildContext {
  AuthService get authService => AuthService();
}

// ============ AUTH GUARD MIXIN ============

mixin AuthGuardMixin<T extends StatefulWidget> on State<T> {
  final AuthService _authService = AuthService();

  /// Check if user is authenticated
  bool get isAuthenticated => _authService.isLoggedIn;

  /// Require authentication
  Future<bool> requireAuth() async {
    if (!isAuthenticated) {
      // Navigate to login
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return false;
    }
    return true;
  }
}
