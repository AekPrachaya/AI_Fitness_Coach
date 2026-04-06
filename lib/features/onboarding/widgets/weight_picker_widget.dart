import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WeightPickerWidget
// Vertical drum-roll picker using ListWheelScrollView.
// Items are always 1 kg steps (30–200 kg). In lbs mode the same kg positions
// are displayed as their pound equivalent so the scroll index never changes
// when the user toggles units — only the labels update.
// ─────────────────────────────────────────────────────────────────────────────

class WeightPickerWidget extends StatefulWidget {
  const WeightPickerWidget({
    super.key,
    required this.value,
    required this.inLbs,
    required this.onChanged,
  });

  final double? value; // kg
  final bool inLbs;
  final ValueChanged<double> onChanged;

  @override
  State<WeightPickerWidget> createState() => _WeightPickerWidgetState();
}

class _WeightPickerWidgetState extends State<WeightPickerWidget> {
  static const double _minKg = 30.0;
  static const int _itemCount = 171; // 30–200 kg inclusive (1 kg steps)
  static const double _itemExtent = 48.0;

  late FixedExtentScrollController _scrollController;

  int get _initialIndex => ((widget.value ?? 70.0) - _minKg).round().clamp(0, _itemCount - 1);

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: _initialIndex);
    // Emit the initial value so the notifier is populated even if the user
    // never scrolls the drum roll.
    if (widget.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_kgForIndex(_initialIndex));
      });
    }
  }

  @override
  void didUpdateWidget(WeightPickerWidget old) {
    super.didUpdateWidget(old);
    // Sync scroll position when value changes externally (unit toggle does not
    // change the kg index, so no scroll is needed in that case).
    if (widget.value != null &&
        old.value != widget.value &&
        !widget.inLbs == !old.inLbs) {
      final newIndex = (widget.value! - _minKg).round().clamp(0, _itemCount - 1);
      if (_scrollController.hasClients &&
          _scrollController.selectedItem != newIndex) {
        _scrollController.animateToItem(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _kgForIndex(int index) => _minKg + index;

  String _labelForIndex(BuildContext context, int index) {
    final kg = _kgForIndex(index);
    if (!widget.inLbs) return '${kg.toInt()} kg';
    final lbs = (kg * 2.20462).round();
    return '$lbs lbs';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      height: 160,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadius.mdAll,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Drum roll ─────────────────────────────────────────────────
            ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: _itemExtent,
              perspective: 0.003,
              diameterRatio: 2.0,
              overAndUnderCenterOpacity: 0.3,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) {
                widget.onChanged(_kgForIndex(index));
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  if (index < 0 || index >= _itemCount) return null;
                  final isCenter = index == _scrollController.selectedItem;
                  return Center(
                    child: Text(
                      _labelForIndex(context, index),
                      style: (isCenter ? tt.titleLarge : tt.titleSmall)
                          ?.copyWith(
                        color: isCenter
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                },
                childCount: _itemCount,
              ),
            ),

            // ── Center selection band ─────────────────────────────────────
            IgnorePointer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 1,
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: _itemExtent - 2),
                  Container(
                    height: 1,
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
