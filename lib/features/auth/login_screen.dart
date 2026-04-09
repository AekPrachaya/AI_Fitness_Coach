import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import 'auth_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen — Task 2.7
// Email + Password fields, show/hide toggle, Forgot password link,
// Social login buttons (UI only), mock auth via Hive.
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    await ref.read(authNotifierProvider.notifier).mockLogin(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    final authState = ref.read(authNotifierProvider);
    if (authState.isLoggedIn && mounted) {
      context.go(RouteNames.home);
    }
  }

  void _showForgotPasswordDialog() {
    final textTheme = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text('Reset Password', style: textTheme.titleLarge),
        content: Text(
          'Password reset is not available in this version.\n'
          'This feature will be enabled when the backend is connected.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Social login coming soon — use email for now.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
    );
  }

  String? _emailError(AuthState authState) {
    final msg = authState.errorMessage;
    if (msg == null) return null;
    return msg.toLowerCase().contains('email') ? msg : null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Layer 1 — subtle top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surfaceElevated.withValues(alpha: 0.6),
                      AppColors.background.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Layer 2 — main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ).copyWith(top: AppSpacing.xl),
              child: Column(
                children: [
                  // A. Back button (only when navigated from Welcome)
                  if (context.canPop())
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => context.pop(),
                      ),
                    ),
                  SizedBox(height: context.canPop() ? AppSpacing.lg : 0),

                  // B. Logo
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                        color: AppColors.surfaceElevated,
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        size: 28,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        duration: 300.ms,
                      ),

                  const SizedBox(height: AppSpacing.lg),

                  // C. Title
                  Text(
                    'Welcome back',
                    style: textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.08, end: 0.0, duration: 300.ms),

                  const SizedBox(height: AppSpacing.sm),

                  // D. Subtitle
                  Text(
                    'Sign in to continue your training.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.08, end: 0.0, duration: 300.ms),

                  // E. Spacing
                  const SizedBox(height: AppSpacing.xxl),

                  // F. Email field
                  AppTextField(
                    label: 'Email address',
                    hint: 'your@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) =>
                        ref.read(authNotifierProvider.notifier).clearError(),
                    errorText: _emailError(authState),
                  )
                      .animate(delay: 180.ms)
                      .fadeIn(duration: 280.ms)
                      .slideY(begin: 0.06, end: 0.0, duration: 280.ms),

                  const SizedBox(height: AppSpacing.md),

                  // G. Password field
                  AppTextField(
                    label: 'Password',
                    hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) =>
                        ref.read(authNotifierProvider.notifier).clearError(),
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _showPassword = !_showPassword),
                      child: Padding(
                        padding:
                            const EdgeInsets.only(right: AppSpacing.md),
                        child: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _showPassword
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 240.ms)
                      .fadeIn(duration: 260.ms)
                      .slideY(begin: 0.06, end: 0.0, duration: 260.ms),

                  // H. Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        'Forgot password?',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 240.ms)
                      .fadeIn(duration: 260.ms)
                      .slideY(begin: 0.06, end: 0.0, duration: 260.ms),

                  // I. Spacing
                  const SizedBox(height: AppSpacing.sm),

                  // J. Error message
                  if (authState.errorMessage != null &&
                      !authState.errorMessage!
                          .toLowerCase()
                          .contains('email'))
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        authState.errorMessage!,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // K. Login button
                  AppPrimaryButton(
                    label: authState.isLoading ? '' : 'Sign In',
                    isLoading: authState.isLoading,
                    onTap: authState.isLoading ? null : _handleLogin,
                  )
                      .animate(delay: 320.ms)
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: 0.05, end: 0.0, duration: 250.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // L. Divider row
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.divider, height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          'or continue with',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.divider, height: 1),
                      ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(duration: 250.ms),

                  const SizedBox(height: AppSpacing.lg),

                  // M. Social login buttons (UI only)
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: 'Google',
                          icon: Icons.g_mobiledata_rounded,
                          onTap: _showComingSoonSnackbar,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SocialButton(
                          label: 'Apple',
                          icon: Icons.apple_rounded,
                          onTap: _showComingSoonSnackbar,
                        ),
                      ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(duration: 250.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // N. Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(RouteNames.register),
                        child: Text(
                          'Sign up',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(duration: 250.ms),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SocialButton — outline-style social login button (UI only)
// ─────────────────────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.transparent,
          border: Border.all(color: AppColors.borderMedium, width: 1),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
