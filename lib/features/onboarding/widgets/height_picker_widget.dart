// TODO: Replace with a scrollable ruler picker for production.
// The horizontal ruler requires platform-specific scroll physics for snapping;
// the increment/decrement fallback is used here for reliability.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HeightPickerWidget
// Increment / decrement control for height selection.
// Stores value in cm internally; displays in cm or ft/in per [inFeet].
// Range: 100–220 cm (3'3"–7'3")
// Step: 1 cm or 1 in (~2.54 cm) depending on display unit.
// ─────────────────────────────────────────────────────────────────────────────

class HeightPickerWidget extends StatefulWidget {
  const HeightPickerWidget({
    super.key,
    required this.value,
    required this.inFeet,
    required this.onChanged,
  });

  final double? value; // cm
  final bool inFeet;
  final ValueChanged<double> onChanged;

  @override
  State<HeightPickerWidget> createState() => _HeightPickerWidgetState();
}

class _HeightPickerWidgetState extends State<HeightPickerWidget> {
  static const double _minCm = 100.0;
  static const double _maxCm = 220.0;

  late double _cm;

  @override
  void initState() {
    super.initState();
    _cm = widget.value ?? 170.0;
    // Emit the initial value so the notifier is populated even if the user
    // never touches the picker. Must run after the first frame so that the
    // parent ConsumerWidget has finished building.
    if (widget.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_cm);
      });
    }
  }

  @override
  void didUpdateWidget(HeightPickerWidget old) {
    super.didUpdateWidget(old);
    if (widget.value != null && (widget.value! - _cm).abs() > 0.01) {
      setState(() => _cm = widget.value!);
    }
  }

  // 1 inch when in ft mode; 1 cm otherwise
  double get _step => widget.inFeet ? 2.54 : 1.0;

  void _decrement() {
    final next = (_cm - _step).clamp(_minCm, _maxCm);
    if (next == _cm) return;
    setState(() => _cm = next);
    widget.onChanged(_cm);
  }

  void _increment() {
    final next = (_cm + _step).clamp(_minCm, _maxCm);
    if (next == _cm) return;
    setState(() => _cm = next);
    widget.onChanged(_cm);
  }

  String _displayValue() {
    if (!widget.inFeet) return '${_cm.round()} cm';
    final totalInches = (_cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return "$feet'$inches\"";
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: _cm > _minCm ? _decrement : null,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              _displayValue(),
              key: ValueKey(_displayValue()),
              style: tt.displaySmall?.copyWith(color: AppColors.accent),
            ),
          ),
          AppIconButton(
            icon: Icons.keyboard_arrow_up_rounded,
            onTap: _cm < _maxCm ? _increment : null,
          ),
        ],
      ),
    );
  }
}
