import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

// Define the QuickAction enum here
enum QuickAction { search, saved, trips, profile }

// Helper class for display data
class QuickActionData {
  final String label;
  final IconData icon;
  final Color color;
  final QuickAction action;

  const QuickActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.action,
  });
}

class QuickActionsWidget extends StatelessWidget {
  final void Function(QuickAction) onActionTap;
  final VoidCallback onShowMore;

  const QuickActionsWidget({
    super.key,
    required this.onActionTap,
    required this.onShowMore,
  });

  static const List<QuickActionData> _actions = [
    QuickActionData(
      label: 'Search',
      icon: Icons.search,
      color: Colors.blue,
      action: QuickAction.search,
    ),
    QuickActionData(
      label: 'Saved',
      icon: Icons.bookmark,
      color: Colors.green,
      action: QuickAction.saved,
    ),
    QuickActionData(
      label: 'Trips',
      icon: Icons.history,
      color: Colors.orange,
      action: QuickAction.trips,
    ),
    QuickActionData(
      label: 'Profile',
      icon: Icons.person,
      color: Colors.purple,
      action: QuickAction.profile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ..._actions.map(
            (action) => _buildActionButton(
              action: action,
              theme: theme,
              isDark: isDark,
            ),
          ),
          _buildMoreButton(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required QuickActionData action,
    required ThemeData theme,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => onActionTap(action.action),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: action.color.withOpacity(0.1),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: AppConstants.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton(ThemeData theme, bool isDark) {
    return InkWell(
      onTap: onShowMore,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.grey[700] : Colors.grey[200],
              ),
              child: Icon(
                Icons.more_horiz,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'More',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: AppConstants.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
