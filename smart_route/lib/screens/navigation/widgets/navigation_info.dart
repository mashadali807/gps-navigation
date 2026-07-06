import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class NavigationInfoWidget extends StatelessWidget {
  final double? distance;
  final double? duration;
  final double? speed;
  final String? nextInstruction;
  final double? nextInstructionDistance;

  const NavigationInfoWidget({
    super.key,
    this.distance,
    this.duration,
    this.speed,
    this.nextInstruction,
    this.nextInstructionDistance,
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                theme,
                Icons.route,
                distance != null
                    ? AppConstants.formatDistance(distance!)
                    : '--',
                'Distance',
                isDark,
              ),
              _buildInfoItem(
                theme,
                Icons.timer,
                duration != null
                    ? AppConstants.formatDuration(duration!)
                    : '--',
                'Time',
                isDark,
              ),
              _buildInfoItem(
                theme,
                Icons.speed,
                speed != null ? AppConstants.formatSpeed(speed!) : '--',
                'Speed',
                isDark,
              ),
            ],
          ),
          if (nextInstruction != null) ...[
            const SizedBox(height: AppConstants.paddingMedium),
            Row(
              children: [
                Icon(Icons.turn_right, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nextInstruction!,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (nextInstructionDistance != null)
                  Text(
                    AppConstants.formatDistance(nextInstructionDistance!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
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
    );
  }
}
