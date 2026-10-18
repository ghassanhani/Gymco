import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/training.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

/// The equipment a home-made exercise can use, as the library names it.
const _equipment = ['barbell', 'dumbbell', 'machine', 'cable', 'body only', 'kettlebells', 'bands', null];

String _equipmentName(AppLocalizations l, String? e) => switch (e) {
  'barbell' => l.eqBarbell,
  'dumbbell' => l.eqDumbbell,
  'machine' => l.eqMachine,
  'cable' => l.eqCable,
  'body only' => l.eqBody,
  'kettlebells' => l.eqKettlebell,
  'bands' => l.eqBands,
  _ => l.eqOther,
};

/// Not in the library: name it, say what it trains and with what. It joins
/// the library on this phone and logs like any other.
Future<Exercise?> createExercise(BuildContext context, WidgetRef ref, {String name = ''}) {
  final l = AppLocalizations.of(context);
  return showVSheet<Exercise>(
    context,
    title: l.createExercise,
    body: (ctx) => [_CreateBody(initial: name, l: l)],
  );
}

class _CreateBody extends ConsumerStatefulWidget {
  const _CreateBody({required this.initial, required this.l});
  final String initial;
  final AppLocalizations l;

  @override
  ConsumerState<_CreateBody> createState() => _CreateBodyState();
}

class _CreateBodyState extends ConsumerState<_CreateBody> {
  late final _name = TextEditingController(text: widget.initial);
  String? _muscle;
  String? _equip = 'dumbbell';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final e = await ref.read(dbProvider).addCustomExercise(name: _name.text, muscle: _muscle!, equipment: _equip);
    ref.invalidate(exerciseLibraryProvider);
    if (mounted) Navigator.pop(context, e);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ok = _name.text.trim().isNotEmpty && _muscle != null && !_saving;
    Widget chips<T>(List<T> values, String Function(T) label, T current, ValueChanged<T> pick) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final v in values) VChip(label: label(v), on: current == v, onTap: () => pick(v))],
    );
    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: widget.initial.isEmpty,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.t1),
          decoration: InputDecoration(
            hintText: l.exerciseNameHint,
            filled: true,
            fillColor: Volt.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        Eyebrow(l.mainMuscle, padding: const EdgeInsetsDirectional.only(start: 4)),
        chips<String?>(ExerciseLibrary.muscles, (m) => muscleName(l, m!), _muscle, (m) => setState(() => _muscle = m)),
        Eyebrow(l.equipmentLbl, padding: const EdgeInsetsDirectional.only(start: 4)),
        chips<String?>(_equipment, (e) => _equipmentName(l, e), _equip, (e) => setState(() => _equip = e)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Muted(_muscle == null ? l.pickMuscleFirst : l.customExerciseNote),
        ),
        VBtn(label: l.createAndAdd, expand: true, onTap: ok ? _save : null),
      ],
    );
  }
}
