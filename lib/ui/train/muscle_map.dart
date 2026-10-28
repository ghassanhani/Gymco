import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import 'muscle_art.dart';

enum BodyView { front, back, side }

/// Which shapes of each view light up for a muscle, by the exercise
/// library's muscle names.
const Map<BodyView, Map<String, List<String>>> _shapes = {
  BodyView.front: {
    'chest': ['f7', 'f32', 'f28', 'f29', 'f27', 'f26'],
    'shoulders': ['f3', 'f5', 'f40', 'f10'],
    'traps': ['f58', 'f57'],
    'neck': ['f55', 'f56'],
    'biceps': ['f22', 'f23'],
    'triceps': ['f50', 'f48'],
    'forearms': ['f25', 'f24', 'f45', 'f46', 'f49', 'f47'],
    'abdominals': ['f43', 'f44', 'f36', 'f35', 'f34', 'f33', 'f31', 'f30', 'f51', 'f52', 'f39', 'f38', 'f42', 'f41'],
    'quadriceps': ['f17', 'f16', 'f19', 'f18', 'f21', 'f20'],
    'adductors': ['f21', 'f20'],
    'abductors': ['f17', 'f16'],
    'calves': ['f15', 'f14', 'f9', 'f37'],
  },
  BodyView.back: {
    'shoulders': ['delt_rear-l', 'delt_rear-r'],
    'traps': ['traps'],
    'middle back': ['upper_back-l', 'upper_back-r'],
    'lats': ['lats-l', 'lats-r'],
    'lower back': ['lower_back-l', 'lower_back-r'],
    'abdominals': ['flank-l', 'flank-r'],
    'glutes': ['glutes-l', 'glutes-r'],
    'abductors': ['glutes-l', 'glutes-r'],
    'hamstrings': ['hamstrings-l', 'hamstrings-r'],
    'calves': ['calves_out-l', 'calves_out-r', 'calves_in-l', 'calves_in-r'],
    'triceps': ['triceps-l', 'triceps-r'],
    'forearms': ['forearms-l', 'forearms-r'],
  },
  BodyView.side: {
    'shoulders': ['s23', 's17', 's22'],
    'chest': ['s32', 's37', 's4'],
    'abdominals': ['s41', 's44', 's38', 's33', 's14'],
    'biceps': ['s31'],
    'triceps': ['s13'],
    'forearms': ['s21', 's12'],
    'lats': ['s43'],
    'middle back': ['s43'],
    'traps': ['s29'],
    'neck': ['s35'],
    'glutes': ['s61'],
    'abductors': ['s61'],
    'quadriceps': ['s60'],
    'hamstrings': ['s64'],
    'calves': ['s65', 's62', 's66'],
  },
};

const _size = {BodyView.front: Size(998, 3142), BodyView.back: Size(998, 3142), BodyView.side: Size(573, 3099)};
const _art = {BodyView.front: frontBodySvg, BodyView.back: backBodySvg, BodyView.side: sideBodySvg};

Set<String> _lit(BodyView v, Iterable<String> muscles) => {for (final m in muscles) ...?_shapes[v]![m]};

/// The views that show an exercise best: the side for a lift that works
/// the front and back of the legs together (squats, lunges, deadlifts),
/// otherwise the front and the back, leaving out one with little to show.
List<BodyView> viewsFor(List<String> primary, List<String> secondary) {
  final all = {...primary, ...secondary};
  const backLeg = {'glutes', 'hamstrings'};
  final legLift =
      primary.any({'quadriceps', ...backLeg}.contains) && all.contains('quadriceps') && all.any(backLeg.contains);
  if (legLift) return const [BodyView.side];
  // A view earns its place with a main muscle, or with two helpers.
  bool shows(BodyView v) => _lit(v, primary).isNotEmpty || secondary.where((m) => _lit(v, [m]).isNotEmpty).length >= 2;
  return [
    for (final v in const [BodyView.front, BodyView.back])
      if (shows(v)) v,
  ];
}

/// The body with the muscles an exercise works coloured in: the main ones in
/// red, the helpers in light red.
class MuscleMap extends StatelessWidget {
  const MuscleMap({super.key, required this.primary, required this.secondary, this.height = 230});

  final List<String> primary, secondary;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final views = viewsFor(primary, secondary);
    if (views.isEmpty) return const SizedBox.shrink();
    final dark = !Volt.isLight;
    Widget swatch(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Muted(label, size: 12),
      ],
    );
    return VCard(
      child: GapCol(
        gap: 12,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Muted(l.musclesWorked)),
              swatch(_MuscleColors.red, l.musclesMain),
              const SizedBox(width: 12),
              swatch(_MuscleColors.helpOn(dark), l.musclesHelp),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (i, v) in views.indexed) ...[
                if (i > 0) const SizedBox(width: 28),
                SizedBox(
                  key: Key('muscles-${v.name}'),
                  height: height,
                  width: height * _size[v]!.width / _size[v]!.height,
                  child: SvgPicture.string(
                    _art[v]!,
                    excludeFromSemantics: true,
                    colorMapper: _MuscleColors(
                      main: _lit(v, primary),
                      help: _lit(v, secondary).difference(_lit(v, primary)),
                      dark: dark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MuscleColors extends ColorMapper {
  const _MuscleColors({required this.main, required this.help, required this.dark});

  final Set<String> main, help;
  final bool dark;

  static const red = Color(0xFFE5484D);
  static Color helpOn(bool dark) => dark ? const Color(0xFF8A3A3E) : const Color(0xFFF7B4B6);

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    if (attributeName == 'fill' && id != null) {
      if (main.contains(id)) return red;
      if (help.contains(id)) return helpOn(dark);
    }
    if (!dark) return color;
    return switch (color.toARGB32()) {
      0xFFF9F9F9 || 0xFFF5F5F5 || 0xFFFFFFFF => const Color(0xFF3A3E45),
      0xFFC5C5C5 || 0xFFC8C4C5 || 0xFFCBCACC || 0xFFD2D0D2 || 0xFFB9C0BF => const Color(0xFF2A2D33),
      _ => const Color(0xFF4C5058),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is _MuscleColors &&
      other.dark == dark &&
      other.main.length == main.length &&
      other.main.containsAll(main) &&
      other.help.length == help.length &&
      other.help.containsAll(help);

  @override
  int get hashCode => Object.hash(dark, Object.hashAllUnordered(main), Object.hashAllUnordered(help));
}
