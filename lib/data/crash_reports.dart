import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

// Filled in by the build from GitHub secrets; empty means no crash reports.
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
const _androidKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
const _androidApp = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
const _iosKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
const _iosApp = String.fromEnvironment('FIREBASE_IOS_APP_ID');

FirebaseOptions? get _options {
  if (_projectId.isEmpty || _senderId.isEmpty) return null;
  final (key, app) = Platform.isIOS ? (_iosKey, _iosApp) : (_androidKey, _androidApp);
  if (key.isEmpty || app.isEmpty) return null;
  return FirebaseOptions(
    apiKey: key,
    appId: app,
    messagingSenderId: _senderId,
    projectId: _projectId,
    iosBundleId: Platform.isIOS ? 'app.gymco.gymco' : null,
  );
}

/// Sends crashes to Firebase Crashlytics in release builds. Never sees what
/// the user logs: only the error, the stack and the phone model.
Future<void> startCrashReports() async {
  final options = _options;
  if (kDebugMode || options == null) return;
  try {
    await Firebase.initializeApp(options: options).timeout(const Duration(seconds: 5));
    final c = FirebaseCrashlytics.instance;
    FlutterError.onError = c.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (e, s) {
      c.recordError(e, s, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Gymco: crash reports off: $e');
  }
}

/// A failure the user saw but the app survived, such as a startup error.
void reportError(Object e, StackTrace s) {
  if (Firebase.apps.isEmpty) return;
  FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
}
