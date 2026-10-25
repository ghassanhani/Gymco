import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import 'iron_avatar.dart';

/// The pieces of talking to Iron, modelled on a chat with an assistant:
/// a stage where Iron greets and asks ([IronStage]), ideas to start from
/// ([IronSuggestions]), the message box ([IronComposer]), what the user
/// sent ([UserBubble]) and Iron's reply ([IronSays]). [AskIron] is the
/// compact form for inputs inside another screen, such as writing a meal.

/// Iron large, on a soft glow, with a greeting and its question.
class IronStage extends StatelessWidget {
  const IronStage({super.key, required this.title, required this.question});
  final String title;
  final String question;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const _Halo(size: 170),
                IronAvatar(mood: IronMood.idle, size: 92),
              ],
            ),
          ),
          const SizedBox(height: 6),
          AiText(
            title,
            colors: ironGradient,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.4),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.5, height: 1.45, color: Volt.t2),
            ),
          ),
        ],
      ),
    );
  }
}

/// A red glow that breathes slowly behind Iron.
class _Halo extends StatefulWidget {
  const _Halo({required this.size});
  final double size;

  @override
  State<_Halo> createState() => _HaloState();
}

class _HaloState extends State<_Halo> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void initState() {
    super.initState();
    if (!IronAvatar.still) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: widget.size * (0.9 + 0.1 * t),
          height: widget.size * (0.9 + 0.1 * t),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                ironGradient[1].withValues(alpha: (Volt.isLight ? 0.2 : 0.3) + 0.08 * t),
                ironGradient[2].withValues(alpha: Volt.isLight ? 0.06 : 0.1),
                ironGradient[2].withValues(alpha: 0),
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        );
      },
    );
  }
}

/// One idea to start from: an icon and a line, tapped to fill the message.
typedef IronIdea = ({String icon, String text});

/// Ideas as cards in a row that scrolls sideways.
class IronSuggestions extends StatelessWidget {
  const IronSuggestions({super.key, required this.ideas, required this.onPick});
  final List<IronIdea> ideas;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final red = ironGradient[1];
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: ideas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final idea = ideas[i];
          return Semantics(
            button: true,
            label: idea.text,
            excludeSemantics: true,
            child: Pressable(
              radius: 20,
              onTap: () => onPick(idea.text),
              child: Container(
                width: 156,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Volt.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Volt.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: red.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: VIcon(idea.icon, size: 15, color: red),
                    ),
                    const Spacer(),
                    Text(
                      idea.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w600, color: Volt.t1),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The message box: a rounded field that lifts off the page, with a round
/// send button inside. The edge glows Iron's red while typing.
class IronComposer extends StatefulWidget {
  const IronComposer({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.onSend,
    this.sendLabel,
    this.sendEmpty = false,
    this.busy = false,
    this.minLines = 1,
    this.maxLines = 6,
    this.maxLength,
  });

  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;

  /// Null for a field read as it is typed, with nothing to send.
  final VoidCallback? onSend;

  /// What sending does, for the button's tooltip and screen readers.
  final String? sendLabel;

  /// Whether an empty message may be sent: Iron can work from the numbers.
  final bool sendEmpty;
  final bool busy;
  final int minLines;
  final int? maxLines;
  final int? maxLength;

  @override
  State<IronComposer> createState() => _IronComposerState();
}

class _IronComposerState extends State<IronComposer> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_redraw);
    widget.controller.addListener(_redraw);
  }

  @override
  void didUpdateWidget(IronComposer old) {
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final focused = _focus.hasFocus;
    final hasText = widget.controller.text.trim().isNotEmpty;
    final canSend = widget.onSend != null && !widget.busy && (widget.sendEmpty || hasText);
    final red = ironGradient[1];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: focused ? LinearGradient(colors: ironGradient) : LinearGradient(colors: [Volt.line2, Volt.line2]),
        boxShadow: [
          BoxShadow(
            color: focused
                ? red.withValues(alpha: Volt.isLight ? 0.18 : 0.28)
                : Colors.black.withValues(alpha: Volt.isLight ? 0.035 : 0.25),
            blurRadius: focused ? 28 : 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Volt.isLight ? Colors.white : Volt.card,
          borderRadius: BorderRadius.circular(26.5),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                onChanged: widget.onChanged,
                minLines: widget.minLines,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: red,
                style: TextStyle(fontSize: 15.5, height: 1.45, color: Volt.t1),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: widget.hint,
                  hintMaxLines: 4,
                  hintStyle: TextStyle(fontSize: 15.5, height: 1.45, color: Volt.t4),
                  filled: false,
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
                ),
              ),
            ),
            if (widget.onSend != null)
              _Send(label: widget.sendLabel ?? l.askIronSend, busy: widget.busy, onTap: canSend ? widget.onSend : null),
          ],
        ),
      ),
    );
  }
}

/// The round send button: Iron's gradient with an arrow when it can send,
/// quiet grey when there is nothing to send yet.
class _Send extends StatelessWidget {
  const _Send({required this.label, required this.busy, this.onTap});
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final live = onTap != null || busy;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: live ? LinearGradient(colors: ironGradient) : null,
              color: live ? null : Volt.field,
            ),
            child: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : VIcon('up', size: 18, color: live ? Colors.white : Volt.t4),
          ),
        ),
      ),
    );
  }
}

/// What the user asked, on the right, in Iron's colours.
class UserBubble extends StatelessWidget {
  const UserBubble(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: ironGradient),
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(22),
              topEnd: Radius.circular(22),
              bottomStart: Radius.circular(22),
              bottomEnd: Radius.circular(6),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Iron's reply: its face and name, then [child]; while [typing], three
/// dots instead. [mood] cheers when a plan arrives, with its sound.
class IronSays extends StatelessWidget {
  const IronSays({super.key, this.child, this.typing = false, this.mood = IronMood.happy});
  final Widget? child;
  final bool typing;
  final IronMood mood;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IronAvatar(mood: typing ? IronMood.thinking : mood, size: 38, announce: !typing && mood == IronMood.cheer),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 6),
                child: AiText(
                  l.ironName,
                  colors: ironGradient,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              if (typing) const _Dots() else ?child,
            ],
          ),
        ),
      ],
    );
  }
}

/// Three dots rising in turn: Iron is typing.
class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (!IronAvatar.still) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Volt.card,
        border: Border.all(color: Volt.line),
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(6),
          topEnd: Radius.circular(20),
          bottomStart: Radius.circular(20),
          bottomEnd: Radius.circular(20),
        ),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Transform.translate(
                offset: Offset(0, -3 * math.max(0, math.sin((_c.value - i * 0.18) * 2 * math.pi))),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: ironGradient[i], shape: BoxShape.circle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A reply from Iron in its own bubble: for a short line of text.
class IronBubble extends StatelessWidget {
  const IronBubble(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Volt.card,
        border: Border.all(color: Volt.line),
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(6),
          topEnd: Radius.circular(20),
          bottomStart: Radius.circular(20),
          bottomEnd: Radius.circular(20),
        ),
      ),
      child: Text(text, style: TextStyle(fontSize: 14.5, height: 1.45, color: Volt.t1)),
    );
  }
}

/// The compact form, inside another screen: Iron's face, name and question
/// on one line, the message box under it.
class AskIron extends StatelessWidget {
  const AskIron({
    super.key,
    required this.question,
    required this.controller,
    this.hint,
    this.busyQuestion,
    this.onChanged,
    this.onSend,
    this.sendLabel,
    this.busy = false,
    this.minLines = 1,
    this.maxLines = 6,
    this.maxLength,
  });

  final String question;
  final TextEditingController controller;
  final String? hint;
  final String? busyQuestion;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSend;
  final String? sendLabel;
  final bool busy;
  final int minLines;
  final int? maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: controller,
          builder: (_, _) => Row(
            children: [
              IronAvatar(
                mood: busy
                    ? IronMood.thinking
                    : controller.text.trim().isNotEmpty
                    ? IronMood.happy
                    : IronMood.idle,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        busy && busyQuestion != null ? busyQuestion! : question,
                        key: ValueKey(busy),
                        style: TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w600, color: Volt.t1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IronComposer(
          controller: controller,
          hint: hint,
          onChanged: onChanged,
          onSend: onSend,
          sendLabel: sendLabel,
          busy: busy,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
        ),
      ],
    );
  }
}
