import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/mock_data.dart';
import '../../../shared/models/models.dart';

/// The exercise that follows [currentId] in the catalogue, wrapping round from
/// the last to the first, so there is always somewhere to go next.
///
/// An unknown [currentId] starts from the top of the list. Null only when
/// there is no *other* exercise to move on to.
Workout? nextWorkoutAfter(List<Workout> all, String currentId) {
  if (all.isEmpty) return null;
  final i = all.indexWhere((w) => w.id == currentId);
  if (i < 0) return all.first;
  if (all.length < 2) return null;
  return all[(i + 1) % all.length];
}

/// The just-finished exercise and the one that comes after it, for the
/// transition screen.
typedef ExerciseTransition = ({Workout? current, Workout? next});

final exerciseTransitionProvider = FutureProvider.autoDispose
    .family<ExerciseTransition, String>((ref, currentId) async {
      final all = await MockData.loadWorkouts();
      final current = all.where((w) => w.id == currentId).firstOrNull;
      return (current: current, next: nextWorkoutAfter(all, currentId));
    });
