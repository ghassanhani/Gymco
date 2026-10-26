import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

typedef FaqItem = ({String q, String a});
typedef FaqSection = ({String title, List<FaqItem> items});

/// The questions and answers in each language, from assets/faq/faq.json
/// (built by tool/faq_build.py, which also writes the website's copy).
final faqProvider = FutureProvider<Map<String, List<FaqSection>>>((ref) async {
  final bytes = await rootBundle.load('assets/faq/faq.json');
  final j = jsonDecode(
    utf8.decode(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes)),
  ) as Map<String, Object?>;
  return {
    for (final MapEntry(:key, :value) in j.entries)
      key: [
        for (final s in (value! as List).cast<Map<String, Object?>>())
          (
            title: s['title']! as String,
            items: [
              for (final i in (s['items']! as List).cast<Map<String, Object?>>())
                (q: i['q']! as String, a: i['a']! as String),
            ],
          ),
      ],
  };
});

/// Questions & answers: everything people ask, by topic, with a search, and
/// a way to message us when the answer isn't there.
class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  final _q = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(faqProvider).value;

    final lang = Localizations.localeOf(context).languageCode;
    final sections = all?[lang] ?? all?['en'] ?? const <FaqSection>[];
    final words = _query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    bool hit(FaqItem i) {
      final text = '${i.q} ${i.a}'.toLowerCase();
      return words.every(text.contains);
    }

    final shown = [
      for (final s in sections)
        if (s.items.where(hit).toList() case final items when items.isNotEmpty) (title: s.title, items: items),
    ];

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: l.faqTitle, sub: l.faqSub, titleSize: 20),
            Expanded(
              child: Pad(
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: smooth(
                      BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(13), border: Volt.edge),
                    ),
                    child: Row(
                      children: [
                        VIcon('search', size: 18, color: Volt.t3),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _q,
                            onChanged: (v) => setState(() => _query = v.trim()),
                            textInputAction: TextInputAction.search,
                            style: TextStyle(fontSize: 15, color: Volt.t1),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              filled: false,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: l.faqSearch,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          IconBtn(
                            'close',
                            label: l.faqClear,
                            size: 28,
                            iconSize: 13,
                            color: Volt.t3,
                            onTap: () {
                              _q.clear();
                              setState(() => _query = '');
                            },
                          ),
                      ],
                    ),
                  ),
                  if (all != null && shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Muted(l.faqNone, align: TextAlign.center),
                    ),
                  for (final s in shown) ...[
                    Eyebrow(s.title, padding: const EdgeInsetsDirectional.only(start: 4, top: 6)),
                    VList(
                      children: [
                        for (final i in s.items) _Question(i, open: words.isNotEmpty, key: ValueKey('${i.q}$_query')),
                      ],
                    ),
                  ],
                  VCard(
                    child: Row(
                      children: [
                        VIcon('info', size: 19, color: Volt.t3),
                        const SizedBox(width: 12),
                        ItemText(l.faqStuck, sub: l.faqStuckSub),
                        const SizedBox(width: 8),
                        VBtn(label: l.faqMessageUs, small: true, onTap: () => context.push('/help')),
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

/// One question; tap it for the answer.
class _Question extends StatefulWidget {
  const _Question(this.item, {required this.open, super.key});
  final FaqItem item;

  /// Opens with the answer showing, as when it matched a search.
  final bool open;

  @override
  State<_Question> createState() => _QuestionState();
}

class _QuestionState extends State<_Question> {
  late var _open = widget.open;

  @override
  Widget build(BuildContext context) {
    final lines = widget.item.a.split('\n');
    return Semantics(
      button: true,
      expanded: _open,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _open = !_open);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.q,
                        style: TextStyle(fontSize: 15, height: 1.3, fontWeight: FontWeight.w600, color: Volt.t1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: VIcon('down', size: 16, color: Volt.t3),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: !_open
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final line in lines)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: line.startsWith('• ')
                                      ? Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Muted('•', size: 14, color: Volt.t3),
                                            const SizedBox(width: 8),
                                            Expanded(child: Muted(line.substring(2), size: 14, color: Volt.t2)),
                                          ],
                                        )
                                      : Muted(line, size: 14, color: Volt.t2),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
