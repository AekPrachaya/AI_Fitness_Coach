import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../profile_logic.dart';
import '../profile_options.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modal bottom-sheet editors for the Profile rows. Each returns the new value,
// or null when the sheet is dismissed without saving. They never write
// anything themselves — the screen persists the result.
// ─────────────────────────────────────────────────────────────────────────────

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: builder,
  );
}

/// Shared chrome: drag handle, title, body, keyboard-aware bottom padding.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});
  final String title;
  final Widget child;

  static const double _handleWidth = 36;
  static const double _handleHeight = 4;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: AppSpacing.lg + keyboard,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: _handleWidth,
                height: _handleHeight,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: AppRadius.circleAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: tt.titleLarge),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Name ─────────────────────────────────────────────────────────────────────

Future<String?> showNameEditor(BuildContext context, String current) =>
    _showSheet<String>(context, (_) => _NameEditor(initial: current));

class _NameEditor extends StatefulWidget {
  const _NameEditor({required this.initial});
  final String initial;

  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  late final _controller = TextEditingController(text: widget.initial);
  bool _touched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final error = validateName(_controller.text);
    return _SheetFrame(
      title: 'Name',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _controller,
            hint: 'Your name',
            maxLength: maxNameLength,
            textInputAction: TextInputAction.done,
            errorText: _touched ? error : null,
            onChanged: (_) => setState(() => _touched = true),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(label: 'Save', onTap: error == null ? _save : null),
        ],
      ),
    );
  }
}

// ── Numbers (age / height / weight) ──────────────────────────────────────────

Future<double?> showNumberEditor(
  BuildContext context, {
  required String title,
  required NumberRule rule,
  required double current,
}) => _showSheet<double>(
  context,
  (_) => _NumberEditor(title: title, rule: rule, initial: current),
);

class _NumberEditor extends StatefulWidget {
  const _NumberEditor({
    required this.title,
    required this.rule,
    required this.initial,
  });

  final String title;
  final NumberRule rule;
  final double initial;

  @override
  State<_NumberEditor> createState() => _NumberEditorState();
}

class _NumberEditorState extends State<_NumberEditor> {
  late final _controller = TextEditingController(
    text: widget.initial.toStringAsFixed(widget.rule.decimals),
  );
  bool _touched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() =>
      Navigator.of(context).pop(widget.rule.parse(_controller.text));

  @override
  Widget build(BuildContext context) {
    final rule = widget.rule;
    final error = rule.validate(_controller.text);
    final decimal = rule.decimals > 0;

    return _SheetFrame(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textInputAction: TextInputAction.done,
            helperText: _touched && error != null
                ? null
                : '${rule.min.toStringAsFixed(0)}–'
                      '${rule.max.toStringAsFixed(0)} ${rule.unit}',
            errorText: _touched ? error : null,
            suffixIcon: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                rule.unit,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            onChanged: (_) => setState(() => _touched = true),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(label: 'Save', onTap: error == null ? _save : null),
        ],
      ),
    );
  }
}

// ── Single choice (gender / goal / level) ────────────────────────────────────

/// Tapping an option saves it straight away.
Future<String?> showChoiceEditor(
  BuildContext context, {
  required String title,
  required List<ProfileOption> options,
  required String current,
}) => _showSheet<String>(
  context,
  (sheetContext) => _SheetFrame(
    title: title,
    child: Column(
      children: [
        for (final o in options)
          _OptionTile(
            label: o.label,
            selected: o.id == current,
            multi: false,
            onTap: () => Navigator.of(sheetContext).pop(o.id),
          ),
      ],
    ),
  ),
);

// ── Equipment (multi choice) ─────────────────────────────────────────────────

Future<List<String>?> showEquipmentEditor(
  BuildContext context,
  List<String> current,
) => _showSheet<List<String>>(
  context,
  (_) => _EquipmentEditor(initial: current),
);

class _EquipmentEditor extends StatefulWidget {
  const _EquipmentEditor({required this.initial});
  final List<String> initial;

  @override
  State<_EquipmentEditor> createState() => _EquipmentEditorState();
}

class _EquipmentEditorState extends State<_EquipmentEditor> {
  late List<String> _selected = List<String>.from(widget.initial);

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Equipment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in equipmentOptions)
            _OptionTile(
              label: o.label,
              selected: _selected.contains(o.id),
              multi: true,
              onTap: () =>
                  setState(() => _selected = toggleEquipment(_selected, o.id)),
            ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: 'Save',
            onTap: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

// ── Option tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final IconData icon;
    if (multi) {
      icon = selected
          ? Icons.check_box_rounded
          : Icons.check_box_outline_blank_rounded;
    } else {
      icon = selected
          ? Icons.radio_button_checked_rounded
          : Icons.radio_button_unchecked_rounded;
    }

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smAll,
          splashColor: AppColors.accent.withValues(alpha: 0.08),
          highlightColor: AppColors.accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: tt.titleMedium?.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
