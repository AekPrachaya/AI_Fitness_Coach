import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/utils/mock_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(MockData.boxUserProfile);
  await Hive.openBox(MockData.boxSessionHistory);
  await Hive.openBox(MockData.boxProgressData);
  await MockData.seedProgressHistory();
  await MockData.seedBodyMetrics();
  runApp(const ProviderScope(child: FitnessApp()));
}
