import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toggle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Building blocks for the settings-style cards on the Profile screen.
// ─────────────────────────────────────────────────────────────────────────────

/// Small caps title above a card.
class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(text, style: tt.labelLarge),
    );
  }
}

/// A card whose rows fill it edge to edge, clipped so row splashes keep the
/// card's rounded corners.
class ProfileListCard extends StatelessWidget {
  const ProfileListCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.mdAll,
        child: Column(children: children),
      ),
    );
  }
}

class ProfileRowDivider extends StatelessWidget {
  const ProfileRowDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: AppSpacing.md,
    endIndent: AppSpacing.md,
    color: AppColors.divider,
  );
}

/// Tappable surface for a row: a transparent Material so the ink shows above
/// the card's own fill.
class _RowInk extends StatelessWidget {
  const _RowInk({required this.onTap, required this.child});
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

/// Label on the left, current value + chevron on the right. Tap to edit.
class ProfileValueRow extends StatelessWidget {
  const ProfileValueRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: 'Edit $label',
      child: _RowInk(
        onTap: onTap,
        child: Row(
          children: [
            Text(label, style: tt.titleMedium),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined capsule label, e.g. the BMI category.
class ProfilePill extends StatelessWidget {
  const ProfilePill({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.circleAll,
        border: Border.all(color: color),
      ),
      child: Text(text, style: tt.labelSmall?.copyWith(color: color)),
    );
  }
}

/// Title + subtitle with an [AppToggle]. The whole row toggles.
class ProfileToggleRow extends StatelessWidget {
  const ProfileToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Semantics(
      toggled: value,
      label: title,
      child: _RowInk(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.titleMedium),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppToggle(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Icon + coloured title + chevron, for one-shot actions.
class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      child: _RowInk(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(title, style: tt.titleMedium?.copyWith(color: color)),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
