import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/cloud.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import 'account_screen.dart' show cloudMessage;

/// An idea for Gymco, sent to the team: it lands in the Control Center's
/// Feature requests tab. Works signed out.
class FeatureRequestScreen extends ConsumerStatefulWidget {
  const FeatureRequestScreen({super.key});

  @override
  ConsumerState<FeatureRequestScreen> createState() => _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends ConsumerState<FeatureRequestScreen> {
  late final TextEditingController _email;
  final _idea = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: ref.read(accountProvider).value ?? ref.read(cloudProvider).email ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _idea.dispose();
    super.dispose();
  }

  bool get _ready => !_busy && _email.text.contains('@') && _idea.text.trim().length >= 3;

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final idea = _idea.text.trim();
    final firstLine = idea.split('\n').first;
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
            subject: firstLine.length > 80 ? '${firstLine.substring(0, 80)}…' : firstLine,
            body: idea,
            locale: meta.locale,
            appVersion: meta.appVersion,
            platform: meta.platform,
            kind: 'feature',
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
    showVToast(context, l.requestFeatureSent);
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
            BackBar(title: l.requestFeature, sub: l.requestFeatureSub, titleSize: 20),
            Expanded(
              child: Pad(
                children: [
                  VCard(
                    child: GapCol(
                      gap: 12,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const Key('feature-idea'),
                          controller: _idea,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          minLines: 4,
                          maxLines: 10,
                          maxLength: 2000,
                          onChanged: (_) => setState(() {}),
                          style: style,
                          decoration: InputDecoration(hintText: l.requestFeatureHint, counterText: ''),
                        ),
                        TextField(
                          key: const Key('feature-email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) => setState(() {}),
                          style: style,
                          decoration: InputDecoration(hintText: l.requestFeatureEmail),
                        ),
                        VBtn(label: l.requestFeatureSend, expand: true, onTap: _ready ? _send : null),
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
