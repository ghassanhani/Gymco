import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

/// The top of Me while signed out: what an account adds, and the way in.
/// Hidden once signed in (the Account row shows the email) and in builds
/// without accounts.
class SignInCard extends ConsumerWidget {
  const SignInCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cloud = ref.watch(cloudProvider);
    final email = ref.watch(accountProvider).value ?? cloud.email;
    if (!cloud.available || email != null) return const SizedBox.shrink();
    return VCard(
      child: GapCol(
        gap: 14,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Volt.brandWash, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const VIcon('user', size: 21, color: Volt.brandInk),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GapCol(
                  gap: 2,
                  children: [
                    Text(
                      l.meSignInTitle,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Volt.t1),
                    ),
                    Muted(l.meSignInSub, size: 13),
                  ],
                ),
              ),
            ],
          ),
          VBtn(label: l.meSignInCta, icon: 'user', expand: true, onTap: () => context.push('/account')),
        ],
      ),
    );
  }
}
