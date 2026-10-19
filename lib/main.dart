import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/cloud.dart';
import 'data/crash_reports.dart';
import 'data/local_db.dart';
import 'state/cloud_providers.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await startCrashReports();
  try {
    // One digit style everywhere: Western digits in Arabic too, as in the design.
    DateFormat.useNativeDigitsByDefaultFor('ar', false);
    final db = await LocalDb.open().timeout(const Duration(seconds: 15));
    final prefs = await SharedPreferences.getInstance();
    runApp(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          prefsProvider.overrideWithValue(prefs),
          cloudProvider.overrideWithValue(await _connect()),
          appVersionProvider.overrideWithValue(await _version()),
        ],
        child: const GymcoApp(),
      ),
    );
  } catch (e, s) {
    // Never hang on the splash: show what went wrong instead.
    reportError(e, s);
    runApp(_StartupFailed(error: e, stack: s));
  }
}

Future<String?> _version() async {
  try {
    final p = await PackageInfo.fromPlatform();
    return '${p.version} (${p.buildNumber})';
  } catch (_) {
    return null;
  }
}

/// The account side is optional: if it cannot start, the app runs phone-only.
Future<Cloud> _connect() async {
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) return const NoCloud();
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    ).timeout(const Duration(seconds: 8));
    return SupabaseCloud(Supabase.instance.client);
  } catch (e) {
    debugPrint('Gymco: cloud unavailable, running phone-only: $e');
    return const NoCloud();
  }
}

class _StartupFailed extends StatelessWidget {
  const _StartupFailed({required this.error, required this.stack});
  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF0A0B09),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            'Gymco could not start.\n\n$error\n\n$stack',
            style: const TextStyle(color: Color(0xFFF5F7F0), fontSize: 13, height: 1.4),
          ),
        ),
      ),
    ),
  );
}
