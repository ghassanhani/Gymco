import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/watch_apps.dart';

void main() {
  test('the card names the app the readings came from, whatever the device', () {
    expect(watchAppName('com.huami.watch.hmwatchmanager'), 'Zepp');
    expect(watchAppName('WHOOP'), 'WHOOP');
    expect(watchAppName('com.whoop.android'), 'WHOOP');
    expect(watchAppName('com.garmin.android.apps.connectmobile'), 'Garmin Connect');
    expect(watchAppName('Oura'), 'Oura');
    expect(watchAppName('com.ultrahuman.android'), 'Ultrahuman');
    expect(watchAppName('com.xiaomi.wearable'), 'Mi Fitness');
    // An app Gymco doesn't know keeps its own name.
    expect(watchAppName('Some Band'), 'Some Band');
  });
}
