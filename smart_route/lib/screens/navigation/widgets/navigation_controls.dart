import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class NavigationControls extends StatelessWidget {
  final VoidCallback onEnd;
  final VoidCallback onRecenter;
  final VoidCallback? onToggleSteps;
  final VoidCallback? onMute;
  final bool isMuted;

  const NavigationControls({
    super.key,
    required this.onEnd,
    required this.onRecenter,
    this.onToggleSteps,
    this.onMute,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildControlButton(
            theme,
            Icons.close,
            'End',
            onEnd,
            isDark,
            color: Colors.red,
          ),
          _buildControlButton(
            theme,
            Icons.location_searching,
            'Recenter',
            onRecenter,
            isDark,
            color: Colors.blue,
          ),
          if (onToggleSteps != null)
            _buildControlButton(
              theme,
              Icons.info_outline,
              'Steps',
              onToggleSteps!,
              isDark,
              color: Colors.orange,
            ),
          if (onMute != null)
            _buildControlButton(
              theme,
              isMuted ? Icons.volume_off : Icons.volume_up,
              isMuted ? 'Unmute' : 'Mute',
              onMute!,
              isDark,
              color: isMuted ? Colors.grey : theme.primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    ThemeData theme,
    IconData icon,
    String label,
    VoidCallback onPressed,
    bool isDark, {
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingSmall,
          vertical: AppConstants.paddingSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (color ?? theme.primaryColor).withOpacity(0.1),
              ),
              child: Icon(icon, color: color ?? theme.primaryColor, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color ?? theme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: AppConstants.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
