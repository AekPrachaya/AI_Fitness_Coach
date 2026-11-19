import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/utils/mock_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await _openBox(MockData.boxUserProfile);
  await _openBox(MockData.boxSessionHistory);
  await _openBox(MockData.boxProgressData);
  await MockData.seedProgressHistory();
  await MockData.seedBodyMetrics();
  runApp(const ProviderScope(child: FitnessApp()));
}

/// Opens a box, starting it over if the file on disk cannot be read.
///
/// A box that fails to open fails before `runApp`, so the app would never
/// start again until it was reinstalled. Losing the history in that box is
/// the lesser harm: reinstalling loses it too.
Future<void> _openBox(String name) async {
  try {
    await Hive.openBox(name);
  } catch (e) {
    debugPrint('Hive: box "$name" unreadable, starting it over — $e');
    await Hive.deleteBoxFromDisk(name);
    await Hive.openBox(name);
  }
}
