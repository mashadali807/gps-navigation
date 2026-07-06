import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import 'loading_widget.dart';

class AppErrorWidget extends StatelessWidget {
  final String? message;
  final String? title;
  final VoidCallback? onRetry;
  final Widget? icon;
  final ErrorType type;
  final bool showRetry;
  final String retryText;
  final Color? color;

  const AppErrorWidget({
    super.key,
    this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.type = ErrorType.general,
    this.showRetry = true,
    this.retryText = 'Try Again',
    this.color,
  });

  factory AppErrorWidget.network({VoidCallback? onRetry, String? message}) {
    return AppErrorWidget(
      type: ErrorType.network,
      onRetry: onRetry,
      message: message ?? AppConstants.errorNoInternet,
      title: 'No Internet Connection',
      icon: const Icon(Icons.wifi_off, size: 80),
    );
  }

  factory AppErrorWidget.server({VoidCallback? onRetry, String? message}) {
    return AppErrorWidget(
      type: ErrorType.server,
      onRetry: onRetry,
      message: message ?? AppConstants.errorServer,
      title: 'Server Error',
      icon: const Icon(Icons.cloud_off, size: 80),
    );
  }

  factory AppErrorWidget.location({VoidCallback? onRetry, String? message}) {
    return AppErrorWidget(
      type: ErrorType.location,
      onRetry: onRetry,
      message: message ?? AppConstants.errorLocationPermission,
      title: 'Location Error',
      icon: const Icon(Icons.location_off, size: 80),
    );
  }

  factory AppErrorWidget.auth({VoidCallback? onRetry, String? message}) {
    return AppErrorWidget(
      type: ErrorType.auth,
      onRetry: onRetry,
      message: message ?? AppConstants.errorAuth,
      title: 'Authentication Error',
      icon: const Icon(Icons.lock_outline, size: 80),
    );
  }

  factory AppErrorWidget.route({VoidCallback? onRetry, String? message}) {
    return AppErrorWidget(
      type: ErrorType.route,
      onRetry: onRetry,
      message: message ?? AppConstants.errorRoute,
      title: 'Route Not Found',
      icon: const Icon(Icons.route_outlined, size: 80),
    );
  }

  factory AppErrorWidget.search({VoidCallback? onRetry, String? message}) {
    return AppErrorWidget(
      type: ErrorType.search,
      onRetry: onRetry,
      message: message ?? AppConstants.errorSearch,
      title: 'No Results Found',
      icon: const Icon(Icons.search_off, size: 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon with Animation
            _buildErrorIcon(theme, isDark),

            const SizedBox(height: AppConstants.paddingLarge),

            // Error Title
            _buildErrorTitle(theme),

            const SizedBox(height: AppConstants.paddingMedium),

            // Error Message
            _buildErrorMessage(theme),

            const SizedBox(height: AppConstants.paddingExtraLarge),

            // Retry Button
            if (showRetry && onRetry != null) _buildRetryButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIcon(ThemeData theme, bool isDark) {
    final defaultIcon = Icon(
      _getErrorIcon(),
      size: 80,
      color: color ?? _getErrorColor(theme),
    );

    return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (color ?? _getErrorColor(theme)).withOpacity(0.1),
          ),
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: icon ?? defaultIcon,
        )
        .animate()
        .scale(duration: AppConstants.durationMedium, curve: Curves.easeOutBack)
        .fadeIn(duration: AppConstants.durationShort);
  }

  Widget _buildErrorTitle(ThemeData theme) {
    return Text(
          title ?? _getDefaultTitle(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? _getErrorColor(theme),
          ),
          textAlign: TextAlign.center,
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 100.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: AppConstants.durationMedium,
          delay: 100.ms,
        );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Text(
      message ?? _getDefaultMessage(),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
      ),
      textAlign: TextAlign.center,
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 200.ms);
  }

  Widget _buildRetryButton(ThemeData theme) {
    return ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(retryText),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.paddingMedium,
            ),
            minimumSize: const Size(200, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            ),
            backgroundColor: color ?? theme.primaryColor,
            foregroundColor: Colors.white,
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 300.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: AppConstants.durationMedium,
          delay: 300.ms,
        );
  }

  IconData _getErrorIcon() {
    switch (type) {
      case ErrorType.network:
        return Icons.signal_wifi_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.location:
        return Icons.location_off;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.route:
        return Icons.route_outlined;
      case ErrorType.search:
        return Icons.search_off;
      case ErrorType.general:
      default:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor(ThemeData theme) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.location:
        return Colors.blue;
      case ErrorType.auth:
        return Colors.purple;
      case ErrorType.route:
        return Colors.amber;
      case ErrorType.search:
        return Colors.grey;
      case ErrorType.general:
      default:
        return theme.colorScheme.error;
    }
  }

  String _getDefaultTitle() {
    switch (type) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.location:
        return 'Location Error';
      case ErrorType.auth:
        return 'Authentication Error';
      case ErrorType.route:
        return 'Route Error';
      case ErrorType.search:
        return 'No Results';
      case ErrorType.general:
      default:
        return 'Something Went Wrong';
    }
  }

  String _getDefaultMessage() {
    switch (type) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.server:
        return 'We\'re having trouble connecting to the server. Please try again later.';
      case ErrorType.location:
        return 'Please enable location services and grant permission to use this feature.';
      case ErrorType.auth:
        return 'Please sign in again to continue.';
      case ErrorType.route:
        return 'Could not find a route to your destination. Please try a different location.';
      case ErrorType.search:
        return 'No locations found. Please try a different search term.';
      case ErrorType.general:
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

// ============ ERROR TYPE ENUM ============

enum ErrorType { general, network, server, location, auth, route, search }

// ============ ERROR HANDLING EXTENSIONS ============

/// Extension for handling errors in async operations
extension ErrorHandler on Object {
  /// Get user-friendly error message
  String getUserFriendlyMessage() {
    if (this is String) {
      return toString();
    }

    // Firebase Auth errors
    if (toString().contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (toString().contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (toString().contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (toString().contains('invalid-email')) {
      return 'Invalid email address.';
    }
    if (toString().contains('network-request-failed')) {
      return AppConstants.errorNoInternet;
    }

    // Supabase errors
    if (toString().contains('JWT')) {
      return 'Authentication error. Please sign in again.';
    }
    if (toString().contains('row-level-security')) {
      return 'You don\'t have permission to perform this action.';
    }

    // General errors
    if (toString().contains('timeout')) {
      return 'Connection timeout. Please try again.';
    }
    if (toString().contains('socket')) {
      return AppConstants.errorNoInternet;
    }

    return toString();
  }

  /// Check if error is network related
  bool get isNetworkError {
    final error = toString().toLowerCase();
    return error.contains('network') ||
        error.contains('socket') ||
        error.contains('timeout') ||
        error.contains('connection') ||
        error.contains('internet');
  }

  /// Check if error is authentication related
  bool get isAuthError {
    final error = toString().toLowerCase();
    return error.contains('auth') ||
        error.contains('permission') ||
        error.contains('unauthorized') ||
        error.contains('token') ||
        error.contains('jwt');
  }

  /// Check if error is server related
  bool get isServerError {
    final error = toString().toLowerCase();
    return error.contains('500') ||
        error.contains('502') ||
        error.contains('503') ||
        error.contains('server') ||
        error.contains('internal');
  }
}

// ============ ERROR WIDGET WITH STATE MANAGEMENT ============

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final VoidCallback? onError;
  final bool showErrorWidget;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
    this.showErrorWidget = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _error = details.exception;
      _stackTrace = details.stack;
      widget.onError?.call();
      setState(() {});
      return widget.fallback ?? const SizedBox.shrink();
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.showErrorWidget) {
      // Create a local variable with non-nullable type
      final error = _error!;

      return AppErrorWidget(
        message: error.toString(),
        onRetry: _resetError,
        type: error.isNetworkError
            ? ErrorType.network
            : error.isAuthError
            ? ErrorType.auth
            : error.isServerError
            ? ErrorType.server
            : ErrorType.general,
      );
    }
    return widget.child;
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }
}

// ============ ERROR INDICATOR WIDGET ============

class ErrorIndicator extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final double size;

  const ErrorIndicator({super.key, this.message, this.onRetry, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: size,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

// ============ ASYNC ERROR HANDLER MIXIN ============

mixin AsyncErrorHandler<T extends StatefulWidget> on State<T> {
  Object? _asyncError;
  bool _isLoading = false;

  Object? get asyncError => _asyncError;
  bool get isLoading => _isLoading;
  bool get hasError => _asyncError != null;

  void setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _asyncError = null;
    });
  }

  void setError(Object error) {
    setState(() {
      _asyncError = error;
      _isLoading = false;
    });
  }

  void clearError() {
    setState(() {
      _asyncError = null;
    });
  }

  Future<T?> runAsync<T>(Future<T> Function() operation) async {
    try {
      setLoading(true);
      final result = await operation();
      setLoading(false);
      return result;
    } catch (e) {
      setError(e);
      return null;
    }
  }

  Widget buildAsyncContent({
    required Widget Function() builder,
    Widget? loadingWidget,
    Widget? errorWidget,
    bool showLoadingOnError = false,
  }) {
    if (_isLoading) {
      return loadingWidget ?? const LoadingWidget();
    }

    if (_asyncError != null) {
      final error = _asyncError!; // Safe to force unwrap since we checked null

      return errorWidget ??
          AppErrorWidget(
            message: error.getUserFriendlyMessage(),
            onRetry: () => runAsync(() => Future.value(null)),
            type: error.isNetworkError
                ? ErrorType.network
                : error.isAuthError
                ? ErrorType.auth
                : error.isServerError
                ? ErrorType.server
                : ErrorType.general,
          );
    }

    return builder();
  }
}
