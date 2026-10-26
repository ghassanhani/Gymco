import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/cloud.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import 'account_screen.dart' show cloudMessage;

/// Help & support: a message to the team, sent through the public
/// support-ticket function. The deletion switch turns it into a request to
/// delete the account and its data.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  late final TextEditingController _email;
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _deletion = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final signedIn = ref.read(accountProvider).value ?? ref.read(cloudProvider).email;
    _email = TextEditingController(text: signedIn ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  bool get _ready =>
      !_busy && _email.text.contains('@') && _subject.text.trim().isNotEmpty && _message.text.trim().isNotEmpty;

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final meta = ref.read(deviceMetaProvider);
    try {
      await ref
          .read(cloudProvider)
          .sendSupportTicket(
            email: _email.text.trim(),
            subject: _subject.text.trim(),
            body: _message.text.trim(),
            locale: meta.locale,
            appVersion: meta.appVersion,
            platform: meta.platform,
            kind: _deletion ? 'deletion' : 'general',
          );
    } on CloudException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.failure == CloudFailure.dailyCap ? l.helpTooMany : cloudMessage(l, e.failure);
      });
      return;
    }
    if (!mounted) return;
    showVToast(context, l.helpSent);
    context.canPop() ? context.pop() : context.go('/me');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = TextStyle(fontSize: 16, color: Volt.t1);
    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: l.helpSupport, titleSize: 20),
            Expanded(
              child: Pad(
                children: [
                  VList(
                    children: [
                      VItem(
                        onTap: () => context.push('/faq'),
                        children: [
                          VIcon('list', size: 19, color: Volt.t3),
                          ItemText(l.faqTitle, sub: l.faqSub),
                          VIcon('fwd', size: 14, color: Volt.t4),
                        ],
                      ),
                    ],
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.helpIntro)),
                  VCard(
                    child: GapCol(
                      gap: 12,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const Key('help-email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          style: style,
                          decoration: InputDecoration(hintText: l.emailHint),
                        ),
                        TextField(
                          key: const Key('help-subject'),
                          controller: _subject,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLength: 80,
                          onChanged: (_) => setState(() {}),
                          style: style,
                          decoration: InputDecoration(hintText: l.helpSubjectHint, counterText: ''),
                        ),
                        TextField(
                          key: const Key('help-message'),
                          controller: _message,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          minLines: 4,
                          maxLines: 10,
                          maxLength: 2000,
                          onChanged: (_) => setState(() {}),
                          style: style,
                          decoration: InputDecoration(hintText: l.helpMessageHint, counterText: ''),
                        ),
                        SRow(
                          label: l.helpDeleteSwitch,
                          on: _deletion,
                          onTap: () => setState(() => _deletion = !_deletion),
                          trail: VToggle(on: _deletion),
                        ),
                        if (_deletion)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Muted(l.helpDeleteNote, color: Volt.t2),
                          ),
                        VBtn(label: l.helpSend, expand: true, onTap: _ready ? _send : null),
                        if (_error != null)
                          Row(
                            children: [
                              VIcon('warn', size: 16, color: Volt.warn),
                              const SizedBox(width: 8),
                              Expanded(child: Muted(_error!, color: Volt.warn)),
                            ],
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
