import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AgePickerWidget
// Increment / decrement control for selecting age in range [min, max].
// Uses AnimatedSwitcher so the number animates on change.
// ─────────────────────────────────────────────────────────────────────────────

class AgePickerWidget extends StatefulWidget {
  const AgePickerWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 10,
    this.max = 80,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  State<AgePickerWidget> createState() => _AgePickerWidgetState();
}

class _AgePickerWidgetState extends State<AgePickerWidget> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? widget.min;
  }

  @override
  void didUpdateWidget(AgePickerWidget old) {
    super.didUpdateWidget(old);
    if (widget.value != null && widget.value != _value) {
      setState(() => _value = widget.value!);
    }
  }

  void _decrement() {
    if (_value <= widget.min) return;
    setState(() => _value--);
    widget.onChanged(_value);
  }

  void _increment() {
    if (_value >= widget.max) return;
    setState(() => _value++);
    widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIconButton(
          icon: Icons.remove,
          onTap: _value > widget.min ? _decrement : null,
        ),
        const SizedBox(width: AppSpacing.xl),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            '$_value',
            key: ValueKey(_value),
            style: tt.displaySmall?.copyWith(color: AppColors.accent),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        AppIconButton(
          icon: Icons.add,
          onTap: _value < widget.max ? _increment : null,
        ),
      ],
    );
  }
}
