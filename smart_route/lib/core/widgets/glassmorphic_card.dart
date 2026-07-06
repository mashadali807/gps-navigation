import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final double opacity;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? shadowColor;
  final double shadowBlur;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool isAnimated;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool hasGlow;
  final double glowIntensity;
  final Alignment? glowAlignment;
  final List<BoxShadow>? customShadows;
  final Gradient? gradient;
  final bool isLoading;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = AppConstants.radiusLarge,
    this.blur = 20,
    this.opacity = 0.7,
    this.borderWidth = 1.5,
    this.borderColor,
    this.backgroundColor,
    this.shadowColor,
    this.shadowBlur = 20,
    this.padding = const EdgeInsets.all(AppConstants.paddingLarge),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.isAnimated = true,
    this.animationDuration = const Duration(milliseconds: 400),
    this.animationCurve = Curves.easeOutCubic,
    this.hasGlow = false,
    this.glowIntensity = 0.3,
    this.glowAlignment,
    this.customShadows,
    this.gradient,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Default colors based on theme
    final defaultBgColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.7);

    final defaultBorderColor = isDark
        ? Colors.white.withOpacity(0.15)
        : Colors.white.withOpacity(0.5);

    final defaultShadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.1);

    // Build glassmorphic container
    Widget card = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (backgroundColor ?? defaultBgColor),
                (backgroundColor ?? defaultBgColor).withOpacity(opacity * 0.8),
              ],
            ),
        border: Border.all(
          color: borderColor ?? defaultBorderColor,
          width: borderWidth,
        ),
        boxShadow:
            customShadows ??
            [
              BoxShadow(
                color: shadowColor ?? defaultShadowColor,
                blurRadius: shadowBlur,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : child,
    );

    // Add glow effect if enabled
    if (hasGlow) {
      card = _buildGlowEffect(card);
    }

    // Add animation if enabled
    if (isAnimated) {
      card = card
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: animationDuration,
            curve: animationCurve,
            color: Colors.white.withOpacity(glowIntensity),
          );
    }

    // Add tap handling
    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: (borderColor ?? defaultBorderColor).withOpacity(0.2),
          highlightColor: (borderColor ?? defaultBorderColor).withOpacity(0.1),
          child: card,
        ),
      );
    }

    return card;
  }

  Widget _buildGlowEffect(Widget child) {
    return Stack(
      children: [
        // Glow background
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: RadialGradient(
              center: glowAlignment ?? Alignment.topLeft,
              radius: 1.5,
              colors: [
                Colors.white.withOpacity(glowIntensity),
                Colors.transparent,
              ],
              stops: const [0, 1],
            ),
          ),
        ),
        // Main content
        child,
      ],
    );
  }
}

// ============ GLASSMORPHIC CARD VARIANTS ============

class GlassmorphicCardWithImage extends StatelessWidget {
  final String imageUrl;
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isAnimated;

  const GlassmorphicCardWithImage({
    super.key,
    required this.imageUrl,
    required this.child,
    this.borderRadius = AppConstants.radiusLarge,
    this.blur = 20,
    this.opacity = 0.6,
    this.padding = const EdgeInsets.all(AppConstants.paddingLarge),
    this.onTap,
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.black.withOpacity(opacity),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: blur,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
          ],
        ),
        child: child,
      ),
    );

    if (isAnimated) {
      card = card
          .animate()
          .fadeIn(duration: AppConstants.durationMedium)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
            duration: AppConstants.durationMedium,
          );
    }

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}

// ============ GLASSMORPHIC BUTTON ============

class GlassmorphicButton extends StatelessWidget {
  final String text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final bool isAnimated;
  final bool isLoading;

  const GlassmorphicButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.borderRadius = AppConstants.radiusLarge,
    this.blur = 20,
    this.color,
    this.textColor,
    this.fontSize = AppConstants.fontSizeLarge,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppConstants.paddingLarge,
      vertical: AppConstants.paddingMedium,
    ),
    this.isAnimated = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final buttonColor =
        color ??
        (isDark
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.7));

    final buttonTextColor =
        textColor ?? (isDark ? Colors.white : Colors.black87);

    Widget button = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [buttonColor, buttonColor.withOpacity(0.6)],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: blur,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(
                  text,
                  style: TextStyle(
                    color: buttonTextColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
              ],
            ),
    );

    if (isAnimated) {
      button = button
          .animate()
          .fadeIn(duration: AppConstants.durationMedium)
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: AppConstants.durationMedium,
          );
    }

    if (onPressed != null && !isLoading) {
      button = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: button,
        ),
      );
    }

    return button;
  }
}

// ============ GLASSMORPHIC INPUT FIELD ============

class GlassmorphicInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isLoading;
  final bool enabled;
  final bool showValidation;
  final double borderRadius;
  final double blur;

  const GlassmorphicInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.enabled = true,
    this.showValidation = true,
    this.borderRadius = AppConstants.radiusMedium,
    this.blur = 20,
  });

  @override
  State<GlassmorphicInput> createState() => _GlassmorphicInputState();
}

class _GlassmorphicInputState extends State<GlassmorphicInput> {
  late TextEditingController _controller;
  String? _errorText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.showValidation) {
      _validate();
    }
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(_controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inputColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.6);

    final borderColor = _errorText != null
        ? Colors.red
        : _isFocused
        ? Colors.blue
        : Colors.white.withOpacity(0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [inputColor, inputColor.withOpacity(0.4)],
            ),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: widget.blur,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: TextFormField(
            controller: _controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled && !widget.isLoading,
            onChanged: (value) {
              widget.onChanged?.call(value);
              if (widget.showValidation) _validate();
            },
            onFieldSubmitted: (_) => widget.onSubmitted?.call(),
            onTap: () => setState(() => _isFocused = true),
            onEditingComplete: () => setState(() => _isFocused = false),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              errorText: widget.showValidation ? _errorText : null,
              errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        if (_errorText != null && widget.showValidation) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============ GLASSMORPHIC CARD LIST TILE ============

class GlassmorphicListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isAnimated;

  const GlassmorphicListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.borderRadius = AppConstants.radiusMedium,
    this.padding = const EdgeInsets.all(AppConstants.paddingMedium),
    this.isAnimated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget tile = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.6),
            isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.white.withOpacity(0.3),
          ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) title!,
                if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (isAnimated) {
      tile = tile
          .animate()
          .fadeIn(duration: AppConstants.durationMedium)
          .slideX(begin: 0.2, end: 0, duration: AppConstants.durationMedium);
    }

    if (onTap != null) {
      tile = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: tile,
        ),
      );
    }

    return tile;
  }
}

// ============ GLASSMORPHIC APP BAR ============

class GlassmorphicAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final double blur;

  const GlassmorphicAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor ??
                  (isDark
                      ? Colors.black.withOpacity(0.8)
                      : Colors.white.withOpacity(0.8)),
              backgroundColor ??
                  (isDark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.white.withOpacity(0.4)),
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ============ EXTENSION FOR GLASSMORPHIC STYLING ============

extension GlassmorphicStyling on Widget {
  /// Wrap widget with glassmorphic effect
  Widget withGlassmorphic({
    double borderRadius = AppConstants.radiusLarge,
    double blur = 20,
    double opacity = 0.7,
    double borderWidth = 1.5,
    Color? borderColor,
    Color? backgroundColor,
    EdgeInsetsGeometry padding = const EdgeInsets.all(
      AppConstants.paddingLarge,
    ),
    List<BoxShadow>? shadows,
    bool isAnimated = true,
  }) {
    return GlassmorphicCard(
      borderRadius: borderRadius,
      blur: blur,
      opacity: opacity,
      borderWidth: borderWidth,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      padding: padding,
      customShadows: shadows,
      isAnimated: isAnimated,
      child: this,
    );
  }
}
