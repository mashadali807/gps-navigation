import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:smart_route/providers/trip_provider.dart';
import 'package:smart_route/screens/auth/forget_password_screen.dart';
import 'package:smart_route/services/storage_services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/firebase_config.dart';
import 'config/supabase_config.dart';
import 'providers/location_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/map_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/trips/trip_history_screen.dart';
import 'screens/trips/trip_detail_screen.dart';
import 'screens/navigation/route_preview_screen.dart';
import 'screens/navigation/navigation_screen.dart';
import 'models/route_model.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseConfig.initialize();
    await SupabaseConfig.initialize();
    await Hive.initFlutter();

    final storageService = StorageService();
    await storageService.initialize();
  } catch (e) {
    log('❌ Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => MapProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => NavigationProvider(), lazy: true),
        ChangeNotifierProvider(
          create: (_) => TripProvider(),
          lazy: true, // Add this
        ),
        Provider<StorageService>.value(value: StorageService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            theme: themeProvider.themeData,
            darkTheme: themeProvider.darkThemeData,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

// ============ ROUTER CONFIGURATION ============

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Main App Routes
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // Search Routes
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchScreen(),
    ),

    // Profile Routes
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      name: 'edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // Trip Routes
    GoRoute(
      path: '/trips',
      name: 'trips',
      builder: (context, state) => const TripHistoryScreen(),
    ),
    GoRoute(
      path: '/trip/:id',
      name: 'trip-detail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return TripDetailScreen(tripId: id);
      },
    ),

    // Navigation Routes
    GoRoute(
      path: '/route-preview',
      name: 'route-preview',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final route = extra?['route'] as RouteModel?;
        final alternatives = extra?['alternatives'] as List<RouteModel>?;
        if (route == null) {
          return const Scaffold(
            body: Center(
              child: Text('No route provided', style: TextStyle(fontSize: 16)),
            ),
          );
        }
        return RoutePreviewScreen(
          route: route,
          alternativeRoutes: alternatives,
        );
      },
    ),
    GoRoute(
      path: '/navigation',
      name: 'navigation',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final destination = extra?['destination'] as LatLng?;
        final route = extra?['route'] as RouteModel?;
        if (destination == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No destination provided',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        return NavigationScreen(destination: destination, route: route);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Page Not Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The page you are looking for does not exist.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
  redirect: (context, state) {
    // Check if user is authenticated
    try {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final currentLocation = state.matchedLocation;

      // Public routes that don't require authentication
      const publicRoutes = [
        '/',
        '/onboarding',
        '/login',
        '/register',
        '/forgot-password',
      ];

      // If authenticated and trying to access auth routes, redirect to home
      if (isAuthenticated && publicRoutes.contains(currentLocation)) {
        return '/home';
      }

      // If not authenticated and trying to access protected routes
      if (!isAuthenticated &&
          !publicRoutes.contains(currentLocation) &&
          currentLocation != '/') {
        return '/login';
      }

      return null;
    } catch (e) {
      // If auth provider is not initialized, don't redirect
      return null;
    }
  },
);

// ============ ROUTE NAVIGATION EXTENSIONS ============

extension RouteNavigation on BuildContext {
  /// Navigate to a route by name
  void goTo(String routeName, {Map<String, dynamic>? extra}) {
    go(routeName, extra: extra);
  }

  /// Navigate to home
  void goToHome() => go('/home');

  /// Navigate to login
  void goToLogin() => go('/login');

  /// Navigate to register
  void goToRegister() => go('/register');

  /// Navigate to onboarding
  void goToOnboarding() => go('/onboarding');

  /// Navigate to forgot password
  void goToForgotPassword() => go('/forgot-password');

  /// Navigate to profile
  void goToProfile() => go('/profile');

  /// Navigate to edit profile
  void goToEditProfile() => go('/profile/edit');

  /// Navigate to settings
  void goToSettings() => go('/settings');

  /// Navigate to search
  void goToSearch() => go('/search');

  /// Navigate to trips
  void goToTrips() => go('/trips');

  /// Navigate to trip detail
  void goToTripDetail(String tripId) => go('/trip/$tripId');

  /// Navigate to route preview
  void goToRoutePreview({
    required RouteModel route,
    List<RouteModel>? alternatives,
  }) {
    go('/route-preview', extra: {'route': route, 'alternatives': alternatives});
  }

  /// Navigate to navigation
  void goToNavigation({required LatLng destination, RouteModel? route}) {
    go('/navigation', extra: {'destination': destination, 'route': route});
  }

  /// Push a new route (keeps previous route in stack)
  void pushTo(String routeName, {Map<String, dynamic>? extra}) {
    push(routeName, extra: extra);
  }

  /// Pop the current route
  void popRoute() => pop();

  /// Go back to previous route
  void goBack() => pop();

  /// Replace current route
  void replaceWith(String routeName, {Map<String, dynamic>? extra}) {
    replace(routeName, extra: extra);
  }
}

// ============ ERROR BOUNDARY ============

class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      // You can add error handling widgets here
    );
  }
}

// ============ APP INITIALIZATION LOGGER ============

void log(String message) {
  // Use a constant to check debug mode
  const bool isDebugMode = true; // Set to false for release builds
  if (isDebugMode) {
    print(message);
  }
}
