import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_route/core/utills/helpers.dart';

import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/constants/app_constants.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isLoading = true;
  String? _error;
  bool _isNavigating = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for animations to complete
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Initialize Auth Provider first
      final authProvider = context.read<AuthProvider>();
      await authProvider.initialize();

      if (!mounted) return;

      // Check if user is authenticated
      if (authProvider.isAuthenticated) {
        // User is logged in - initialize location
        final locationProvider = context.read<LocationProvider>();
        await locationProvider.initialize();
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });

      // Navigate to appropriate screen
      _navigateToScreen();
    } catch (e) {
      Helpers.logError(e, tag: 'SplashScreen');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToScreen() {
    if (_isNavigating) return;
    _isNavigating = true;

    if (_error != null) {
      _showErrorDialog();
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();

      if (!mounted) return;

      // ============================================
      // CHECK IF USER IS ALREADY LOGGED IN
      // ============================================
      if (authProvider.isAuthenticated) {
        // User is logged in - go to Home
        context.go('/home');
        return;
      } else {
        // User is NOT logged in - check first launch
        _checkFirstLaunch();
      }
    } catch (e) {
      Helpers.logError(e, tag: 'SplashScreen._navigateToScreen');
      _isNavigating = false;
    }
  }

  void _checkFirstLaunch() {
    try {
      // Check if user has seen onboarding
      // In a real app, read from SharedPreferences
      final bool seenOnboarding = false; // Replace with actual check

      if (!mounted) return;

      if (seenOnboarding) {
        // User has seen onboarding - go to Login
        context.go('/login');
        return;
      } else {
        // First time user - go to Onboarding
        context.go('/onboarding');
        return;
      }
    } catch (e) {
      Helpers.logError(e, tag: 'SplashScreen._checkFirstLaunch');
      _isNavigating = false;
    }
  }

  void _showErrorDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text(_error ?? 'Failed to initialize app. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _retryInitialize();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _retryInitialize() {
    setState(() {
      _error = null;
      _isLoading = true;
      _isNavigating = false;
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[50]!, Colors.white, Colors.blue[50]!],
          ),
        ),
        child: _error != null
            ? _buildErrorContent(theme)
            : _buildSplashContent(theme, isDark, size),
      ),
    );
  }

  Widget _buildSplashContent(ThemeData theme, bool isDark, Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Icon with animations
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(opacity: _fadeAnimation.value, child: child),
                ),
              );
            },
            child: Container(
              width: size.width * 0.35,
              height: size.width * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.navigation,
                  size: size.width * 0.15,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingExtraLarge),

          // App Name
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(opacity: _fadeAnimation.value, child: child);
            },
            child: Column(
              children: [
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  'Live GPS Tracking & Navigation',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingExtraLarge * 2),

          // Loading indicator
          if (_isLoading)
            const CircularProgressIndicator(strokeWidth: 2)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildErrorContent(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              _error ?? 'Failed to initialize app',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingExtraLarge),
            ElevatedButton.icon(
              onPressed: _retryInitialize,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge,
                  vertical: AppConstants.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ SPLASH SCREEN WITH BACKGROUND ============

class SplashScreenWithBackground extends StatelessWidget {
  final String backgroundImage;

  const SplashScreenWithBackground({super.key, required this.backgroundImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(backgroundImage, fit: BoxFit.cover),

          // Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              ),
            ),
          ),

          // Content
          const SplashScreen(),
        ],
      ),
    );
  }
}

// ============ SPLASH SCREEN WITH ANIMATED LOGO ============

class AnimatedSplashScreen extends StatefulWidget {
  final String logoPath;
  final Duration animationDuration;
  final Widget? child;

  const AnimatedSplashScreen({
    super.key,
    required this.logoPath,
    this.animationDuration = const Duration(seconds: 2),
    this.child,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[900]!, Colors.blue[700]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animation.value,
                    child: Opacity(opacity: _animation.value, child: child),
                  );
                },
                child: Image.asset(widget.logoPath, width: 200, height: 200),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ SPLASH SCREEN ROUTE ============

extension SplashRoute on BuildContext {
  void navigateToSplash() {
    go('/');
  }
}
