import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_widget.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import '../trips/trip_history_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser == null) {
        await authProvider.initialize();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToEditProfile() {
    context.go('/profile/edit');
  }

  void _navigateToSettings() {
    context.go('/settings');
  }

  void _navigateToTripHistory() {
    context.go('/trips');
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        final success = await authProvider.logout();

        setState(() {
          _isLoading = false;
        });

        if (success && mounted) {
          // Navigate to login screen and clear the entire stack
          context.go('/login');

          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final locationProvider = context.watch<LocationProvider>();

    // If user is not authenticated, redirect to login
    if (!authProvider.isAuthenticated && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: LoadingWidget(
            message: 'Loading profile...',
            style: LoadingStyle.spinner,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            // Check if there's a previous route to go back to
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If no previous route, go to home
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: _navigateToSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(theme, isDark, user),

              const SizedBox(height: AppConstants.paddingLarge),

              // Stats Cards
              _buildStatsCards(theme, isDark, user, locationProvider),

              const SizedBox(height: AppConstants.paddingLarge),

              // Menu Items
              _buildMenuItems(theme, isDark),

              const SizedBox(height: AppConstants.paddingLarge),

              // Logout Button
              _buildLogoutButton(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isDark, dynamic user) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _navigateToEditProfile,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          user?.initials ?? 'U',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey[900]! : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().scale(
            duration: AppConstants.durationMedium,
            curve: Curves.easeOutBack,
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Name
          Text(
            user?.displayName ?? 'User',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(
            duration: AppConstants.durationMedium,
            delay: 100.ms,
          ),

          const SizedBox(height: AppConstants.paddingSmall),

          // Email
          Text(
            user?.email ?? 'No email',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ).animate().fadeIn(
            duration: AppConstants.durationMedium,
            delay: 200.ms,
          ),

          const SizedBox(height: AppConstants.paddingSmall),

          // Joined Date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                'Joined ${user?.joinDate ?? 'N/A'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.circle,
                size: 6,
                color: isDark ? Colors.grey[600] : Colors.grey[300],
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.check_circle,
                size: 14,
                color: user?.isEmailVerified ?? false
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                user?.isEmailVerified ?? false ? 'Verified' : 'Unverified',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: user?.isEmailVerified ?? false
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ],
          ).animate().fadeIn(
            duration: AppConstants.durationMedium,
            delay: 300.ms,
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _navigateToEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.paddingMedium,
                ),
              ),
            ),
          ).animate().fadeIn(
            duration: AppConstants.durationMedium,
            delay: 400.ms,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    ThemeData theme,
    bool isDark,
    dynamic user,
    LocationProvider locationProvider,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            isDark,
            'Trips',
            '12', // Replace with actual trip count
            Icons.route,
            Colors.blue,
          ),
        ),
        const SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: _buildStatCard(
            theme,
            isDark,
            'Distance',
            '1,234 km', // Replace with actual distance
            Icons.straighten,
            Colors.green,
          ),
        ),
        const SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: _buildStatCard(
            theme,
            isDark,
            'Saved',
            '8', // Replace with actual saved places
            Icons.bookmark,
            Colors.orange,
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 500.ms);
  }

  Widget _buildStatCard(
    ThemeData theme,
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(ThemeData theme, bool isDark) {
    final menuItems = [
      _MenuItem(
        icon: Icons.history,
        label: 'Trip History',
        subtitle: 'View your past trips',
        onTap: _navigateToTripHistory,
        color: Colors.blue,
      ),
      _MenuItem(
        icon: Icons.bookmark,
        label: 'Saved Places',
        subtitle: 'Your favorite locations',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved places feature coming soon!')),
          );
        },
        color: Colors.green,
      ),
      _MenuItem(
        icon: Icons.notifications,
        label: 'Notifications',
        subtitle: 'Manage your alerts',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications feature coming soon!')),
          );
        },
        color: Colors.orange,
      ),
      _MenuItem(
        icon: Icons.security,
        label: 'Privacy & Security',
        subtitle: 'Manage your privacy settings',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Privacy settings feature coming soon!'),
            ),
          );
        },
        color: Colors.purple,
      ),
      _MenuItem(
        icon: Icons.help_outline,
        label: 'Help & Support',
        subtitle: 'Get help and support',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Help & Support feature coming soon!'),
            ),
          );
        },
        color: Colors.teal,
      ),
    ];

    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      child: Column(
        children: menuItems.map((item) {
          return _buildMenuItem(theme, isDark, item, item == menuItems.last);
        }).toList(),
      ),
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 600.ms);
  }

  Widget _buildMenuItem(
    ThemeData theme,
    bool isDark,
    _MenuItem item,
    bool isLast,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color.withOpacity(0.1),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          title: Text(item.label, style: theme.textTheme.titleMedium),
          subtitle: Text(
            item.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
          onTap: item.onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
          ),
        ),
        if (!isLast)
          Divider(
            height: 0,
            thickness: 0.5,
            color: isDark ? Colors.grey[700] : Colors.grey[200],
            indent: 56,
          ),
      ],
    );
  }

  Widget _buildLogoutButton(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(
          'Logout',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingMedium,
          ),
          side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 700.ms);
  }
}

// ============ MENU ITEM MODEL ============

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });
}
