import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local_db.dart';
import '../../data/training.dart';
import '../../l10n/app_localizations.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/widgets.dart';

/// New routine when [routineId] is null, else edit that one.
class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({super.key, this.routineId});
  final int? routineId;

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  final _name = TextEditingController();
  List<RoutineItem> _items = [];
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _load(List<Routine> all) {
    if (_loaded) return;
    _loaded = true;
    final r = all.where((r) => r.id == widget.routineId).firstOrNull;
    if (r != null) {
      _name.text = r.name;
      _items = [...r.items];
    }
  }

  bool get _canSave => _name.text.trim().isNotEmpty && _items.isNotEmpty;

  Future<void> _add() async {
    final picked = await context.push<List<Exercise>>('/exercises/pick');
    if (picked == null) return;
    setState(() => _items = [..._items, for (final e in picked) RoutineItem(exerciseId: e.id)]);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    try {
      await ref
          .read(routineActionsProvider)
          .save(Routine(id: widget.routineId, name: _name.text.trim(), items: _items));
      if (mounted) context.pop();
    } on DuplicateNameException catch (e) {
      setState(() => _error = l.nameTaken(e.name));
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Volt.card,
        title: Text(l.deleteRoutineTitle),
        content: Text(l.deleteRoutineBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(routineActionsProvider).delete(widget.routineId!);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final routines = ref.watch(routinesProvider).value;
    if (routines != null) _load(routines);
    final lib = ref.watch(exerciseLibraryProvider).value;

    Widget stepper(String label, int value, int min, int max, ValueChanged<int> onChanged, {int step = 1}) => Column(
      children: [
        Text(label, style: t.bodySmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '$label −',
              visualDensity: VisualDensity.compact,
              onPressed: value - step >= min ? () => onChanged(value - step) : null,
              icon: const Icon(Icons.remove_rounded, size: 18),
            ),
            Text('$value', style: t.titleMedium),
            IconButton(
              tooltip: '$label +',
              visualDensity: VisualDensity.compact,
              onPressed: value + step <= max ? () => onChanged(value + step) : null,
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: VoltBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Row(
                children: [
                  const CloseButton(),
                  Expanded(child: Text(widget.routineId == null ? l.newRoutine : l.editRoutine, style: t.titleLarge)),
                  if (widget.routineId != null)
                    IconButton(
                      tooltip: l.deleteRoutine,
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                onChanged: (_) => setState(() => _error = null),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.routineName, errorText: _error),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _items.length; i++) ...[
                VoltCard(
                  padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(lib?[_items[i].exerciseId]?.name ?? _items[i].exerciseId, style: t.titleMedium),
                          ),
                          IconButton(
                            tooltip: l.removeExercise,
                            onPressed: () => setState(() => _items = [..._items]..removeAt(i)),
                            icon: const Icon(Icons.close_rounded, color: Volt.t3),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          stepper(
                            l.setsLabel,
                            _items[i].sets,
                            1,
                            10,
                            (v) => setState(() => _items[i] = _items[i].copyWith(sets: v)),
                          ),
                          stepper(
                            l.repsLabel,
                            _items[i].repLow,
                            1,
                            _items[i].repHigh,
                            (v) => setState(() => _items[i] = _items[i].copyWith(repLow: v)),
                          ),
                          stepper(
                            '',
                            _items[i].repHigh,
                            _items[i].repLow,
                            50,
                            (v) => setState(() => _items[i] = _items[i].copyWith(repHigh: v)),
                          ),
                          stepper(
                            '${l.restLabel} (s)',
                            _items[i].restSeconds,
                            15,
                            600,
                            (v) => setState(() => _items[i] = _items[i].copyWith(restSeconds: v)),
                            step: 15,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              GhostButton(label: l.addExercise, icon: Icons.add_rounded, onPressed: _add),
              const SizedBox(height: 24),
              GlowButton(label: l.save, onPressed: _canSave ? _save : null),
            ],
          ),
        ),
      ),
    );
  }
}
