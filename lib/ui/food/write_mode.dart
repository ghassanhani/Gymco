import 'package:flutter/material.dart';

import '../../data/meal_reader.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

/// `.binput.logarea`: the written meal, plain language.
class LogArea extends StatelessWidget {
  const LogArea({super.key, required this.controller, required this.onChanged, this.hint, this.rows = 5});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int rows;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder edge(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: rows,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.none,
      style: const TextStyle(fontSize: 15, height: 1.55, color: Volt.t1),
      decoration: InputDecoration(
        hintText: hint,
        hintMaxLines: 4,
        hintStyle: const TextStyle(fontSize: 15, height: 1.55, color: Volt.t4),
        filled: true,
        fillColor: Volt.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: edge(Colors.transparent),
        enabledBorder: edge(Colors.transparent),
        focusedBorder: edge(Volt.brand),
      ),
    );
  }
}

/// The empty state under the log area, before anything is written.
class WriteEmpty extends StatelessWidget {
  const WriteEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return VCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: GapCol(
        gap: 10,
        cross: CrossAxisAlignment.center,
        children: [
          const IconBtn('list', label: '', onTap: null, iconSize: 22, color: Volt.t2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Muted(l.writeEmpty, align: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// What the reader made of the text: one card per food, the ones it could
/// not match with a way to search, and a note when amounts were assumed.
class WrittenRows extends StatelessWidget {
  const WrittenRows({
    super.key,
    required this.items,
    required this.dropped,
    required this.onDrop,
    required this.onSearch,
    this.onEstimate,
    required this.onEdit,
  });
  final List<WrittenItem> items;
  final Set<int> dropped;
  final ValueChanged<int> onDrop;
  final ValueChanged<WrittenItem> onSearch;

  /// Asks the model for a food the phone does not have; null when signed out.
  final ValueChanged<int>? onEstimate;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kept = [
      for (final (i, it) in items.indexed)
        if (!dropped.contains(i)) (i, it),
    ];
    final found = kept.where((e) => e.$2.food != null).toList();
    final assumed = found.where((e) => e.$2.assumed).length;
    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Expanded(child: Eyebrow(l.itRead(found.length))),
              if (assumed > 0) Muted(l.nAssumed(assumed), color: Volt.warn),
            ],
          ),
        ),
        for (final (i, it) in kept)
          if (it.food == null)
            VCard(
              tight: true,
              border: Border.all(color: Volt.line2),
              child: Row(
                children: [
                  const VIcon('search', size: 17, color: Volt.t3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GapCol(
                      gap: 2,
                      children: [
                        Text(
                          it.phrase.text,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                        ),
                        Muted(l.notInDbYet),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (onEstimate != null) ...[
                    VBtn(
                      label: l.estimateAction,
                      small: true,
                      minHeight: 34,
                      fontSize: 13,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onTap: () => onEstimate!(i),
                    ),
                    const SizedBox(width: 6),
                  ],
                  VBtn(
                    label: l.searchAction,
                    kind: BtnKind.ghost,
                    small: true,
                    minHeight: 34,
                    fontSize: 13,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onTap: () => onSearch(it),
                  ),
                ],
              ),
            )
          else
            VCard(
              tight: true,
              onTap: () => onEdit(i),
              child: Row(
                children: [
                  Expanded(
                    child: GapCol(
                      gap: 3,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              it.food!.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                            ),
                            if (it.assumed) const _AssumedTag(),
                          ],
                        ),
                        Text(
                          l.writtenSub(
                            fmtInt(context, it.grams),
                            fmtInt(context, it.kcal),
                            fmtDec(context, it.protein, digits: 1),
                          ),
                          style: numStyle(13, weight: FontWeight.w400, color: Volt.t3),
                        ),
                      ],
                    ),
                  ),
                  IconBtn(
                    'close',
                    label: l.removeNamed(it.food!.name),
                    size: 32,
                    iconSize: 16,
                    background: Colors.transparent,
                    color: Volt.t3,
                    onTap: () => onDrop(i),
                  ),
                ],
              ),
            ),
        if (assumed > 0)
          VCard(
            tight: true,
            border: Border.all(color: Volt.warnEdge),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: VIcon('warn', size: 17, color: Volt.warn),
                ),
                const SizedBox(width: 10),
                Expanded(child: Muted(l.assumedNote)),
              ],
            ),
          ),
      ],
    );
  }
}

class _AssumedTag extends StatelessWidget {
  const _AssumedTag();

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: Volt.warnWash,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Volt.warnEdge),
    ),
    child: Center(
      widthFactor: 1,
      child: Text(AppLocalizations.of(context).assumedTag, style: const TextStyle(fontSize: 11, color: Volt.warn)),
    ),
  );
}

/// `.miclarge`: hold to dictate, or tap to start and tap again to stop.
class MicButton extends StatelessWidget {
  const MicButton({super.key, required this.listening, required this.onStart, required this.onStop});
  final bool listening;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: AppLocalizations.of(context).dictateMeal,
    child: GestureDetector(
      onTap: listening ? onStop : onStart,
      onLongPressStart: (_) => listening ? null : onStart(),
      onLongPressEnd: (_) => onStop(),
      child: AnimatedScale(
        scale: listening ? 1.08 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          width: 78,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: Volt.glow,
            boxShadow: [
              BoxShadow(
                color: Volt.brand.withValues(alpha: listening ? 0.7 : 0.45),
                blurRadius: listening ? 34 : 26,
                spreadRadius: listening ? 2 : -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const VIcon('mic', size: 30, color: Volt.ink),
        ),
      ),
    ),
  );
}
