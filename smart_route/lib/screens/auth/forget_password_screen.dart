import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_route/core/utills/validators.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailSent = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (success) {
        setState(() {
          _isEmailSent = true;
          _successMessage =
              'Password reset email sent successfully!\n\nPlease check your email inbox and follow the instructions to reset your password.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              authProvider.error ??
              'Failed to send reset email. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  void _resendEmail() {
    setState(() {
      _isEmailSent = false;
      _successMessage = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[50]!, Colors.white, Colors.blue[50]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    _buildHeader(theme, isDark),

                    const SizedBox(height: AppConstants.paddingLarge),

                    // Main Card
                    GlassmorphicCard(
                      width: size.width > 500 ? 500 : size.width - 32,
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      isAnimated: true,
                      child: _isEmailSent
                          ? _buildSuccessContent(theme, isDark)
                          : _buildFormContent(theme, isDark),
                    ),

                    const SizedBox(height: AppConstants.paddingMedium),

                    // Back to Login
                    _buildBackToLogin(theme, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.primaryColor.withOpacity(0.1),
          ),
          child: Icon(Icons.lock_reset, size: 40, color: theme.primaryColor),
        ).animate().scale(
          duration: AppConstants.durationMedium,
          curve: Curves.easeOutBack,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Title
        Text(
          'Forgot Password?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ).animate().fadeIn(
          duration: AppConstants.durationMedium,
          delay: 100.ms,
        ),

        const SizedBox(height: AppConstants.paddingSmall),

        // Subtitle
        Text(
          'Enter your email address and we\'ll send you\na link to reset your password',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(
          duration: AppConstants.durationMedium,
          delay: 200.ms,
        ),
      ],
    );
  }

  Widget _buildFormContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Error Message
        if (_error != null)
          Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: AppConstants.fontSizeMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: AppConstants.durationShort)
              .slideY(
                begin: -0.2,
                end: 0,
                duration: AppConstants.durationShort,
              ),

        if (_error != null) const SizedBox(height: AppConstants.paddingMedium),

        // Email Field
        TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800]! : Colors.grey[50],
              ),
              validator: Validators.validateEmail,
              enabled: !_isLoading,
            )
            .animate()
            .fadeIn(duration: AppConstants.durationMedium, delay: 300.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppConstants.durationMedium,
              delay: 300.ms,
            ),

        const SizedBox(height: AppConstants.paddingLarge),

        // Submit Button
        _buildSubmitButton(theme, isDark),

        const SizedBox(height: AppConstants.paddingMedium),

        // Info Text
        Text(
          'We\'ll send a password reset link to your email',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.grey[500] : Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(
          duration: AppConstants.durationMedium,
          delay: 500.ms,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isDark) {
    return SizedBox(
          width: double.infinity,
          height: 56,
          child: _isLoading
              ? const LoadingWidget(size: 30, style: LoadingStyle.spinner)
              : ElevatedButton(
                  onPressed: _sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMedium,
                      ),
                    ),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_outlined),
                      const SizedBox(width: AppConstants.paddingSmall),
                      Text(
                        'Send Reset Email',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 400.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: AppConstants.durationMedium,
          delay: 400.ms,
        );
  }

  Widget _buildSuccessContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(0.1),
          ),
          child: const Icon(Icons.check_circle, size: 50, color: Colors.green),
        ).animate().scale(
          duration: AppConstants.durationMedium,
          curve: Curves.easeOutBack,
        ),

        const SizedBox(height: AppConstants.paddingLarge),

        // Success Title
        Text(
          'Email Sent!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ).animate().fadeIn(duration: AppConstants.durationMedium),

        const SizedBox(height: AppConstants.paddingMedium),

        // Success Message
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
          ),
          child: Text(
            _successMessage ?? 'Password reset email sent successfully!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(
          duration: AppConstants.durationMedium,
          delay: 100.ms,
        ),

        const SizedBox(height: AppConstants.paddingLarge),

        // Action Buttons
        Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMedium,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Back to Login'),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingMedium),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    onPressed: _resendEmail,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, size: 20),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Text(
                          'Didn\'t receive email? Resend',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
            .animate()
            .fadeIn(duration: AppConstants.durationMedium, delay: 200.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppConstants.durationMedium,
              delay: 200.ms,
            ),
      ],
    );
  }

  Widget _buildBackToLogin(ThemeData theme, bool isDark) {
    return TextButton(
      onPressed: _navigateToLogin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back,
            size: 18,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Text(
            'Back to Login',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: AppConstants.fontSizeMedium,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 600.ms);
  }
}

// ============ ROUTE NAVIGATION ============

extension ForgotPasswordRoute on BuildContext {
  void navigateToForgotPassword() {
    go('/forgot-password');
  }
}
