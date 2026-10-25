import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/ui/kit/smooth.dart';

void main() {
  test('a rounded box gets smooth corners, keeping its colour and border', () {
    final d = smooth(
      BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue, width: 2),
      ),
    );
    expect(d, isA<ShapeDecoration>());
    final s = d as ShapeDecoration;
    expect(s.color, Colors.red);
    expect(
      s.shape,
      SmoothBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  });

  test('boxes without a radius, circles and one-sided borders stay as they are', () {
    const plain = BoxDecoration(color: Colors.red);
    const circle = BoxDecoration(shape: BoxShape.circle);
    final oneSide = BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: const Border(bottom: BorderSide()),
    );
    expect(smooth(plain), same(plain));
    expect(smooth(circle), same(circle));
    expect(smooth(oneSide), same(oneSide));
  });

  test('smooth corners take a little more off than plain ones, and leave the middle alone', () {
    const rect = Rect.fromLTWH(0, 0, 200, 200);
    int inCorner(Path p) {
      var n = 0;
      for (var x = 0.25; x < 40; x += 0.5) {
        for (var y = 0.25; y < 40; y += 0.5) {
          if (p.contains(Offset(x, y))) n++;
        }
      }
      return n;
    }

    final smoothPath = const SmoothBorder(borderRadius: BorderRadius.all(Radius.circular(20))).getOuterPath(rect);
    final plain = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    expect(inCorner(smoothPath), lessThan(inCorner(plain)));
    expect(smoothPath.contains(const Offset(100, 100)), isTrue);
  });
}
