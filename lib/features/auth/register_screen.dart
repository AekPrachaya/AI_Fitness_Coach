import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import 'auth_notifier.dart';
import 'password_strength.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RegisterScreen — Task 2.8
// Name, Email, Password (with strength indicator), Confirm Password,
// Terms checkbox, social login buttons (UI only), mock register via Hive.
// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _termsAccepted = false;
  PasswordStrength _strength = PasswordStrength.empty;

  late final TapGestureRecognizer _termsTapRecognizer;
  late final TapGestureRecognizer _privacyTapRecognizer;

  @override
  void initState() {
    super.initState();
    _passController.addListener(() {
      setState(() {
        _strength = PasswordStrengthCalculator.calculate(_passController.text);
      });
    });
    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () => _showTermsDialog('Terms of Service');
    _privacyTapRecognizer = TapGestureRecognizer()
      ..onTap = () => _showTermsDialog('Privacy Policy');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    super.dispose();
  }

  bool _canSubmit(AuthState authState) =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.contains('@') &&
      _passController.text.length >= 8 &&
      _passController.text == _confirmController.text &&
      _termsAccepted &&
      !authState.isLoading;

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    await ref.read(authNotifierProvider.notifier).mockRegister(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passController.text,
        );
    final authState = ref.read(authNotifierProvider);
    if (authState.isLoggedIn && mounted) {
      context.go(RouteNames.home);
    }
  }

  void _showTermsDialog(String title) {
    final textTheme = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text(title, style: textTheme.titleLarge),
        content: Text(
          '$title will be available when the backend is connected.\n\n'
          'By creating an account, you acknowledge that your data is '
          'stored locally on this device during the preview phase.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it', style: TextStyle(color: AppColors.accent)),
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

  Widget _buildConfirmSuffix() {
    if (_confirmController.text.isEmpty) {
      return GestureDetector(
        onTap: () => setState(() => _showConfirm = !_showConfirm),
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Icon(
            _showConfirm
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _showConfirm ? AppColors.accent : AppColors.textSecondary,
            size: 22,
          ),
        ),
      );
    }
    final matches = _passController.text == _confirmController.text;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Icon(
        matches ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: matches ? AppColors.accent : AppColors.error,
        size: 20,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final textTheme = Theme.of(context).textTheme;
    final canSubmit = _canSubmit(authState);

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
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surfaceElevated.withValues(alpha: 0.5),
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
                  // A. Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.login);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

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
                    'Create your\naccount',
                    style: textTheme.headlineLarge?.copyWith(height: 1.15),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(
                        begin: 0.08,
                        end: 0.0,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: AppSpacing.sm),

                  // D. Subtitle
                  Text(
                    'Start your AI-powered fitness journey.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(
                        begin: 0.08,
                        end: 0.0,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),

                  // E. Spacing
                  const SizedBox(height: AppSpacing.xxl),

                  // F. Name field
                  AppTextField(
                    label: 'Full name',
                    hint: 'Your name',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: AppColors.textDisabled,
                    ),
                    onChanged: (_) {
                      setState(() {});
                      ref.read(authNotifierProvider.notifier).clearError();
                    },
                  )
                      .animate(delay: 160.ms)
                      .fadeIn(duration: 260.ms)
                      .slideY(begin: 0.05, end: 0.0, duration: 260.ms),

                  const SizedBox(height: AppSpacing.md),

                  // G. Email field
                  AppTextField(
                    label: 'Email address',
                    hint: 'your@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      size: 20,
                      color: AppColors.textDisabled,
                    ),
                    onChanged: (_) {
                      setState(() {});
                      ref.read(authNotifierProvider.notifier).clearError();
                    },
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: 0.05, end: 0.0, duration: 250.ms),

                  const SizedBox(height: AppSpacing.md),

                  // H. Password field
                  AppTextField(
                    label: 'Password',
                    hint: 'At least 8 characters',
                    controller: _passController,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: AppColors.textDisabled,
                    ),
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _showPassword = !_showPassword),
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
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
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: 0.05, end: 0.0, duration: 240.ms),

                  const SizedBox(height: AppSpacing.sm),

                  // Password strength bar
                  if (_strength != PasswordStrength.empty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppProgressBar(
                          value: PasswordStrengthCalculator.value(_strength),
                          height: 4,
                          fillColor:
                              PasswordStrengthCalculator.color(_strength),
                          animated: true,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Text(
                              PasswordStrengthCalculator.label(_strength),
                              style: textTheme.labelMedium?.copyWith(
                                color: PasswordStrengthCalculator.color(
                                    _strength),
                              ),
                            ),
                            const Spacer(),
                            if (_strength == PasswordStrength.weak ||
                                _strength == PasswordStrength.fair)
                              Text(
                                'Add uppercase, numbers & symbols',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.textDisabled,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    )
                  else
                    const SizedBox(height: AppSpacing.md),

                  // I. Confirm password field
                  AppTextField(
                    label: 'Confirm password',
                    hint: 'Re-enter your password',
                    controller: _confirmController,
                    obscureText: !_showConfirm,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: AppColors.textDisabled,
                    ),
                    suffixIcon: _buildConfirmSuffix(),
                    onChanged: (_) => setState(() {}),
                  )
                      .animate(delay: 280.ms)
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: 0.05, end: 0.0, duration: 240.ms),

                  // J. Spacing
                  const SizedBox(height: AppSpacing.lg),

                  // K. Terms & Privacy checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) =>
                              setState(() => _termsAccepted = v ?? false),
                          activeColor: AppColors.accent,
                          checkColor: AppColors.background,
                          side: const BorderSide(
                            color: AppColors.borderMedium,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.accent,
                                ),
                                recognizer: _termsTapRecognizer,
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.accent,
                                ),
                                recognizer: _privacyTapRecognizer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 340.ms).fadeIn(duration: 230.ms),

                  // L. Spacing
                  const SizedBox(height: AppSpacing.sm),

                  // M. Error message
                  if (authState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        authState.errorMessage!,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // N. Register button
                  AppPrimaryButton(
                    label: authState.isLoading ? '' : 'Create Account',
                    isLoading: authState.isLoading,
                    onTap: canSubmit ? _handleRegister : null,
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 230.ms)
                      .slideY(begin: 0.05, end: 0.0, duration: 230.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // O. Divider row
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
                  ).animate(delay: 480.ms).fadeIn(duration: 220.ms),

                  const SizedBox(height: AppSpacing.lg),

                  // P. Social login buttons (UI only)
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
                  ).animate(delay: 480.ms).fadeIn(duration: 220.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // Q. "Already have an account?" link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(RouteNames.login),
                        child: Text(
                          'Sign in',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 480.ms).fadeIn(duration: 220.ms),

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
