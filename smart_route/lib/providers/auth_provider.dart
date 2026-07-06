import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:smart_route/core/utills/helpers.dart';
import 'package:smart_route/services/storage_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  AuthStatus _status = AuthStatus.uninitialized;

  // ============ GETTERS ============

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  AuthStatus get status => _status;
  bool get isGuest => _currentUser == null;

  // ============ INITIALIZATION ============

  Future<void> initialize() async {
    try {
      _isLoading = true;
      _status = AuthStatus.loading;
      notifyListeners();

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _loadUserFromFirebase(user);
      } else {
        final savedUser = await _loadSavedUser();
        if (savedUser != null) {
          _currentUser = savedUser;
          _isAuthenticated = true;
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      }
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============ AUTHENTICATION METHODS ============

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      final userModel = UserModel.fromFirebase(userCredential.user!);
      await _saveUserToSupabase(userModel);
      await _saveUserLocally(userModel);

      _currentUser = userModel;
      _isAuthenticated = true;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _loadUserFromFirebase(userCredential.user!);
      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      await _loadUserFromFirebase(userCredential.user!);
      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> loginAsGuest() async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _firebaseAuth.signInAnonymously();

      final guestUser = UserModel(
        id: userCredential.user!.uid,
        email: 'guest@example.com',
        displayName: 'Guest User',
        isEmailVerified: false,
        role: UserRole.user,
        status: UserStatus.active,
      );

      await _saveUserLocally(guestUser);

      _currentUser = guestUser;
      _isAuthenticated = true;
      _status = AuthStatus.authenticated;
      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      _setLoading(true);
      _clearError();

      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await _clearUserData();

      _currentUser = null;
      _isAuthenticated = false;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();

      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.delete();

      await _supabaseClient.from('users').delete().eq('id', user.uid);

      await _clearUserData();

      _currentUser = null;
      _isAuthenticated = false;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        throw Exception('No user logged in');
      }

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
        await user.reload();
      }

      final updatedUser = _currentUser!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        bio: bio,
        updatedAt: DateTime.now(),
      );

      await _supabaseClient
          .from('users')
          .update(updatedUser.toJson())
          .eq('id', _currentUser!.id);

      await _saveUserLocally(updatedUser);

      _currentUser = updatedUser;
      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      _setLoading(false);
      notifyListeners();

      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  // ============ PRIVATE METHODS ============

  Future<void> _loadUserFromFirebase(User firebaseUser) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('id', firebaseUser.uid)
          .maybeSingle();

      if (response != null) {
        _currentUser = UserModel.fromJson(response);
      } else {
        final userModel = UserModel.fromFirebase(firebaseUser);
        await _saveUserToSupabase(userModel);
        _currentUser = userModel;
      }

      await _supabaseClient
          .from('users')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', firebaseUser.uid);

      await _saveUserLocally(_currentUser!);

      _isAuthenticated = true;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<void> _saveUserToSupabase(UserModel user) async {
    try {
      await _supabaseClient.from('users').upsert(user.toJson());
    } catch (e) {
      print('Error saving user to Supabase: $e');
      rethrow;
    }
  }

  Future<void> _saveUserLocally(UserModel user) async {
    try {
      await _storageService.saveUser(user);
      await _secureStorage.write(key: 'user_id', value: user.id);
    } catch (e) {
      print('Error saving user locally: $e');
    }
  }

  Future<UserModel?> _loadSavedUser() async {
    try {
      final userId = await _secureStorage.read(key: 'user_id');
      if (userId == null) return null;

      final user = await _storageService.getUser();
      return user;
    } catch (e) {
      print('Error loading saved user: $e');
      return null;
    }
  }

  Future<void> _clearUserData() async {
    try {
      await _secureStorage.delete(key: 'user_id');
      await _secureStorage.delete(key: 'user_data');
      await _storageService.deleteUser();
      await _storageService.clearAllPlaces();
      await _storageService.clearAllTrips();
      await _storageService.clearCache();
      await _storageService.clearLocationHistory();
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _handleError(dynamic error) {
    _error = error.toString();
    _status = AuthStatus.error;
    _isLoading = false;
    notifyListeners();
    Helpers.logError(error, tag: 'AuthProvider');
  }

  // ============ STREAM LISTENERS ============

  void listenToAuthChanges() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user == null) {
        _currentUser = null;
        _isAuthenticated = false;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else if (_currentUser?.id != user.uid) {
        _loadUserFromFirebase(user).then((_) {
          notifyListeners();
        });
      }
    });
  }

  // ============ SUPABASE REALTIME ============

  void subscribeToUserUpdates() {
    if (_currentUser == null) return;

    _supabaseClient
        .channel('user_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentUser!.id,
          ),
          callback: (payload) {
            final changes = payload.newRecord;
            if (changes != null && changes.isNotEmpty) {
              _currentUser = UserModel.fromJson(changes);
              _storageService.saveUser(_currentUser!);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  // ============ DISPOSE ============

  @override
  void dispose() {
    // Clean up subscriptions
    _supabaseClient.removeAllChannels();
    super.dispose();
  }
}

// ============ AUTH STATUS ENUM ============

enum AuthStatus {
  uninitialized,
  loading,
  authenticated,
  unauthenticated,
  error,
}

// ============ AUTH PROVIDER EXTENSIONS ============

extension AuthProviderExtension on BuildContext {
  AuthProvider get auth => Provider.of<AuthProvider>(this, listen: false);

  AuthProvider watchAuth() => Provider.of<AuthProvider>(this, listen: true);

  bool get isAuthenticated => auth.isAuthenticated;
  UserModel? get currentUser => auth.currentUser;
  bool get isGuest => auth.isGuest;
  bool get isAdmin => auth.currentUser?.isAdmin ?? false;
}

// ============ AUTH GUARD ============

class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget? unauthenticatedWidget;
  final Widget? loadingWidget;

  const AuthGuard({
    super.key,
    required this.child,
    this.unauthenticatedWidget,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.loading ||
        auth.status == AuthStatus.uninitialized) {
      return loadingWidget ??
          const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.status == AuthStatus.unauthenticated) {
      return unauthenticatedWidget ?? const SizedBox.shrink();
    }

    if (auth.status == AuthStatus.error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                auth.error ?? 'Authentication error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => auth.initialize(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}

// ============ ROLE GUARD ============

class RoleGuard extends StatelessWidget {
  final Widget child;
  final UserRole requiredRole;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.child,
    required this.requiredRole,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.currentUser;

    if (user == null) {
      return fallback ?? const SizedBox.shrink();
    }

    final hasAccess = _hasRequiredRole(user.role, requiredRole);

    if (!hasAccess) {
      return fallback ?? const SizedBox.shrink();
    }

    return child;
  }

  bool _hasRequiredRole(UserRole userRole, UserRole requiredRole) {
    final roleLevels = {
      UserRole.user: 0,
      UserRole.moderator: 1,
      UserRole.admin: 2,
    };

    return (roleLevels[userRole] ?? 0) >= (roleLevels[requiredRole] ?? 0);
  }
}
