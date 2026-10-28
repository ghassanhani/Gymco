import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/ui/train/muscle_map.dart';

void main() {
  test('a squat is shown from the side', () {
    expect(viewsFor(['quadriceps'], ['calves', 'glutes', 'hamstrings', 'lower back']), [BodyView.side]);
  });

  test('a bench press shows the front, and the back for its helpers', () {
    expect(viewsFor(['chest'], ['shoulders', 'triceps']), [BodyView.front, BodyView.back]);
  });

  test('a view with a single helper is left out', () {
    expect(viewsFor(['biceps'], ['forearms']), [BodyView.front]);
    expect(viewsFor(['hamstrings'], ['calves', 'glutes', 'lower back']), [BodyView.back]);
  });

  test('a lat pulldown shows the back, and the front for biceps and shoulders', () {
    expect(viewsFor(['lats'], ['biceps', 'middle back', 'shoulders']), [BodyView.front, BodyView.back]);
  });
}
