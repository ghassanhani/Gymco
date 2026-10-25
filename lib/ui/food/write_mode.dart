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
    SmoothInputBorder edge(Color c) => SmoothInputBorder(
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
      style: TextStyle(fontSize: 15, height: 1.55, color: Volt.t1),
      decoration: InputDecoration(
        hintText: hint,
        hintMaxLines: 4,
        hintStyle: TextStyle(fontSize: 15, height: 1.55, color: Volt.t4),
        filled: true,
        fillColor: Volt.field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: edge(Colors.transparent),
        enabledBorder: edge(Colors.transparent),
        focusedBorder: edge(Volt.lime),
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
          IconBtn('list', label: '', onTap: null, iconSize: 22, color: Volt.t2),
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
    this.onAskAll,
    this.asking = false,
    required this.onEdit,
  });
  final List<WrittenItem> items;
  final Set<int> dropped;
  final ValueChanged<int> onDrop;
  final ValueChanged<WrittenItem> onSearch;

  /// Asks the model for a food the phone does not have; null when signed out.
  final ValueChanged<int>? onEstimate;

  /// Sends every food it could not match to the model in one go.
  final VoidCallback? onAskAll;
  final bool asking;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kept = [
      for (final (i, it) in items.indexed)
        if (!dropped.contains(i)) (i, it),
    ];
    final found = kept.where((e) => e.$2.food != null).toList();
    // An AI row carries its own tag; its amount is the model's, not a default.
    bool assumedRow(WrittenItem it) => it.assumed && it.food?.source != 'ai';
    final assumed = found.where((e) => assumedRow(e.$2)).length;
    final missing = kept.length - found.length;
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
        if (missing > 0 && onAskAll != null)
          VCard(
            color: Volt.brandWash,
            border: Border.all(color: Volt.brandEdge),
            child: GapCol(
              gap: 12,
              cross: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    VIcon('star', size: 20, color: Volt.brandInk),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.aiCanEstimate(missing),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
                      ),
                    ),
                  ],
                ),
                VBtn(
                  label: asking ? l.aiThinking : l.askAiN(missing),
                  icon: asking ? null : 'star',
                  expand: true,
                  onTap: asking ? null : onAskAll,
                ),
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
                  VIcon('search', size: 17, color: Volt.t3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GapCol(
                      gap: 2,
                      children: [
                        Text(
                          it.phrase.text,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                        ),
                        Muted(l.notInDbYet),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (onEstimate != null) ...[
                    AiBtn(label: l.estimateAction, compact: true, onTap: () => onEstimate!(i)),
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
                              foodName(context, it.food!.id, it.food!.name),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                            ),
                            if (it.food!.source == 'ai') const _AiTag(),
                            if (assumedRow(it)) const _AssumedTag(),
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
                    label: l.removeNamed(foodName(context, it.food!.id, it.food!.name)),
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
                Padding(
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

/// On a food the model estimated, so it reads as a guess to check.
class _AiTag extends StatelessWidget {
  const _AiTag();

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: smooth(
      BoxDecoration(
        color: Volt.brandWash,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Volt.brandEdge),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VIcon('star', size: 11, color: Volt.brandInk, strokeWidth: 2),
        const SizedBox(width: 4),
        Text(
          AppLocalizations.of(context).aiTag,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Volt.brandInk),
        ),
      ],
    ),
  );
}

class _AssumedTag extends StatelessWidget {
  const _AssumedTag();

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: smooth(
      BoxDecoration(
        color: Volt.warnWash,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Volt.warnEdge),
      ),
    ),
    child: Center(
      widthFactor: 1,
      child: Text(AppLocalizations.of(context).assumedTag, style: TextStyle(fontSize: 11, color: Volt.warn)),
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
                color: Volt.lime.withValues(alpha: listening ? 0.7 : 0.45),
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
