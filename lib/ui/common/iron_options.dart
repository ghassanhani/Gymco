import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

/// What to ask Iron for, picked rather than typed: days, time, where and what
/// matters most. Each group takes one choice, or none (then Iron goes by the
/// numbers), and the picks go to Iron as a short note in the app's language.
class IronOptions extends StatefulWidget {
  const IronOptions({
    super.key,
    required this.buildLabel,
    required this.onBuild,
    this.busy = false,
    this.fallback = '',
  });

  final String buildLabel;

  /// The note for Iron; [fallback] when nothing was picked.
  final ValueChanged<String> onBuild;
  final bool busy;
  final String fallback;

  @override
  State<IronOptions> createState() => _IronOptionsState();
}

class _IronOptionsState extends State<IronOptions> {
  int? _days, _minutes;
  String? _place, _focus;

  static const _dayChoices = [2, 3, 4, 5, 6];
  static const _minuteChoices = [30, 45, 60, 90];

  Map<String, String> _places(AppLocalizations l) => {'gym': l.optGym, 'home': l.optHome, 'none': l.optNoKit};

  Map<String, String> _focuses(AppLocalizations l) => {
    'balanced': l.optBalanced,
    'muscle': l.optMuscle,
    'fat': l.optFatLoss,
    'strength': l.optStrength,
    'legs': l.optLegs,
    'upper': l.optUpper,
  };

  String _note(AppLocalizations l) => [
    if (_days != null) '${l.optDaysTitle}: $_days.',
    if (_minutes != null) '${l.optTimeTitle}: ${l.optMinutes(_minutes!)}.',
    if (_place != null) '${l.optPlaceTitle}: ${_places(l)[_place]}.',
    if (_focus != null) '${l.optFocusTitle}: ${_focuses(l)[_focus]}.',
  ].join(' ');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget group<T>(String title, Map<T, String> choices, T? picked, ValueChanged<T?> pick) => GapCol(
      gap: 8,
      cross: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Volt.t2),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final MapEntry(:key, :value) in choices.entries)
              VChip(
                label: value,
                on: picked == key,
                height: 38,
                onTap: () {
                  HapticFeedback.selectionClick();
                  pick(picked == key ? null : key);
                },
              ),
          ],
        ),
      ],
    );

    return VCard(
      child: GapCol(
        gap: 16,
        cross: CrossAxisAlignment.stretch,
        children: [
          group(l.optDaysTitle, {for (final d in _dayChoices) d: '$d'}, _days, (v) => setState(() => _days = v)),
          group(
            l.optTimeTitle,
            {for (final m in _minuteChoices) m: l.optMinutes(m)},
            _minutes,
            (v) => setState(() => _minutes = v),
          ),
          group(l.optPlaceTitle, _places(l), _place, (v) => setState(() => _place = v)),
          group(l.optFocusTitle, _focuses(l), _focus, (v) => setState(() => _focus = v)),
          Muted(l.optHint, size: 12),
          AiBtn(
            label: widget.buildLabel,
            busy: widget.busy,
            colors: ironGradient,
            foreground: Colors.white,
            onTap: widget.busy
                ? null
                : () {
                    final note = _note(l);
                    widget.onBuild(note.isEmpty ? widget.fallback : note);
                  },
          ),
        ],
      ),
    );
  }
}
