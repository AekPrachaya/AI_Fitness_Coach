import 'package:flutter/material.dart';
import 'app_colors.dart';

class TypographyPreview extends StatelessWidget {
  const TypographyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Typography Preview')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _slot(context, 'displayLarge',   tt.displayLarge,   'FORMAI 88',    isCaps: true),
            _slot(context, 'displayMedium',  tt.displayMedium,  'REPS 24',      isCaps: true),
            _slot(context, 'displaySmall',   tt.displaySmall,   'SET 03',       isCaps: true),
            _slot(context, 'headlineLarge',  tt.headlineLarge,  'Train Smarter'),
            _slot(context, 'headlineMedium', tt.headlineMedium, 'Weekly Progress'),
            _slot(context, 'headlineSmall',  tt.headlineSmall,  "Today's Workout"),
            _slot(context, 'titleLarge',     tt.titleLarge,     'Push Day A'),
            _slot(context, 'titleMedium',    tt.titleMedium,    'Barbell Squat'),
            _slot(context, 'titleSmall',     tt.titleSmall,     'Form Score'),
            _slot(context, 'bodyLarge',      tt.bodyLarge,      'Keep your chest up and core braced throughout the movement.'),
            _slot(context, 'bodyMedium',     tt.bodyMedium,     'Complete 3 sets of 12 reps with 90 sec rest.'),
            _slot(context, 'bodySmall',      tt.bodySmall,      'Tap any exercise for detailed instructions.'),
            _slot(context, 'labelLarge',     tt.labelLarge,     '94% · 87° · 2:34'),
            _slot(context, 'labelMedium',    tt.labelMedium,    '72% · 120° · 0:45'),
            _slot(context, 'labelSmall',     tt.labelSmall,     '58% · 103° · 1:12'),
          ],
        ),
      ),
    );
  }

  Widget _slot(
    BuildContext context,
    String name,
    TextStyle? style,
    String sample, {
    bool isCaps = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(isCaps ? sample.toUpperCase() : sample, style: style),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
        ],
      ),
    );
  }
}
