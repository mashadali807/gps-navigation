import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Live GPS Tracking',
      description:
          'Track your location in real-time with high accuracy GPS technology. Never lose your way again.',
      icon: Icons.gps_fixed,
      imageAsset: 'assets/images/onboarding/gps_tracking.svg',
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Smart Navigation',
      description:
          'Get turn-by-turn directions with real-time traffic updates. Find the fastest route to your destination.',
      icon: Icons.navigation,
      imageAsset: 'assets/images/onboarding/navigation.svg',
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Save Your Places',
      description:
          'Bookmark your favorite locations, save trips, and access them anytime. Your journey, your way.',
      icon: Icons.favorite,
      imageAsset: 'assets/images/onboarding/save_places.svg',
      color: Colors.purple,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  void _navigateToRegister() {
    context.push('/register');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: AppConstants.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(context, _pages[index], isDark, size);
                },
              ),
            ),

            // Bottom Section
            _buildBottomSection(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    OnboardingPage page,
    bool isDark,
    Size size,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image/Icon Container
          Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      page.color.withOpacity(0.2),
                      page.color.withOpacity(0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.color.withOpacity(0.1),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    page.icon,
                    size: size.width * 0.2,
                    color: page.color,
                  ),
                ),
              )
              .animate()
              .scale(
                duration: AppConstants.durationMedium,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: AppConstants.durationMedium),

          const SizedBox(height: AppConstants.paddingExtraLarge),

          // Title
          Text(
                page.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: AppConstants.durationMedium, delay: 200.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: AppConstants.durationMedium,
                delay: 200.ms,
              ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Description
          Text(
                page.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
              .animate()
              .fadeIn(duration: AppConstants.durationMedium, delay: 300.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: AppConstants.durationMedium,
                delay: 300.ms,
              ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey[100]!,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dot Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildDotIndicator(index),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              if (_currentPage > 0) _buildBackButton(theme, isDark),

              const Spacer(),

              // Next/Get Started Button
              _buildNextButton(theme, isDark),
            ],
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Register Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: AppConstants.fontSizeMedium,
                ),
              ),
              TextButton(
                onPressed: _navigateToLogin,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: AppConstants.fontSizeMedium,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(
            duration: AppConstants.durationMedium,
            delay: 400.ms,
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    final isActive = index == _currentPage;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive
            ? theme.primaryColor
            : theme.primaryColor.withOpacity(0.3),
      ),
    ).animate().scale(
      duration: AppConstants.durationShort,
      curve: Curves.easeInOut,
    );
  }

  Widget _buildBackButton(ThemeData theme, bool isDark) {
    return OutlinedButton.icon(
          onPressed: _previousPage,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back'),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.paddingMedium,
            ),
            side: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 300.ms)
        .slideX(
          begin: -0.2,
          end: 0,
          duration: AppConstants.durationMedium,
          delay: 300.ms,
        );
  }

  Widget _buildNextButton(ThemeData theme, bool isDark) {
    final isLastPage = _currentPage == _pages.length - 1;

    return ElevatedButton.icon(
          onPressed: _nextPage,
          icon: isLastPage
              ? const Icon(Icons.arrow_forward_rounded, size: 18)
              : const Icon(Icons.arrow_forward, size: 18),
          label: Text(
            isLastPage ? 'Get Started' : 'Next',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.paddingMedium,
            ),
            elevation: 0,
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 300.ms)
        .slideX(
          begin: 0.2,
          end: 0,
          duration: AppConstants.durationMedium,
          delay: 300.ms,
        );
  }
}

// ============ ONBOARDING PAGE MODEL ============

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final String imageAsset;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.imageAsset,
    required this.color,
  });
}

// ============ ROUTE NAVIGATION ============

extension OnboardingRoute on BuildContext {
  void navigateToOnboarding() {
    this.go('/onboarding');
  }
}
