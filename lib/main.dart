import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local_db.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // One digit style everywhere: Western digits in Arabic too, as in the design.
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
  final db = await LocalDb.open();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [dbProvider.overrideWithValue(db), prefsProvider.overrideWithValue(prefs)],
      child: const GymcoApp(),
    ),
  );
}
