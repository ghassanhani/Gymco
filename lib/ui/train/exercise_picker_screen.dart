import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/training.dart';
import '../../l10n/app_localizations.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/widgets.dart';

/// Pick one or more exercises. Pops with the chosen list, in tap order.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

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
    final t = Theme.of(context).textTheme;
    final lib = ref.watch(exerciseLibraryProvider).value;
    final hits = lib?.search(_q.text, muscle: _muscle) ?? const <Exercise>[];

    return Scaffold(
      body: VoltBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    const CloseButton(),
                    Expanded(child: Text(l.addExercise, style: t.titleLarge)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _q,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l.searchExercises,
                    prefixIcon: const Icon(Icons.search_rounded, color: Volt.t3),
                  ),
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  children: [
                    for (final m in [null, ...ExerciseLibrary.muscles])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(m == null ? l.allMuscles : muscleName(l, m)),
                          selected: _muscle == m,
                          onSelected: (_) => setState(() => _muscle = m),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: lib == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: hits.length,
                        itemExtent: 76,
                        itemBuilder: (_, i) {
                          final e = hits[i];
                          final on = _picked.contains(e);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: on ? Volt.brandWash : Volt.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Volt.rRow),
                                side: BorderSide(color: on ? Volt.brand : Colors.transparent, width: 1.5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => setState(() => on ? _picked.remove(e) : _picked.add(e)),
                                child: Row(
                                  children: [
                                    ExerciseThumb(exercise: e, size: 68),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            e.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.titleMedium?.copyWith(fontSize: 15),
                                          ),
                                          Text(e.primary.map((m) => muscleName(l, m)).join(', '), style: t.bodySmall),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l.instructions,
                                      onPressed: () => context.push('/exercise/${Uri.encodeComponent(e.id)}'),
                                      icon: const Icon(Icons.info_outline_rounded, color: Volt.t3),
                                    ),
                                    Icon(
                                      on ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                      color: on ? Volt.brand : Volt.t4,
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _picked.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: GlowButton(label: l.addCount(_picked.length), onPressed: () => context.pop(List.of(_picked))),
              ),
            ),
    );
  }
}

/// The exercise's first photo, cached on the phone after the first view.
class ExerciseThumb extends ConsumerWidget {
  const ExerciseThumb({super.key, required this.exercise, this.size = 56});
  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = Container(
      width: size,
      height: size,
      color: Volt.card2,
      alignment: Alignment.center,
      child: Text(
        exercise.badge,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Volt.t3),
      ),
    );
    if (exercise.images.isEmpty || !ref.watch(showExercisePhotosProvider)) return fallback;
    return CachedNetworkImage(
      imageUrl: exercise.imageUrl(0),
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final e = ref.watch(exerciseLibraryProvider).value?[exerciseId];
    return Scaffold(
      body: VoltBackground(
        child: SafeArea(
          child: e == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  children: [
                    Row(
                      children: [
                        const BackButton(),
                        Expanded(child: Text(e.name, style: t.titleLarge)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (e.images.isNotEmpty && ref.watch(showExercisePhotosProvider))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Volt.rCard),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: PageView(
                            children: [
                              for (var i = 0; i < e.images.length; i++)
                                CachedNetworkImage(
                                  imageUrl: e.imageUrl(i),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Center(child: Text(l.photoUnavailable, style: t.bodySmall)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    SectionHeader(l.primaryMuscles),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final m in e.primary) Chip(label: Text(muscleName(l, m)))],
                    ),
                    if (e.secondary.isNotEmpty) ...[
                      SectionHeader(l.secondaryMuscles),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final m in e.secondary) Chip(label: Text(muscleName(l, m)))],
                      ),
                    ],
                    SectionHeader(l.instructions),
                    for (var i = 0; i < e.instructions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text('${i + 1}', style: t.titleMedium?.copyWith(color: Volt.brand)),
                            ),
                            Expanded(child: Text(e.instructions[i], style: t.bodyMedium)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
