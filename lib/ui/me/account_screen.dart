import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/cloud.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

/// What to tell the user when a cloud call fails.
String cloudMessage(AppLocalizations l, CloudFailure f) => switch (f) {
  CloudFailure.notSetUp => l.cloudNotSetUp,
  CloudFailure.offline => l.errOffline,
  CloudFailure.badCode => l.errBadCode,
  CloudFailure.busy => l.errBusy,
  CloudFailure.dailyCap => l.photoCap,
  CloudFailure.refused => l.photoRefused,
  CloudFailure.signedOut || CloudFailure.unknown => l.errGeneric,
};

String _when(BuildContext context, DateTime at) =>
    DateFormat('d MMM, HH:mm', Localizations.localeOf(context).toString()).format(at);

/// Sign in with an emailed code, back up, restore, sign out, delete.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Runs [job], showing a failure under the form rather than throwing.
  Future<bool> _run(Future<void> Function() job) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await job();
      return true;
    } on CloudException catch (e) {
      if (mounted) setState(() => _error = cloudMessage(l, e.failure));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (!_email.text.contains('@')) return;
    final ok = await _run(() => ref.read(cloudProvider).sendCode(_email.text));
    if (ok && mounted) setState(() => _codeSent = true);
  }

  Future<void> _verify() async {
    final ok = await _run(() => ref.read(cloudProvider).verifyCode(_email.text, _code.text));
    if (ok && mounted) await _afterSignIn();
  }

  /// Signed in by the typed code or by the email's link, whichever came
  /// first; the other one must not run this again.
  bool _signedInHere = false;

  Future<void> _afterSignIn() async {
    if (_signedInHere) return;
    _signedInHere = true;
    final cloud = ref.read(cloudProvider);
    _code.clear();
    setState(() => _codeSent = false);
    // A backup already in the account: ask before either side wins.
    CloudBackup? found;
    await _run(() async => found = await cloud.download());
    if (!mounted) return;
    if (found != null) {
      await _offerRestore(found!, foundOnSignIn: true);
    } else {
      await _run(() => ref.read(cloudActionsProvider).backupNow());
    }
  }

  Future<void> _offerRestore(CloudBackup b, {bool foundOnSignIn = false}) {
    final l = AppLocalizations.of(context);
    final when = _when(context, b.at);
    return showVSheet<void>(
      context,
      title: foundOnSignIn ? l.foundBackupTitle : l.restoreTitle,
      body: (ctx) => [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Muted(foundOnSignIn ? l.foundBackupBody(when) : l.restoreBody(when)),
        ),
        SRow(
          label: l.restoreIt,
          tint: Volt.brandInk,
          onTap: () async {
            Navigator.pop(ctx);
            if (await _run(() => ref.read(cloudActionsProvider).restore(b)) && mounted) {
              showVToast(context, l.restored);
            }
          },
        ),
        SRow(
          label: l.keepThisPhone,
          onTap: () async {
            Navigator.pop(ctx);
            if (foundOnSignIn) await _run(() => ref.read(cloudActionsProvider).backupNow());
          },
        ),
      ],
    );
  }

  Future<void> _restore() async {
    final l = AppLocalizations.of(context);
    CloudBackup? b;
    if (!await _run(() async => b = await ref.read(cloudProvider).download()) || !mounted) return;
    if (b == null) {
      showVToast(context, l.noBackupYet, info: true);
      return;
    }
    await _offerRestore(b!);
  }

  Future<void> _deleteAccount() {
    final l = AppLocalizations.of(context);
    return showVSheet<void>(
      context,
      title: l.deleteAccount,
      body: (ctx) => [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.deleteAccountBody)),
        SRow(label: l.keepMyData, onTap: () => Navigator.pop(ctx)),
        SRow(
          label: l.deleteAccountConfirm,
          tint: Volt.warn,
          onTap: () async {
            Navigator.pop(ctx);
            if (await _run(() => ref.read(cloudProvider).deleteAccount()) && mounted) {
              showVToast(context, l.accountDeleted);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cloud = ref.watch(cloudProvider);
    // The email's link signs in outside this screen; pick up from there.
    ref.listen(accountProvider, (was, now) {
      if (_codeSent && was?.value == null && now.value != null) _afterSignIn();
    });
    final email = ref.watch(accountProvider).value ?? cloud.email;
    final last = ref.watch(lastBackupProvider);

    final error = _error == null
        ? null
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VIcon('warn', size: 16, color: Volt.warn),
              const SizedBox(width: 8),
              Expanded(child: Muted(_error!, color: Volt.warn)),
            ],
          );

    final List<Widget> body;
    if (!cloud.available) {
      body = [
        VCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VIcon('info', size: 18, color: Volt.t3),
              const SizedBox(width: 10),
              Expanded(child: Muted(l.cloudNotSetUp, color: Volt.t2)),
            ],
          ),
        ),
      ];
    } else if (email == null) {
      body = [
        VCard(
          child: GapCol(
            gap: 12,
            cross: CrossAxisAlignment.stretch,
            children: [
              _Head(icon: 'user', title: l.signInTitle, sub: l.signInSub),
              if (!_codeSent) ...[
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 16, color: Volt.t1),
                  decoration: InputDecoration(hintText: l.emailHint),
                ),
                VBtn(label: l.sendCode, expand: true, onTap: _busy || !_email.text.contains('@') ? null : _send),
              ] else ...[
                Muted(l.codeSentTo(_email.text.trim()), color: Volt.t2),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _verify(),
                  onChanged: (_) => setState(() {}),
                  style: numStyle(20, weight: FontWeight.w600),
                  decoration: InputDecoration(hintText: l.codeHint),
                ),
                VBtn(label: l.signInAction, expand: true, onTap: _busy || _code.text.length < 6 ? null : _verify),
                VBtn(
                  label: l.useOtherEmail,
                  kind: BtnKind.ghost,
                  expand: true,
                  onTap: () => setState(() {
                    _codeSent = false;
                    _error = null;
                  }),
                ),
              ],
              ?error,
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.accountWhy)),
      ];
    } else {
      body = [
        VCard(
          child: _Head(icon: 'user', title: email, sub: l.signedInAs),
        ),
        VCard(
          child: GapCol(
            gap: 12,
            cross: CrossAxisAlignment.stretch,
            children: [
              _Head(
                icon: 'dl',
                title: l.backupTitle,
                sub: last == null ? l.notBackedUp : l.backedUpAt(_when(context, last)),
              ),
              Muted(l.backupAuto),
              VBtn(
                label: l.backupNow,
                kind: BtnKind.ghost,
                expand: true,
                onTap: _busy
                    ? null
                    : () async {
                        if (await _run(() => ref.read(cloudActionsProvider).backupNow()) && context.mounted) {
                          showVToast(context, l.backupDone);
                        }
                      },
              ),
              VBtn(label: l.restoreAction, kind: BtnKind.ghost, expand: true, onTap: _busy ? null : _restore),
              ?error,
            ],
          ),
        ),
        VList(
          children: [
            VItem(
              onTap: () => _run(() => ref.read(cloudProvider).signOut()),
              semantics: l.signOut,
              children: [
                const VIcon('back', size: 19, color: Volt.t3),
                ItemText(l.signOut, sub: l.signOutNote),
              ],
            ),
          ],
        ),
        VCard(
          border: Border.all(color: Volt.line2),
          child: GapCol(
            gap: 12,
            cross: CrossAxisAlignment.stretch,
            children: [
              _Head(icon: 'trash', title: l.deleteAccount, sub: l.deleteAccountSub, lime: true),
              Pressable(
                onTap: _busy ? null : _deleteAccount,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Volt.brandEdge, width: 1.5),
                  ),
                  child: Text(
                    l.deleteAccountConfirm,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.brandInk),
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: l.accountTitle, titleSize: 20),
            Expanded(child: Pad(bottom: 24, children: body)),
          ],
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.icon, required this.title, required this.sub, this.lime = false});
  final String icon;
  final String title;
  final String sub;
  final bool lime;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: lime ? Volt.brandWash : Volt.card2, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: VIcon(icon, size: 19, color: lime ? Volt.brandInk : Volt.t1),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: GapCol(
          gap: 2,
          children: [
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
            ),
            Muted(sub),
          ],
        ),
      ),
    ],
  );
}
