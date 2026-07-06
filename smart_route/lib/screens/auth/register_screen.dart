import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_route/core/utills/validators.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_widget.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _error;

  // Password strength
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
      });
      return;
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    setState(() {
      _passwordStrength = score / 5;
      switch (score) {
        case 0:
        case 1:
          _passwordStrengthText = 'Weak';
          break;
        case 2:
          _passwordStrengthText = 'Fair';
          break;
        case 3:
          _passwordStrengthText = 'Good';
          break;
        case 4:
          _passwordStrengthText = 'Strong';
          break;
        case 5:
          _passwordStrengthText = 'Very Strong';
          break;
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      setState(() {
        _error = 'Please agree to the Terms & Conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (success) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _error =
              authProvider.error ?? 'Registration failed. Please try again.';
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

  Future<void> _registerWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.loginWithGoogle();

      if (success) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _error =
              authProvider.error ??
              'Google registration failed. Please try again.';
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

                    // Register Card
                    GlassmorphicCard(
                      width: size.width > 500 ? 500 : size.width - 32,
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      isAnimated: true,
                      child: _buildRegisterForm(theme, isDark),
                    ),

                    const SizedBox(height: AppConstants.paddingMedium),

                    // Login Link
                    _buildLoginLink(theme, isDark),
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
        // App Icon
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.navigation, size: 35, color: Colors.white),
        ).animate().scale(
          duration: AppConstants.durationMedium,
          curve: Curves.easeOutBack,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Title
        Text(
          'Create Account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(
          duration: AppConstants.durationMedium,
          delay: 100.ms,
        ),

        const SizedBox(height: AppConstants.paddingSmall),

        // Subtitle
        Text(
          'Start your navigation journey today',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ).animate().fadeIn(
          duration: AppConstants.durationMedium,
          delay: 200.ms,
        ),
      ],
    );
  }

  Widget _buildRegisterForm(ThemeData theme, bool isDark) {
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

        // Name Field
        TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.person_outline),
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
                filled: true,
                fillColor: isDark ? Colors.grey[800]! : Colors.grey[50],
              ),
              validator: Validators.validateName,
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

        const SizedBox(height: AppConstants.paddingMedium),

        // Email Field
        TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
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
                filled: true,
                fillColor: isDark ? Colors.grey[800]! : Colors.grey[50],
              ),
              validator: Validators.validateEmail,
              enabled: !_isLoading,
            )
            .animate()
            .fadeIn(duration: AppConstants.durationMedium, delay: 400.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppConstants.durationMedium,
              delay: 400.ms,
            ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Password Field
        Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: _updatePasswordStrength,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
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
                      borderSide: BorderSide(
                        color: theme.primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800]! : Colors.grey[50],
                  ),
                  validator: Validators.validatePasswordStrong,
                  enabled: !_isLoading,
                ),

                // Password Strength Indicator
                if (_passwordController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _passwordStrength,
                                  backgroundColor: isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[200],
                                  color: _getPasswordStrengthColor(),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _passwordStrengthText,
                              style: TextStyle(
                                fontSize: AppConstants.fontSizeSmall,
                                fontWeight: FontWeight.w600,
                                color: _getPasswordStrengthColor(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use 8+ chars with uppercase, lowercase, numbers & special chars',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                            fontSize: AppConstants.fontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
            .animate()
            .fadeIn(duration: AppConstants.durationMedium, delay: 500.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppConstants.durationMedium,
              delay: 500.ms,
            ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Confirm Password Field
        TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
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
                filled: true,
                fillColor: isDark ? Colors.grey[800]! : Colors.grey[50],
              ),
              validator: (value) => Validators.validateConfirmPassword(
                value,
                _passwordController.text,
              ),
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _register(),
            )
            .animate()
            .fadeIn(duration: AppConstants.durationMedium, delay: 600.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppConstants.durationMedium,
              delay: 600.ms,
            ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Terms & Conditions
        Row(
          children: [
            Checkbox(
              value: _agreeToTerms,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
              activeColor: theme.primaryColor,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _agreeToTerms = !_agreeToTerms;
                  });
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: AppConstants.fontSizeMedium,
                    ),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(
          duration: AppConstants.durationMedium,
          delay: 700.ms,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Register Button
        _buildRegisterButton(theme, isDark),

        const SizedBox(height: AppConstants.paddingMedium),

        // Divider with OR
        _buildDivider(theme, isDark),

        const SizedBox(height: AppConstants.paddingMedium),

        // Google Sign Up Button
        _buildGoogleButton(theme, isDark),
      ],
    );
  }

  Widget _buildRegisterButton(ThemeData theme, bool isDark) {
    return SizedBox(
          width: double.infinity,
          height: 56,
          child: _isLoading
              ? const LoadingWidget(size: 30, style: LoadingStyle.spinner)
              : ElevatedButton(
                  onPressed: _register,
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
                  child: Text(
                    'Create Account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 800.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: AppConstants.durationMedium,
          delay: 800.ms,
        );
  }

  Widget _buildDivider(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
          ),
          child: Text(
            'OR',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 900.ms);
  }

  Widget _buildGoogleButton(ThemeData theme, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _registerWithGoogle,
        icon: const Icon(Icons.g_mobiledata, size: 24),
        label: Text(
          'Sign up with Google',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppConstants.fontSizeMedium,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          side: BorderSide(
            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 1000.ms);
  }

  Widget _buildLoginLink(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: AppConstants.fontSizeMedium,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _navigateToLogin,
          child: Text(
            'Sign In',
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: AppConstants.fontSizeMedium,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 1100.ms);
  }

  Color _getPasswordStrengthColor() {
    if (_passwordStrength < 0.4) return Colors.red;
    if (_passwordStrength < 0.6) return Colors.orange;
    if (_passwordStrength < 0.8) return Colors.blue;
    return Colors.green;
  }
}

// ============ ROUTE NAVIGATION ============

extension RegisterRoute on BuildContext {
  void navigateToRegister() {
    go('/register');
  }

  void navigateToRegisterAndClearStack() {
    go('/register');
  }
}
