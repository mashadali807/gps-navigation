import 'package:flutter/material.dart';
import 'package:smart_route/core/utills/helpers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/location_model.dart';

class LocationInfoWidget extends StatelessWidget {
  final LocationModel? location;
  final String? address;
  final double? speed;
  final double? accuracy;
  final VoidCallback? onTap;

  const LocationInfoWidget({
    super.key,
    this.location,
    this.address,
    this.speed,
    this.accuracy,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
          children: [
            // Location Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.location_on,
                color: theme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            
            // Location Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address ?? 'Current Location',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (speed != null && speed! > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.speed,
                              size: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppConstants.formatSpeed(speed!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      if (speed != null && speed! > 0 && accuracy != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                        ),
                      if (accuracy != null)
                        Row(
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              size: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '±${accuracy!.toStringAsFixed(0)}m',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Last Updated
            if (location?.timestamp != null)
              Text(
                Helpers.timeAgo(location!.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
            
            const SizedBox(width: AppConstants.paddingSmall),
            
            // Toggle Button
            Icon(
              Icons.keyboard_arrow_down,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}