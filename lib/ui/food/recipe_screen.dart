import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/meal_reader.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'write_mode.dart';

/// Build a recipe: name it, write what goes in the pot the way you would
/// say it, and split it into servings. It is saved as one food per serving.
class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key, this.recipeId});
  final int? recipeId;

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  final _name = TextEditingController();
  final _add = TextEditingController();
  final _items = <(Food, double)>[];
  List<String> _missed = const [];
  int _servings = 4;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _add.dispose();
    super.dispose();
  }

  void _load(List<Recipe> all) {
    if (_loaded) return;
    _loaded = true;
    final r = all.where((x) => x.id == widget.recipeId).firstOrNull;
    if (r == null) return;
    _name.text = r.name;
    _servings = r.servings;
    _items.addAll(r.items);
  }

  Future<void> _read() async {
    final text = _add.text.trim();
    if (text.isEmpty) return;
    final read = await readWrittenMeal(ref.read(dbProvider), text);
    if (!mounted) return;
    setState(() {
      for (final it in read) {
        if (it.food != null) _items.add((it.food!, it.grams));
      }
      _missed = [for (final it in read.where((x) => x.food == null)) it.phrase.text];
      _add.clear();
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    await ref.read(dbProvider).saveRecipe(_name.text.trim(), _servings, _items, id: widget.recipeId);
    ref.invalidate(recipesProvider);
    if (!mounted) return;
    showVToast(context, l.recipeSaved(_name.text.trim()));
    context.pop();
  }

  Future<void> _delete() async {
    await ref.read(dbProvider).deleteRecipe(widget.recipeId!);
    ref.invalidate(recipesProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(recipesProvider).value;
    if (widget.recipeId != null && all != null) _load(all);
    final draft = Recipe(id: 0, name: _name.text, servings: _servings, items: _items);
    final serving = draft.asFood();
    final g = serving.servingGrams ?? 0;
    final canSave = _name.text.trim().isNotEmpty && _items.isNotEmpty;

    return Scaffold(
      body: VScreen(
        overlays: [
          LogBar(
            aboveTabs: false,
            children: [
              Expanded(
                child: GapCol(
                  gap: 1,
                  children: [
                    Text(l.kcalPerServing(fmtInt(context, draft.kcalPerServing)), style: numStyle(15)),
                    Muted(l.servingsOf(_servings, fmtInt(context, g))),
                  ],
                ),
              ),
              VBtn(label: l.saveRecipe, small: true, onTap: canSave ? _save : null),
            ],
          ),
        ],
        child: Column(
          children: [
            BackBar(
              title: widget.recipeId == null ? l.newRecipe : l.editRecipe,
              titleSize: 20,
              icon: 'close',
              right: widget.recipeId == null
                  ? null
                  : IconBtn('trash', label: l.deleteRecipe, small: true, iconSize: 17, onTap: _delete),
            ),
            Expanded(
              child: Pad(
                bottom: 120,
                children: [
                  TextField(
                    controller: _name,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Volt.t1),
                    decoration: InputDecoration(
                      hintText: l.recipeNameHint,
                      filled: true,
                      fillColor: Volt.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  VCard(
                    tight: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(l.servingsLabel, style: const TextStyle(fontSize: 14, color: Volt.t1)),
                        ),
                        VStepper(
                          label: '$_servings',
                          onMinus: _servings > 1 ? () => setState(() => _servings--) : null,
                          onPlus: _servings < 30 ? () => setState(() => _servings++) : null,
                        ),
                      ],
                    ),
                  ),
                  Eyebrow(l.ingredientsCount(_items.length), padding: const EdgeInsetsDirectional.only(start: 4)),
                  if (_items.isNotEmpty)
                    VList(
                      children: [
                        for (final (i, (f, grams)) in _items.indexed)
                          VItem(
                            children: [
                              ItemText(
                                foodName(context, f.id, f.name),
                                sub:
                                    '${fmtInt(context, grams)} ${l.grams} · ${fmtInt(context, f.kcal * grams / 100)} ${l.kcal}',
                              ),
                              IconBtn(
                                'close',
                                label: l.removeNamed(foodName(context, f.id, f.name)),
                                size: 32,
                                iconSize: 16,
                                background: Colors.transparent,
                                color: Volt.t3,
                                onTap: () => setState(() => _items.removeAt(i)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  LogArea(controller: _add, onChanged: (_) => setState(() {}), hint: l.recipeIngredientsHint, rows: 3),
                  VBtn(
                    label: l.addIngredients,
                    kind: BtnKind.ghost,
                    icon: 'plus',
                    expand: true,
                    onTap: _add.text.trim().isEmpty ? null : _read,
                  ),
                  if (_missed.isNotEmpty)
                    VCard(
                      tight: true,
                      border: Border.all(color: Volt.warnEdge),
                      child: Muted(l.recipeMissed(_missed.join(', '))),
                    ),
                  if (_items.isNotEmpty)
                    VCard(
                      child: GapCol(
                        gap: 6,
                        children: [
                          Eyebrow(l.perServing),
                          Text(
                            l.pcfLine(
                              fmtInt(context, serving.protein * g / 100),
                              fmtInt(context, serving.carbs * g / 100),
                              fmtInt(context, serving.fat * g / 100),
                            ),
                            style: numStyle(15),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
