import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/cloud.dart';
import 'package:gymco/state/config_providers.dart';
import 'package:gymco/state/pack_providers.dart';
import 'package:gymco/state/training_providers.dart';

import '../helpers.dart';

ProviderContainer containerOf(WidgetTester t) => ProviderScope.containerOf(t.element(find.byType(GymcoApp)));

Future<void> go(WidgetTester t, String path) async {
  containerOf(t).read(routerProvider).go(path);
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Map<String, Object?> published(List<PackDownload> packs, {Map<String, Object?> config = const {}}) => {
  'config_version': 4,
  'config': config,
  'packs': packListing(packs),
  'announcements': <Object?>[],
};

Map<String, Object?> foodsBody(String id, String en, String ar) => {
  'items': [
    {'id': id, 'name': t3(en, ar), 'kcal': 160, 'protein': 6, 'carbs': 4, 'fat': 13, 'serving_g': 30},
  ],
};

/// The phone already holds [p], as a past launch left it.
Map<String, Object> holding(PackDownload p) => {
  'rc.pack.${p.kind}': p.bodyJson,
  'rc.pack.${p.kind}.version': p.version,
};

void main() {
  testWidgets('a pack with a bad checksum is ignored and the previous one kept', (tester) async {
    final v1 = servePack('foods', 1, foodsBody('labneh', 'Labneh', 'لبنة'));
    final v2 = servePack('foods', 2, foodsBody('shanklish', 'Shanklish', 'شنكليش'));
    final cloud = FakeCloud()
      ..config = published([v2])
      // The bytes arrive changed: they no longer hash to either checksum.
      ..packs = {'foods': PackDownload(kind: 'foods', version: 2, checksum: v2.checksum, bodyJson: '${v2.bodyJson} ')};
    final (_, prefs) = await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile, ...holding(v1)});
    await tester.pumpAndSettle();
    expect(cloud.packFetches, ['foods']);
    expect(prefs.getInt('rc.pack.foods.version'), 1);
    expect(prefs.getString('rc.pack.foods'), v1.bodyJson);
    expect(containerOf(tester).read(packsProvider).foods.map((f) => f.name), ['Labneh']);
  });

  testWidgets('a served checksum that differs from the listed one is ignored too', (tester) async {
    final v1 = servePack('foods', 1, foodsBody('labneh', 'Labneh', 'لبنة'));
    final cloud = FakeCloud()
      ..config = {
        ...published([v1]),
        'packs': packListing([v1], checksums: {'foods': 'f' * 64}),
      }
      ..packs = {'foods': v1};
    final (_, prefs) = await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    expect(prefs.getString('rc.pack.foods'), isNull);
    expect(containerOf(tester).read(packsProvider).foods, isEmpty);
  });

  testWidgets('an unchanged version is not downloaded again', (tester) async {
    final copy = servePack('copy', 3, {
      'overrides': {'remindMealBody': t3('Two taps and done.')},
    });
    final foods = servePack('foods', 1, foodsBody('labneh', 'Labneh', 'لبنة'));
    final cloud = FakeCloud()
      ..config = published([copy, foods])
      ..packs = {'copy': copy, 'foods': foods};
    await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile, ...holding(copy)});
    await tester.pumpAndSettle();
    expect(cloud.packFetches, ['foods']);
    await containerOf(tester).read(remoteConfigProvider.notifier).refresh();
    expect(cloud.packFetches, ['foods']);
  });

  testWidgets('a pack food is found in search by its Arabic name, and goes when unpublished', (tester) async {
    final foods = servePack('foods', 1, foodsBody('labneh', 'Labneh', 'لبنة'));
    final cloud = FakeCloud()
      ..config = published([foods])
      ..packs = {'foods': foods};
    final (db, _) = await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile}, locale: const Locale('ar'));
    await tester.pumpAndSettle();
    await go(tester, '/food');
    await tester.enterText(find.byType(TextField), 'لبنه');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('لبنة'), findsOneWidget);
    // Built-in staples are still there.
    expect((await db.searchFoods('banana')).map((f) => f.id), ['usda:banana']);

    cloud.config = published([]);
    await containerOf(tester).read(remoteConfigProvider.notifier).refresh();
    expect(await db.searchFoods('labneh'), isEmpty);
    expect(containerOf(tester).read(packsProvider).foods, isEmpty);
  });

  testWidgets('a pack template is listed after the built-ins on Train and fills the plan', (tester) async {
    final templates = servePack('templates', 1, {
      'items': [
        {
          'id': 'glutes',
          'name': t3('Glute focus, 2 days'),
          'level': 'beginner',
          'routines': [
            for (final (n, day) in [('Lower A', 0), ('Lower B', 3)])
              {
                'name': t3(n),
                'weekday': day,
                'items': [
                  {'exercise': 'squat', 'sets': 3, 'rep_low': 8, 'rep_high': 12, 'rest_s': 120},
                ],
              },
          ],
        },
      ],
    });
    final exercises = servePack('exercises', 1, {
      'items': [
        {
          'id': 'Landmine_Press',
          'name': t3('Landmine Press'),
          'primary': ['shoulders'],
          'secondary': <String>[],
        },
      ],
      'removed': ['ohp'],
    });
    final cloud = FakeCloud()
      ..config = published([templates, exercises])
      ..packs = {'templates': templates, 'exercises': exercises};
    final (db, _) = await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    await go(tester, '/train');
    expect(find.text('Upper / Lower, 4 days'), findsOneWidget);
    expect(find.text('Glute focus, 2 days'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Glute focus, 2 days')).dy,
      greaterThan(tester.getTopLeft(find.text('Full body, 3 days')).dy),
    );
    await tester.tap(find.text('Glute focus, 2 days'));
    await tester.pumpAndSettle();
    final all = await db.routines();
    expect(all.map((r) => r.name), ['Lower A', 'Lower B']);
    expect(all.map((r) => r.weekday), [0, 3]);
    expect(all.first.items.single.exerciseId, 'squat');

    final lib = await containerOf(tester).read(exerciseLibraryProvider.future);
    expect(lib.search('landmine').map((e) => e.id), ['Landmine_Press']);
    expect(lib.search('military'), isEmpty);
    expect(lib['ohp']?.name, 'Standing Military Press');
  });

  testWidgets('a copy override is shown, in the app language only', (tester) async {
    final copy = servePack('copy', 1, {
      'overrides': {
        'welcomeBody': {'en': 'Show up. That is the whole trick.', 'ar': 'احضر فقط.'},
      },
    });
    final cloud = FakeCloud()
      ..config = published([copy])
      ..packs = {'copy': copy};
    await pumpApp(tester, cloud: cloud);
    await tester.pumpAndSettle();
    expect(find.text('Show up. That is the whole trick.'), findsOneWidget);
    expect(find.text('Log food in seconds, train with a plan, and keep a streak worth protecting.'), findsNothing);
  });

  testWidgets('a copy override missing the app language falls back to the built-in', (tester) async {
    final copy = servePack('copy', 1, {
      'overrides': {
        'welcomeBody': {'en': 'Show up. That is the whole trick.', 'ar': 'احضر فقط.'},
      },
    });
    final cloud = FakeCloud()
      ..config = published([copy])
      ..packs = {'copy': copy};
    await pumpApp(tester, cloud: cloud, locale: const Locale('es'));
    await tester.pumpAndSettle();
    expect(
      find.text('Registra comida en segundos, entrena con un plan y mantén una racha que valga la pena.'),
      findsOneWidget,
    );
  });

  testWidgets('when the copy pack is unpublished the built-in text comes back', (tester) async {
    final copy = servePack('copy', 1, {
      'overrides': {'welcomeBody': t3('Show up. That is the whole trick.')},
    });
    final cloud = FakeCloud()..config = published([copy]);
    final (_, prefs) = await pumpApp(tester, cloud: cloud, prefs: holding(copy));
    expect(find.text('Show up. That is the whole trick.'), findsOneWidget);
    cloud.config = published([]);
    await containerOf(tester).read(remoteConfigProvider.notifier).refresh();
    await tester.pumpAndSettle();
    expect(find.text('Log food in seconds, train with a plan, and keep a streak worth protecting.'), findsOneWidget);
    expect(prefs.getString('rc.pack.copy'), isNull);
  });

  testWidgets("the month's challenge target and title come from the pack", (tester) async {
    final challenges = servePack('challenges', 1, {
      'items': [
        {'month': '2026-09', 'title': t3('September sprint'), 'target': 16},
        {'month': '2026-10', 'title': t3('October'), 'target': 8},
      ],
    });
    final cloud = FakeCloud()
      ..config = published([challenges])
      ..packs = {'challenges': challenges};
    await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    await go(tester, '/progress/awards');
    expect(find.text('0 / 16'), findsOneWidget);
    expect(find.text('September sprint'), findsOneWidget);
  });

  testWidgets('a manual grant unlocks Pro when testing mode is off', (tester) async {
    final cloud = FakeCloud(signedIn: 'pat@example.com')
      ..config = published(
        [],
        config: {
          'plans': {'testing_unlock_all': false},
        },
      )
      ..entitlement = Entitlement(plan: 'pro', expiresAt: DateTime(2027, 1, 1));
    await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    await go(tester, '/me');
    expect(containerOf(tester).read(proAccessProvider), ProAccess.granted);
    expect(find.text('Pro is on'), findsOneWidget);
    expect(find.textContaining('unlocked for your account'), findsOneWidget);
  });

  testWidgets('with testing mode off and no grant, Pro stays locked', (tester) async {
    final cloud = FakeCloud(signedIn: 'pat@example.com')
      ..config = published(
        [],
        config: {
          'plans': {'testing_unlock_all': false},
        },
      )
      // Expired.
      ..entitlement = Entitlement(plan: 'pro', expiresAt: DateTime(2026, 1, 1));
    await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile});
    await go(tester, '/me');
    expect(find.text('Pro is coming'), findsOneWidget);
    expect(containerOf(tester).read(proAccessProvider), ProAccess.locked);
    expect(containerOf(tester).read(proUnlockedProvider), isFalse);
  });

  testWidgets('in testing mode Pro is on for everyone', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile});
    expect(containerOf(tester).read(proAccessProvider), ProAccess.testing);
    expect(containerOf(tester).read(proUnlockedProvider), isTrue);
  });
}
