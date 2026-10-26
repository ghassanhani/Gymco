import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// The wearables' own apps, by the name or package the health store gives
/// as a reading's source: how to open each so it syncs. iPhone opens by URL
/// scheme; Android by package (android/app/src/main/AndroidManifest.xml
/// lists them under `queries` so the phone lets Gymco see them).
const _apps = <({List<String> match, String name, String? scheme, String package})>[
  (match: ['zepp', 'amazfit', 'huami'], name: 'Zepp', scheme: 'zepp://', package: 'com.huami.watch.hmwatchmanager'),
  (match: ['whoop'], name: 'WHOOP', scheme: 'whoop://', package: 'com.whoop.android'),
  (match: ['fitbit'], name: 'Fitbit', scheme: 'fitbit://', package: 'com.fitbit.FitbitMobile'),
  (match: ['oura'], name: 'Oura', scheme: 'oura://', package: 'com.ouraring.oura'),
  (
    match: ['garmin', 'connect'],
    name: 'Garmin Connect',
    scheme: null,
    package: 'com.garmin.android.apps.connectmobile',
  ),
  (match: ['samsung', 'shealth'], name: 'Samsung Health', scheme: null, package: 'com.sec.android.app.shealth'),
  (match: ['google fit', 'apps.fitness'], name: 'Google Fit', scheme: null, package: 'com.google.android.apps.fitness'),
  (match: ['polar'], name: 'Polar Flow', scheme: null, package: 'fi.polar.polarflow'),
];

/// A friendly name for a reading's source: "Zepp" for com.huami…, else as given.
String watchAppName(String source) {
  final s = source.toLowerCase();
  return _apps.where((a) => a.match.any(s.contains)).firstOrNull?.name ?? source;
}

/// Whether Gymco knows how to open the app behind [source] on this phone.
bool canOpenWatchApp(String source) {
  final s = source.toLowerCase();
  final app = _apps.where((a) => a.match.any(s.contains)).firstOrNull;
  if (Platform.isAndroid) return app != null || source.contains('.');
  return app?.scheme != null;
}

const _channel = MethodChannel('gymco/siri');

/// Opens the wearable's app; false when the phone couldn't.
Future<bool> openWatchApp(String source) async {
  final s = source.toLowerCase();
  final app = _apps.where((a) => a.match.any(s.contains)).firstOrNull;
  try {
    if (Platform.isAndroid) {
      // Health Connect names the source by its package, so even an app not
      // listed here can be opened.
      final package = app?.package ?? source;
      return await _channel.invokeMethod<bool>('openApp', {'package': package}) ?? false;
    }
    final scheme = app?.scheme;
    if (scheme == null) return false;
    return await launchUrl(Uri.parse(scheme), mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}
