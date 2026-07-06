import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _locationTracking = true;
  bool _saveHistory = true;
  bool _compassEnabled = true;
  bool _showTraffic = true;
  bool _offlineMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Load from preferences in a real app
    // For now, use defaults
  }

  void _toggleTheme() {
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
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
              context.go('/profile');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          children: [
            // Appearance
            _buildSection(theme, isDark, 'Appearance', [
              _buildSwitchTile(
                theme,
                isDark,
                'Dark Mode',
                'Switch between light and dark theme',
                themeProvider.isDarkMode,
                (value) => _toggleTheme(),
                Icons.dark_mode,
              ),
              _buildSwitchTile(
                theme,
                isDark,
                'Material 3',
                'Use Material 3 design',
                themeProvider.isMaterial3,
                (value) => themeProvider.toggleMaterial3(),
                Icons.design_services,
              ),
              _buildSwitchTile(
                theme,
                isDark,
                'Glassmorphism',
                'Enable glassmorphic effects',
                themeProvider.useGlassmorphism,
                (value) => themeProvider.toggleGlassmorphism(),
                Icons.blur_on,
              ),
            ]),

            const SizedBox(height: AppConstants.paddingLarge),

            // Navigation
            _buildSection(theme, isDark, 'Navigation', [
              _buildSwitchTile(
                theme,
                isDark,
                'Compass',
                'Show compass on map',
                _compassEnabled,
                (value) => setState(() => _compassEnabled = value),
                Icons.compass_calibration,
              ),
              _buildSwitchTile(
                theme,
                isDark,
                'Show Traffic',
                'Display traffic information',
                _showTraffic,
                (value) => setState(() => _showTraffic = value),
                Icons.traffic,
              ),
              _buildSwitchTile(
                theme,
                isDark,
                'Offline Mode',
                'Cache maps for offline use',
                _offlineMode,
                (value) => setState(() => _offlineMode = value),
                Icons.offline_bolt,
              ),
            ]),

            const SizedBox(height: AppConstants.paddingLarge),

            // Privacy
            _buildSection(theme, isDark, 'Privacy & Data', [
              _buildSwitchTile(
                theme,
                isDark,
                'Location Tracking',
                'Allow app to track your location',
                _locationTracking,
                (value) => setState(() => _locationTracking = value),
                Icons.location_on,
              ),
              _buildSwitchTile(
                theme,
                isDark,
                'Save Trip History',
                'Store your trip history',
                _saveHistory,
                (value) => setState(() => _saveHistory = value),
                Icons.history,
              ),
              _buildSwitchTile(
                theme,
                isDark,
                'Notifications',
                'Receive notifications from the app',
                _notifications,
                (value) => setState(() => _notifications = value),
                Icons.notifications,
              ),
            ]),

            const SizedBox(height: AppConstants.paddingLarge),

            // Units
            _buildSection(theme, isDark, 'Units', [
              _buildDropdownTile(
                theme,
                isDark,
                'Distance Unit',
                'Kilometers / Miles',
                ['Kilometers', 'Miles'],
                0,
                Icons.straighten,
              ),
              _buildDropdownTile(
                theme,
                isDark,
                'Speed Unit',
                'km/h / mph',
                ['km/h', 'mph'],
                0,
                Icons.speed,
              ),
            ]),

            const SizedBox(height: AppConstants.paddingLarge),

            // About
            _buildSection(theme, isDark, 'About', [
              _buildInfoTile(
                theme,
                isDark,
                'Version',
                AppConstants.appVersion,
                Icons.info_outline,
              ),
              _buildInfoTile(
                theme,
                isDark,
                'App Name',
                AppConstants.appName,
                Icons.apps,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    bool isDark,
    String title,
    List<Widget> children,
  ) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    bool isDark,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.primaryColor.withOpacity(0.1),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 18),
      ),
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.primaryColor,
        activeTrackColor: theme.primaryColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildDropdownTile(
    ThemeData theme,
    bool isDark,
    String title,
    String subtitle,
    List<String> items,
    int selectedIndex,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.primaryColor.withOpacity(0.1),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 18),
      ),
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      trailing: DropdownButton<int>(
        value: selectedIndex,
        onChanged: (value) {},
        dropdownColor: isDark ? Colors.grey[800] : Colors.white,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        items: items.asMap().entries.map((entry) {
          return DropdownMenuItem(value: entry.key, child: Text(entry.value));
        }).toList(),
      ),
    );
  }

  Widget _buildInfoTile(
    ThemeData theme,
    bool isDark,
    String title,
    String value,
    IconData icon,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.primaryColor.withOpacity(0.1),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 18),
      ),
      title: Text(title, style: theme.textTheme.bodyMedium),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }
}
