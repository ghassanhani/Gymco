import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/volt.dart';

/// Seven slim bars, oldest first and today last, each on its own track.
/// Today's is in full colour; the days before are softer. A day with nothing
/// read shows its empty track.
class WeekBars extends StatelessWidget {
  const WeekBars({
    super.key,
    required this.values,
    required this.color,
    required this.today,
    this.height = 34,
    this.letters = true,
    this.max,
    this.barWidth = 6,
    this.relative = false,
  });

  final List<double?> values;
  final Color color;
  final DateTime today;
  final double height;
  final bool letters;

  /// The top of the scale; the largest value when null.
  final double? max;
  final double barWidth;

  /// Scale from a little under the lowest day rather than from zero, for
  /// readings like heart rate that move a few percent, not from nothing.
  final bool relative;

  @override
  Widget build(BuildContext context) {
    final known = values.whereType<double>();
    final top = max ?? (known.isEmpty ? 1.0 : known.reduce((a, b) => a > b ? a : b));
    final floor = relative && known.isNotEmpty ? known.reduce((a, b) => a < b ? a : b) * 0.8 : 0.0;
    final day = DateFormat('EEEEE', Localizations.localeOf(context).toString());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < values.length; i++)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: barWidth,
                height: height,
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  color: Volt.tint.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(barWidth),
                ),
                child: values[i] == null || top <= floor
                    ? null
                    : TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ((values[i]! - floor) / (top - floor)).clamp(0.08, 1.0)),
                        duration: Duration(milliseconds: 500 + 60 * i),
                        curve: Curves.easeOutCubic,
                        builder: (_, f, _) => Container(
                          width: barWidth,
                          height: height * f,
                          decoration: BoxDecoration(
                            color: i == values.length - 1 ? color : color.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(barWidth),
                          ),
                        ),
                      ),
              ),
              if (letters) ...[
                const SizedBox(height: 4),
                Text(
                  day.format(today.subtract(Duration(days: values.length - 1 - i))),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: i == values.length - 1 ? FontWeight.w700 : FontWeight.w500,
                    color: i == values.length - 1 ? Volt.t1 : Volt.t3,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
