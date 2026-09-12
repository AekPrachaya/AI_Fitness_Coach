import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/mock_data.dart';
import '../../../shared/models/models.dart';

// ── View mode ─────────────────────────────────────────────────────────────────

enum BrowseViewMode { list, grid }

// ── Filter state providers ────────────────────────────────────────────────────

/// Selected muscle group. null = "All".
final muscleGroupFilterProvider = StateProvider<String?>((ref) => null);

/// Selected difficulty. null = "All".
final difficultyFilterProvider = StateProvider<String?>((ref) => null);

/// Live search query (updated on every keystroke).
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Current list/grid toggle.
final browseViewModeProvider =
    StateProvider<BrowseViewMode>((ref) => BrowseViewMode.list);

// ── Derived: filtered workouts ────────────────────────────────────────────────

/// Re-runs automatically whenever any filter provider changes.
final filteredWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final all = await MockData.loadWorkouts();

  final muscle = ref.watch(muscleGroupFilterProvider);
  final diff = ref.watch(difficultyFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  return all.where((w) {
    final muscleMatch = muscle == null || w.muscleGroup == muscle;
    final diffMatch = diff == null || w.difficulty == diff;
    final searchMatch = query.isEmpty ||
        w.name.toLowerCase().contains(query) ||
        w.description.toLowerCase().contains(query) ||
        w.muscleGroupTags.any((t) => t.toLowerCase().contains(query));
    return muscleMatch && diffMatch && searchMatch;
  }).toList();
});
