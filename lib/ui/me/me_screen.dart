import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/cheat_meal.dart';
import '../../domain/energy.dart';
import '../../domain/reminders.dart';
import '../../data/site.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../state/providers.dart';
import '../../state/reminder_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'reminder_sheet.dart';
import '../today/today_screen.dart' show goalShort;
import 'account_card.dart';
import 'pro_screen.dart';
import '../../state/config_providers.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  static const languages = {'en': 'English', 'ar': 'العربية', 'es': 'Español'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final profile = ref.watch(profileProvider);
    final reminders = ref.watch(reminderSettingsProvider);
    final now = ref.watch(clockProvider)();
    final week = profile == null ? 1 : now.difference(profile.startedOn).inDays ~/ 7 + 1;

    Widget row(String icon, String title, String sub, VoidCallback onTap, {Widget? right}) => VItem(
      onTap: onTap,
      semantics: title,
      children: [
        VIcon(icon, size: 19, color: Volt.t3),
        ItemText(title, sub: sub),
        right ?? VIcon('fwd', size: 18, color: Volt.t1),
      ],
    );

    String cheatLabel(CheatAllowance a) => switch (a) {
      CheatAllowance.off => l.cheatOff,
      CheatAllowance.oncePerWeek => l.cheatOnce,
      CheatAllowance.twicePerWeek => l.cheatTwice,
    };

    String lookLabel(Appearance a) => switch (a) {
      Appearance.dark => l.appearanceDark,
      Appearance.light => l.appearanceLight,
      Appearance.system => l.appearanceSystem,
    };

    final cloud = ref.watch(cloudProvider);
    final email = ref.watch(accountProvider).value ?? cloud.email;
    final langLabel = s.languageCode == null ? l.systemLanguage : languages[s.languageCode]!;

    return VScreen(
      child: Column(
        children: [
          VAppBar(title: l.meTitle, sub: profile == null ? null : l.meSub(goalShort(l, profile.goal), week)),
          Expanded(
            child: Pad(
              children: [
                const SignInCard(),
                const ProCard(),
                VList(
                  children: [
                    if (profile != null)
                      row(
                        'chart',
                        l.goalAndTargets,
                        '${fmtInt(context, profile.targetKcal)} ${l.kcal} · ${goalShort(l, profile.goal)}',
                        () => context.push('/onboarding'),
                      ),
                    row('list', l.unitsLanguage, langLabel, () => context.push('/language')),
                    row(
                      'sun',
                      l.appearance,
                      lookLabel(s.appearance),
                      () => showVSheet<void>(
                        context,
                        title: l.appearance,
                        body: (ctx) => [
                          for (final a in [Appearance.dark, Appearance.light, Appearance.system])
                            SRow(
                              label: lookLabel(a),
                              on: a == s.appearance,
                              trail: a == s.appearance ? VIcon('check', size: 18, color: Volt.brandInk) : null,
                              onTap: () {
                                Navigator.pop(ctx);
                                notifier.setAppearance(a);
                              },
                            ),
                        ],
                      ),
                    ),
                    row(
                      'user',
                      l.accountTitle,
                      !cloud.available
                          ? l.accountRowOff
                          : email == null
                          ? l.accountRowSub
                          : l.accountRowSignedIn(email),
                      () => context.push('/account'),
                    ),
                    row(
                      'shield',
                      l.healthData,
                      ref.watch(healthOnProvider) ? l.healthOn : l.healthDataSub,
                      () => context.push('/health'),
                    ),
                    row('dl', l.yourData, l.yourDataSub, () => context.push('/data')),
                  ],
                ),
                if (ref.watch(remoteConfigProvider).cheatMeals) ...[
                  Eyebrow(l.safeguards, padding: const EdgeInsetsDirectional.only(start: 4)),
                  VList(
                    children: [
                      row(
                        'star',
                        l.cheatAllowance,
                        cheatLabel(s.cheatAllowance),
                        () => showVSheet<void>(
                          context,
                          title: l.cheatAllowance,
                          body: (ctx) => [
                            for (final a in CheatAllowance.values)
                              SRow(
                                label: cheatLabel(a),
                                on: a == s.cheatAllowance,
                                trail: a == s.cheatAllowance ? VIcon('check', size: 18, color: Volt.brandInk) : null,
                                onTap: () {
                                  notifier.setCheatAllowance(a);
                                  Navigator.pop(ctx);
                                },
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Muted(l.cheatAllowanceNote),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                Eyebrow(l.reminders, padding: const EdgeInsetsDirectional.only(start: 4)),
                VList(
                  children: [
                    for (final (kind, icon, title, sub, on) in [
                      (
                        ReminderKind.lunch,
                        'food',
                        l.remindMeals,
                        l.remindMealsSub(
                          fmtClockTime(context, reminders.mealAt[ReminderKind.breakfast]!),
                          fmtClockTime(context, reminders.mealAt[ReminderKind.lunch]!),
                          fmtClockTime(context, reminders.mealAt[ReminderKind.dinner]!),
                        ),
                        reminders.meals,
                      ),
                      (
                        ReminderKind.water,
                        'drop',
                        l.remindWater,
                        l.remindWaterSub(
                          fmtClockTime(context, reminders.waterAt[0]),
                          fmtClockTime(context, reminders.waterAt[1]),
                          fmtClockTime(context, reminders.waterAt[2]),
                        ),
                        reminders.water,
                      ),
                      (
                        ReminderKind.workout,
                        'dumb',
                        l.remindWorkout,
                        l.remindWorkoutSub(fmtClockTime(context, reminders.workoutAt)),
                        reminders.workout,
                      ),
                    ])
                      row(
                        icon,
                        title,
                        sub,
                        () => showReminderSheet(context, kind),
                        right: Pressable(
                          label: l.toggleReminder(title),
                          onTap: () async {
                            final ok = await ref.read(reminderSettingsProvider.notifier).set(kind, !on);
                            if (!ok && context.mounted) showVToast(context, l.remindersOff, info: true);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: VToggle(on: on),
                          ),
                        ),
                      ),
                  ],
                ),
                VCard(
                  child: GapCol(
                    gap: 10,
                    children: [
                      Eyebrow(l.calorieFloor),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(fmtInt(context, defaultKcalFloor), style: numStyle(22)),
                          const SizedBox(width: 8),
                          Flexible(child: Muted(l.floorSub)),
                        ],
                      ),
                      Muted(l.floorBody),
                    ],
                  ),
                ),
                Eyebrow(l.aboutGymco, padding: const EdgeInsetsDirectional.only(start: 4)),
                VList(
                  children: [
                    row('list', l.faqTitle, l.faqSub, () => context.push('/faq')),
                    row('info', l.helpSupport, l.helpSupportSub, () => context.push('/help')),
                    row('sparkles', l.requestFeature, l.requestFeatureSub, () => context.push('/feature')),
                    row('wifi', l.helpOnSite, l.helpOnSiteSub, () => openSite('support')),
                    row('shield', l.privacyPolicy, l.privacyPolicySub, () => openSite('privacy')),
                    row('list', l.termsOfUse, l.termsOfUseSub, () => openSite('terms')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Units & language, as the canvas draws it.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final options = <(String?, String, String)>[
      (null, l.systemLanguage, l.followsPhone),
      ('en', 'English', l.langEnglishSub),
      ('ar', 'العربية', l.langArabicSub),
      ('es', 'Español', l.langSpanishSub),
    ];
    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: l.unitsLanguage, titleSize: 20),
            Expanded(
              child: Pad(
                bottom: 24,
                children: [
                  Eyebrow(l.language, padding: const EdgeInsetsDirectional.only(start: 4)),
                  VList(
                    children: [
                      for (final (code, name, sub) in options)
                        VItem(
                          onTap: () {
                            n.setLanguage(code);
                            // The next sign-in email follows the new language.
                            ref
                                .read(cloudProvider)
                                .rememberLocale(code ?? PlatformDispatcher.instance.locale.languageCode);
                          },
                          semantics: name,
                          children: [
                            ItemText(name, sub: sub),
                            if (s.languageCode == code) VIcon('check', size: 18, color: Volt.accentInk),
                          ],
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: smooth(BoxDecoration(color: Volt.brandWash, borderRadius: BorderRadius.circular(18))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: VIcon('info', size: 18, color: Volt.t2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(l.rtlNote, style: TextStyle(fontSize: 13, height: 1.45, color: Volt.t2)),
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

String goalLong(AppLocalizations l, Goal g) => switch (g) {
  Goal.cut => l.goalCut,
  Goal.bulk => l.goalBulk,
  Goal.recomp => l.goalRecomp,
  Goal.maintain => l.goalMaintain,
  Goal.prep => l.goalPrep,
};
