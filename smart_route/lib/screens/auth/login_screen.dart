import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_route/core/utills/validators.dart';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/glassmorphic_card.dart';
import '../../core/widgets/loading_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _error = authProvider.error ?? 'Login failed. Please try again.';
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

  Future<void> _loginWithGoogle() async {
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
              authProvider.error ?? 'Google login failed. Please try again.';
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

  Future<void> _loginAsGuest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.loginAsGuest();

      if (success) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        setState(() {
          _error =
              authProvider.error ?? 'Guest login failed. Please try again.';
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

  void _navigateToRegister() {
    context.go('/register');
  }

  void _navigateToForgotPassword() {
    context.go('/forgot-password');
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
                    // Logo/Header
                    _buildLogo(theme, isDark),

                    const SizedBox(height: AppConstants.paddingLarge),

                    // Login Card
                    GlassmorphicCard(
                      width: size.width > 500 ? 500 : size.width - 32,
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      isAnimated: true,
                      child: _buildLoginForm(theme, isDark),
                    ),

                    const SizedBox(height: AppConstants.paddingMedium),

                    // Register Link
                    _buildRegisterLink(theme, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // App Icon
        Container(
          width: 80,
          height: 80,
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
          child: const Icon(Icons.navigation, size: 40, color: Colors.white),
        ).animate().scale(
          duration: AppConstants.durationMedium,
          curve: Curves.easeOutBack,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // App Name
        Text(
          AppConstants.appName,
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

        // Tagline
        Text(
          'Live GPS Tracking & Navigation',
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

  Widget _buildLoginForm(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Welcome Text
        Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Sign in to continue your journey',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: AppConstants.durationMedium, delay: 300.ms)
            .slideX(
              begin: -0.2,
              end: 0,
              duration: AppConstants.durationMedium,
              delay: 300.ms,
            ),

        const SizedBox(height: AppConstants.paddingLarge),

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
            .fadeIn(duration: AppConstants.durationMedium, delay: 400.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppConstants.durationMedium,
              delay: 400.ms,
            ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Password Field
        TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
              validator: Validators.validatePassword,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _login(),
            )
            .animate()
            .fadeIn(duration: AppConstants.durationMedium, delay: 500.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: AppConstants.durationMedium,
              delay: 500.ms,
            ),

        const SizedBox(height: AppConstants.paddingSmall),

        // Remember Me & Forgot Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                  activeColor: theme.primaryColor,
                ),
                Text(
                  'Remember Me',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            Flexible(
              child: TextButton(
                onPressed: _isLoading ? null : _navigateToForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: AppConstants.fontSizeSmall,
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(
          duration: AppConstants.durationMedium,
          delay: 600.ms,
        ),

        const SizedBox(height: AppConstants.paddingMedium),

        // Login Button
        _buildLoginButton(theme, isDark),

        const SizedBox(height: AppConstants.paddingMedium),

        // Divider with OR
        _buildDivider(theme, isDark),

        const SizedBox(height: AppConstants.paddingMedium),

        // Social Login Buttons
        _buildSocialLoginButtons(theme, isDark),

        const SizedBox(height: AppConstants.paddingMedium),

        // Guest Login
        _buildGuestLoginButton(theme, isDark),
      ],
    );
  }

  Widget _buildLoginButton(ThemeData theme, bool isDark) {
    return SizedBox(
          width: double.infinity,
          height: 56,
          child: _isLoading
              ? const LoadingWidget(size: 30, style: LoadingStyle.spinner)
              : ElevatedButton(
                  onPressed: _login,
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
                    'Sign In',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        )
        .animate()
        .fadeIn(duration: AppConstants.durationMedium, delay: 700.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: AppConstants.durationMedium,
          delay: 700.ms,
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
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 800.ms);
  }

  Widget _buildSocialLoginButtons(ThemeData theme, bool isDark) {
    return Row(
      children: [
        // Google Button
        Expanded(
          child: _buildSocialButton(
            icon: Icons.g_mobiledata,
            label: 'Google',
            color: isDark ? Colors.grey[800]! : Colors.white,
            textColor: isDark ? Colors.white : Colors.black87,
            onPressed: _isLoading ? null : _loginWithGoogle,
          ),
        ),
        const SizedBox(width: AppConstants.paddingMedium),
        // Apple Button (for iOS)
        if (Theme.of(context).platform == TargetPlatform.iOS)
          Expanded(
            child: _buildSocialButton(
              icon: Icons.apple,
              label: 'Apple',
              color: isDark ? Colors.grey[800]! : Colors.black,
              textColor: isDark ? Colors.white : Colors.white,
              onPressed: _isLoading
                  ? null
                  : () {
                      // Apple sign in implementation
                    },
            ),
          ),
      ],
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 900.ms);
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24, color: textColor),
        label: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
      ),
    );
  }

  Widget _buildGuestLoginButton(ThemeData theme, bool isDark) {
    return TextButton(
      onPressed: _isLoading ? null : _loginAsGuest,
      child: Text(
        'Continue as Guest',
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: AppConstants.fontSizeMedium,
        ),
      ),
    ).animate().fadeIn(duration: AppConstants.durationMedium, delay: 1000.ms);
  }

  Widget _buildRegisterLink(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Don\'t have an account?',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: AppConstants.fontSizeMedium,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _navigateToRegister,
          child: Text(
            'Sign Up',
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
}

// ============ ROUTE NAVIGATION ============

extension LoginRoute on BuildContext {
  void navigateToLogin() {
    go('/login');
  }

  void navigateToLoginAndClearStack() {
    go('/login');
  }
}
