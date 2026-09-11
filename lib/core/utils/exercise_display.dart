/// Turns a workout id into a readable name — 'bicep_curls' → 'Bicep Curls'.
///
/// Only a fallback for when a route is entered without one: the canonical name
/// comes from `assets/data/workouts.json` and is carried through the route.
String displayNameFor(String exerciseId) => exerciseId
    .split('_')
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');
