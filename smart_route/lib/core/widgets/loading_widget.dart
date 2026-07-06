import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_route/core/widgets/error_widget.dart';
import '../constants/app_constants.dart';

// ============ LOADING STYLE ENUM ============

enum LoadingStyle { circular, dots, gradient, spinner }

// ============ LOADING WIDGET ============

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final LoadingStyle style;
  final bool showMessage;
  final bool fullScreen;
  final Widget? customIndicator;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 40,
    this.color,
    this.style = LoadingStyle.circular,
    this.showMessage = true,
    this.fullScreen = false,
    this.customIndicator,
  });

  factory LoadingWidget.circular({
    String? message,
    double size = 40,
    Color? color,
    bool showMessage = true,
  }) {
    return LoadingWidget(
      message: message,
      size: size,
      color: color,
      style: LoadingStyle.circular,
      showMessage: showMessage,
    );
  }

  factory LoadingWidget.dots({
    String? message,
    double size = 40,
    Color? color,
    bool showMessage = true,
  }) {
    return LoadingWidget(
      message: message,
      size: size,
      color: color,
      style: LoadingStyle.dots,
      showMessage: showMessage,
    );
  }

  factory LoadingWidget.gradient({
    String? message,
    double size = 40,
    Color? color,
    bool showMessage = true,
  }) {
    return LoadingWidget(
      message: message,
      size: size,
      color: color,
      style: LoadingStyle.gradient,
      showMessage: showMessage,
    );
  }

  factory LoadingWidget.spinner({
    String? message,
    double size = 40,
    Color? color,
    bool showMessage = true,
  }) {
    return LoadingWidget(
      message: message,
      size: size,
      color: color,
      style: LoadingStyle.spinner,
      showMessage: showMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = color ?? theme.primaryColor;

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLoadingIndicator(loadingColor),
        if (showMessage && message != null) ...[
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            message!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }

  Widget _buildLoadingIndicator(Color color) {
    if (customIndicator != null) {
      return customIndicator!;
    }

    switch (style) {
      case LoadingStyle.circular:
        return _buildCircularIndicator(color);
      case LoadingStyle.dots:
        return _buildDotsIndicator(color);
      case LoadingStyle.gradient:
        return _buildGradientIndicator(color);
      case LoadingStyle.spinner:
        return _buildSpinnerIndicator(color);
    }
  }

  Widget _buildCircularIndicator(Color color) {
    return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: size / 10,
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationShort)
        .rotate(
          duration: const Duration(seconds: 2),
          curve: Curves.linear,
          begin: 0,
          end: 1,
        );
  }

  Widget _buildDotsIndicator(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
              width: size / 3,
              height: size / 3,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size / 6),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: const Duration(milliseconds: 600),
              delay: Duration(milliseconds: index * 150),
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(0.5, 0.5),
              duration: const Duration(milliseconds: 600),
              delay: Duration(milliseconds: 300 + (index * 150)),
              curve: Curves.easeInOut,
            );
      }),
    );
  }

  Widget _buildGradientIndicator(Color color) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.5), color],
              stops: const [0, 0.5, 1],
            ),
            borderRadius: BorderRadius.circular(size / 2),
          ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationShort)
        .rotate(
          duration: const Duration(seconds: 2),
          curve: Curves.linear,
          begin: 0,
          end: 1,
        );
  }

  Widget _buildSpinnerIndicator(Color color) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.2),
                width: size / 10,
              ),
            ),
          ),
          // Animated spinner
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 2),
            curve: Curves.linear,
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: size / 10),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(size / 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        radius: 1,
                        colors: [color, Colors.transparent],
                        stops: const [0, 0.5],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============ SKELETON LOADING WIDGET ============

class SkeletonLoadingWidget extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration animationDuration;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoadingWidget({
    super.key,
    required this.child,
    required this.isLoading,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoadingWidget> createState() => _SkeletonLoadingWidgetState();
}

class _SkeletonLoadingWidgetState extends State<SkeletonLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor =
        widget.baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor =
        widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ============ SKELETON TEXT ============

class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingWidget(
      isLoading: true,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ============ SKELETON AVATAR ============

class SkeletonAvatar extends StatelessWidget {
  final double size;
  final ShapeBorder shape;

  const SkeletonAvatar({
    super.key,
    this.size = 48,
    this.shape = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingWidget(
      isLoading: true,
      child: Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(shape: shape, color: Colors.transparent),
      ),
    );
  }
}

// ============ SKELETON CARD ============

class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool hasAvatar;
  final bool hasText;
  final int textLines;
  final bool hasButton;

  const SkeletonCard({
    super.key,
    this.width = double.infinity,
    this.height = 150,
    this.borderRadius = AppConstants.radiusMedium,
    this.hasAvatar = false,
    this.hasText = true,
    this.textLines = 3,
    this.hasButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingWidget(
      isLoading: true,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAvatar) ...[
              const SkeletonAvatar(),
              const SizedBox(height: AppConstants.paddingMedium),
            ],
            if (hasText) ...[
              ...List.generate(
                textLines,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    bottom: index < textLines - 1 ? 8 : 0,
                  ),
                  child: SkeletonText(
                    width: index == 0 ? 0.7 : (index == 1 ? 0.9 : 0.5),
                  ),
                ),
              ),
            ],
            if (hasButton) ...[
              const SizedBox(height: AppConstants.paddingMedium),
              SkeletonText(width: 0.4, height: 36, borderRadius: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ============ PAGE LOADING OVERLAY ============

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? overlayColor;
  final double opacity;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.overlayColor,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: (overlayColor ?? Colors.black).withOpacity(opacity),
            child: Center(
              child: LoadingWidget(
                message: message,
                style: LoadingStyle.spinner,
              ),
            ),
          ),
      ],
    );
  }
}

// ============ SHIMMER LOADING WIDGET ============

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.duration = const Duration(milliseconds: 1200),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor =
        widget.baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor =
        widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0, 0.5, 1],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ============ LOADING STATE ENUM ============

enum LoadingState { initial, loading, loaded, error }

// ============ LOADING STATE MIXIN ============

mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  LoadingState _loadingState = LoadingState.initial;
  Object? _error;

  LoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get isLoaded => _loadingState == LoadingState.loaded;
  bool get hasError => _loadingState == LoadingState.error;
  Object? get error => _error;

  void setLoading() {
    setState(() {
      _loadingState = LoadingState.loading;
      _error = null;
    });
  }

  void setLoaded() {
    setState(() {
      _loadingState = LoadingState.loaded;
      _error = null;
    });
  }

  void setError(Object error) {
    setState(() {
      _loadingState = LoadingState.error;
      _error = error;
    });
  }

  void resetState() {
    setState(() {
      _loadingState = LoadingState.initial;
      _error = null;
    });
  }

  Widget buildWithLoadingState({
    required Widget Function() builder,
    Widget? loadingWidget,
    Widget? errorWidget,
    Widget? initialWidget,
  }) {
    switch (_loadingState) {
      case LoadingState.initial:
        return initialWidget ?? const SizedBox.shrink();
      case LoadingState.loading:
        return loadingWidget ?? const LoadingWidget();
      case LoadingState.error:
        if (_error != null) {
          final error = _error!;
          return errorWidget ??
              AppErrorWidget(
                message: error.toString(),
                onRetry: () => setLoading(),
              );
        }
        return errorWidget ?? const SizedBox.shrink();
      case LoadingState.loaded:
        return builder();
    }
  }
}

// ============ EXTENSION FOR LOADING ============

extension LoadingExtension on Widget {
  /// Wrap widget with loading overlay
  Widget withLoadingOverlay({
    required bool isLoading,
    String? message,
    Color? overlayColor,
    double opacity = 0.6,
  }) {
    return LoadingOverlay(
      isLoading: isLoading,
      message: message,
      overlayColor: overlayColor,
      opacity: opacity,
      child: this,
    );
  }

  /// Add shimmer effect when loading
  Widget withShimmer({
    required bool isLoading,
    Duration duration = const Duration(milliseconds: 1200),
    Color? baseColor,
    Color? highlightColor,
  }) {
    return ShimmerLoading(
      isLoading: isLoading,
      duration: duration,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: this,
    );
  }
}
