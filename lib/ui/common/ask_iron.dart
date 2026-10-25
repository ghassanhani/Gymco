import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import 'iron_avatar.dart';

/// Typing to the AI as a conversation with Iron: Iron asks in a speech
/// bubble, the field is the user's message back, the examples are replies
/// to tap, and the send button says what Iron will do. Iron looks up while
/// the user types and thinks while it works.
class AskIron extends StatefulWidget {
  const AskIron({
    super.key,
    required this.question,
    required this.controller,
    this.hint,
    this.busyQuestion,
    this.onChanged,
    this.onSend,
    this.sendLabel,
    this.sendEmpty = false,
    this.busy = false,
    this.suggestions = const [],
    this.minLines = 2,
    this.maxLines = 6,
    this.maxLength,
    this.mood,
  });

  final String question;
  final TextEditingController controller;
  final String? hint;

  /// What Iron says while it works; the question stays when null.
  final String? busyQuestion;
  final ValueChanged<String>? onChanged;

  /// Null for a field read as it is typed, with nothing to send.
  final VoidCallback? onSend;
  final String? sendLabel;

  /// Whether an empty message may be sent: Iron can work from the numbers.
  final bool sendEmpty;
  final bool busy;
  final List<String> suggestions;
  final int minLines;
  final int? maxLines;
  final int? maxLength;

  /// Iron's mood once it has answered, e.g. cheering at a finished program;
  /// it announces that with its sound.
  final IronMood? mood;

  @override
  State<AskIron> createState() => _AskIronState();
}

class _AskIronState extends State<AskIron> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_redraw);
    widget.controller.addListener(_redraw);
  }

  @override
  void didUpdateWidget(AskIron old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_redraw);
      widget.controller.addListener(_redraw);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_redraw);
    _focus.dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  void _pick(String s) {
    widget.controller.text = s;
    widget.controller.selection = TextSelection.collapsed(offset: s.length);
    widget.onChanged?.call(s);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = widget.controller.text.trim();
    final canSend = widget.onSend != null && !widget.busy && (widget.sendEmpty || text.isNotEmpty);
    final mood = widget.busy
        ? IronMood.thinking
        : widget.mood != null
        ? widget.mood!
        : text.isNotEmpty
        ? IronMood.happy
        : IronMood.idle;
    final red = ironGradient[1];

    return GapCol(
      gap: 10,
      cross: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IronAvatar(mood: mood, size: 44, announce: widget.mood != null),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: red.withValues(alpha: 0.09),
                  border: Border.all(color: red.withValues(alpha: 0.3)),
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(18),
                    topEnd: Radius.circular(18),
                    bottomEnd: Radius.circular(18),
                    bottomStart: Radius.circular(4),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    widget.busy && widget.busyQuestion != null ? widget.busyQuestion! : widget.question,
                    key: ValueKey(widget.busy),
                    style: TextStyle(fontSize: 14.5, height: 1.35, fontWeight: FontWeight.w600, color: Volt.t1),
                  ),
                ),
              ),
            ),
          ],
        ),
        // The reply: a gradient edge that lights up while typing.
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [for (final c in ironGradient) c.withValues(alpha: _focus.hasFocus ? 0.95 : 0.3)],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: Volt.field, borderRadius: BorderRadius.circular(18.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  onChanged: widget.onChanged,
                  minLines: widget.minLines,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 15, height: 1.45, color: Volt.t1),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: widget.hint,
                    hintMaxLines: 4,
                    hintStyle: TextStyle(fontSize: 15, height: 1.45, color: Volt.t4),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(14, 13, 14, widget.onSend == null ? 13 : 4),
                  ),
                ),
                if (widget.onSend != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 8, 8),
                    child: Row(
                      children: [
                        Text(
                          l.askIronTo,
                          style: TextStyle(fontSize: 11.5, color: Volt.t4, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _Send(
                              label: widget.sendLabel ?? l.askIronSend,
                              busy: widget.busy,
                              onTap: canSend ? widget.onSend : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.suggestions.isNotEmpty && text.isEmpty && !widget.busy)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              for (final s in widget.suggestions)
                Semantics(
                  button: true,
                  label: s,
                  excludeSemantics: true,
                  child: Pressable(
                    onTap: () => _pick(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Volt.card,
                        border: Border.all(color: Volt.line),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(s, style: TextStyle(fontSize: 13, color: Volt.t2)),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// The send button: Iron's red, with what it will do and an arrow.
class _Send extends StatelessWidget {
  const _Send({required this.label, required this.busy, this.onTap});
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null || busy;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: on ? 1 : 0.4,
          child: Container(
            height: 38,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 6, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: ironGradient),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: busy
                      ? const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const VIcon('up', size: 15, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
