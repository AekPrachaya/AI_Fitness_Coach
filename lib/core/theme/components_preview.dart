import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import '../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ComponentsPreview
// Visual test screen for Task 1.6 widgets.
// Route: /components-preview
// ─────────────────────────────────────────────────────────────────────────────

class ComponentsPreview extends StatefulWidget {
  const ComponentsPreview({super.key});

  @override
  State<ComponentsPreview> createState() => _ComponentsPreviewState();
}

class _ComponentsPreviewState extends State<ComponentsPreview> {
  bool _toggleOn = true;
  bool _toggleOff = false;
  bool _obscure = true;
  int _seg1 = 0;
  int _seg2 = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Components Preview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AppCard variants ────────────────────────────────────────────
            _SectionHeader('AppCard variants'),
            const SizedBox(height: AppSpacing.sm),

            AppCard(
              child: Text(
                'Default card — AppColors.surface background, subtle border',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            AppCard(
              onTap: () {},
              child: Text(
                'Tappable card — tap for mint green ripple',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            AppCard(
              elevated: true,
              child: Text(
                'Elevated card — AppColors.surfaceElevated background',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            AppCard.skeleton(height: 100),

            const SizedBox(height: AppSpacing.xl),

            // ── AppTextField variants ───────────────────────────────────────
            _SectionHeader('AppTextField variants'),
            const SizedBox(height: AppSpacing.sm),

            const AppTextField(label: 'Email address'),
            const SizedBox(height: AppSpacing.md),

            const AppTextField(
              label: 'Email address',
              hint: 'your@email.com',
            ),
            const SizedBox(height: AppSpacing.md),

            const AppTextField(
              label: 'Email address',
              hint: 'your@email.com',
              errorText: 'Invalid email address',
            ),
            const SizedBox(height: AppSpacing.md),

            const AppTextField(
              label: 'Disabled field',
              hint: 'Not editable',
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              label: 'Password',
              hint: 'Enter password',
              obscureText: _obscure,
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── AppToggle variants ──────────────────────────────────────────
            _SectionHeader('AppToggle variants'),
            const SizedBox(height: AppSpacing.sm),

            AppToggle(
              value: _toggleOn,
              onChanged: (v) => setState(() => _toggleOn = v),
              label: 'Notifications',
            ),
            const SizedBox(height: AppSpacing.md),

            AppToggle(
              value: _toggleOff,
              onChanged: (v) => setState(() => _toggleOff = v),
              label: 'Dark mode',
            ),
            const SizedBox(height: AppSpacing.md),

            const AppToggle(
              value: true,
              onChanged: _noOp,
              label: 'Disabled (always on)',
              enabled: false,
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── AppSegmentedControl variants ────────────────────────────────
            _SectionHeader('AppSegmentedControl variants'),
            const SizedBox(height: AppSpacing.sm),

            AppSegmentedControl(
              options: const ['Beginner', 'Pro'],
              selectedIndex: _seg1,
              onChanged: (i) => setState(() => _seg1 = i),
            ),
            const SizedBox(height: AppSpacing.md),

            AppSegmentedControl(
              options: const ['Male', 'Female', 'Other'],
              selectedIndex: _seg2,
              onChanged: (i) => setState(() => _seg2 = i),
            ),
            const SizedBox(height: AppSpacing.md),

            AppSegmentedControl(
              options: const ['Metric', 'Imperial'],
              selectedIndex: 0,
              onChanged: _noOp,
              enabled: false,
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  static void _noOp(dynamic _) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionHeader — internal helper, not exported
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.accent,
          ),
    );
  }
}
