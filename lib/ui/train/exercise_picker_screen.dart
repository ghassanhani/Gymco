import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/training.dart';
import '../../l10n/app_localizations.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'train_kit.dart';

/// Search the library. Picking pops with the chosen list, in tap order;
/// browsing opens each exercise instead.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key, this.browse = false});
  final bool browse;

  @override
  ConsumerState<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final _q = TextEditingController();
  String? _muscle;
  final _picked = <Exercise>[];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lib = ref.watch(exerciseLibraryProvider).value;
    final hits = lib?.search(_q.text, muscle: _muscle) ?? const <Exercise>[];
    final have = {for (final e in ref.watch(activeWorkoutProvider)?.exercises ?? const []) e.exerciseId};

    return Scaffold(
      body: VScreen(
        overlays: [
          if (_picked.isNotEmpty)
            LogBar(
              aboveTabs: false,
              children: [
                Expanded(child: Muted(_picked.map((e) => e.shortName).join(', '))),
                VBtn(label: l.addCount(_picked.length), small: true, onTap: () => context.pop(List.of(_picked))),
              ],
            ),
        ],
        child: Column(
          children: [
            BackBar(
              title: widget.browse ? l.myExercises : l.addAnExercise,
              sub: l.myExercisesSub(lib?.all.length ?? 0),
              icon: widget.browse ? 'back' : 'close',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(13)),
                child: Row(
                  children: [
                    const VIcon('search', size: 18, color: Volt.t3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _q,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 15, color: Volt.t1),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          hintText: l.searchLibrary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  for (final (i, m) in [null, ...ExerciseLibrary.muscles].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    VChip(
                      label: m == null ? l.allMuscles : muscleName(l, m),
                      on: _muscle == m,
                      onTap: () => setState(() => _muscle = m),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: lib == null
                  ? const SizedBox.shrink()
                  : hits.isEmpty
                  ? Padding(padding: const EdgeInsets.all(20), child: Muted(l.noExerciseMatch))
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, _picked.isEmpty ? 24 : 110),
                      itemCount: hits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final e = hits[i];
                        final on = _picked.contains(e);
                        final inIt = !widget.browse && have.contains(e.id);
                        return SRow(
                          label: e.name,
                          sub: muscleLine(l, e),
                          on: on,
                          lead: ExAv(e.badge),
                          trail: widget.browse
                              ? const VIcon('fwd', size: 18, color: Volt.t3)
                              : inIt
                              ? Muted(l.inLbl)
                              : Pick(on: on),
                          onTap: () {
                            if (widget.browse) {
                              context.push('/exercise/${Uri.encodeComponent(e.id)}');
                            } else if (inIt) {
                              showVToast(context, l.alreadyIn, info: true);
                            } else {
                              setState(() => on ? _picked.remove(e) : _picked.add(e));
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
