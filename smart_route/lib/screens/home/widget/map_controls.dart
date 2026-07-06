import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onLocateMe;
  final VoidCallback onCompass;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final bool isFollowing;

  const MapControls({
    super.key,
    required this.onLocateMe,
    required this.onCompass,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildControlButton(
            icon: isFollowing ? Icons.gps_fixed : Icons.gps_off,
            onTap: onLocateMe,
            color: isFollowing ? theme.primaryColor : null,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildControlButton(
            icon: Icons.north,
            onTap: onCompass,
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildControlButton(icon: Icons.add, onTap: onZoomIn, isDark: isDark),
          _buildDivider(isDark),
          _buildControlButton(
            icon: Icons.remove,
            onTap: onZoomOut,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: color ?? (isDark ? Colors.white70 : Colors.black87),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 0,
      thickness: 0.5,
      color: isDark ? Colors.grey[700] : Colors.grey[200],
      indent: 8,
      endIndent: 8,
    );
  }
}
