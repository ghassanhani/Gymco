import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/photo_store.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../state/progress_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

String poseName(AppLocalizations l, Pose p) => switch (p) {
  Pose.front => l.poseFront,
  Pose.side => l.poseSide,
  Pose.back => l.poseBack,
};

/// Progress photos: today's three poses, then any two days side by side.
class PhotosView extends ConsumerStatefulWidget {
  const PhotosView({super.key});

  @override
  ConsumerState<PhotosView> createState() => _PhotosViewState();
}

class _PhotosViewState extends ConsumerState<PhotosView> {
  Pose _pose = Pose.front;
  String? _from;

  Future<void> _take(Pose pose) async {
    final l = AppLocalizations.of(context);
    final camera = await showVSheet<bool>(
      context,
      title: l.photoOf(poseName(l, pose)),
      body: (ctx) => [
        SRow(
          label: l.takePhoto,
          lead: VIcon('camera', size: 18, color: Volt.brandInk),
          onTap: () => Navigator.pop(ctx, true),
        ),
        SRow(
          label: l.chooseFromLibrary,
          lead: VIcon('list', size: 18, color: Volt.t2),
          onTap: () => Navigator.pop(ctx, false),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.photoTip)),
      ],
    );
    if (camera == null) return;
    final bytes = await ref.read(photoPickerProvider).pick(camera: camera);
    if (bytes == null || !mounted) return;
    await ref.read(photoStoreProvider).save(dayKey(ref.read(clockProvider)()), pose, bytes);
    ref.invalidate(progressPhotosProvider);
  }

  void _open(ProgressPhoto p) {
    final l = AppLocalizations.of(context);
    showVSheet<void>(
      context,
      title: '${poseName(l, p.pose)} · ${_date(context, p.day)}',
      body: (ctx) => [
        ClipSmooth(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Image(image: ref.read(photoStoreProvider).image(p), fit: BoxFit.cover),
          ),
        ),
        SRow(
          label: l.deletePhoto,
          tint: Volt.warn,
          onTap: () async {
            Navigator.pop(ctx);
            await ref.read(photoStoreProvider).delete(p);
            ref.invalidate(progressPhotosProvider);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final days = ref.watch(progressPhotosProvider).value ?? const [];
    final today = dayKey(ref.watch(clockProvider)());
    final todays = days.where((d) => d.$1 == today).firstOrNull?.$2 ?? const <Pose, ProgressPhoto>{};
    final withPose = [
      for (final (d, m) in days)
        if (m[_pose] != null) (d, m[_pose]!),
    ];
    final latest = withPose.firstOrNull;
    final fromDay = withPose.length < 2
        ? null
        : withPose.firstWhere((x) => x.$1 == _from && x.$1 != latest!.$1, orElse: () => withPose.last);

    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        VCard(
          child: GapCol(
            gap: 12,
            cross: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Eyebrow(l.todaysPhotos)),
                  VIcon('shield', size: 14, color: Volt.t3),
                  const SizedBox(width: 4),
                  Text(l.onThisPhone, style: TextStyle(fontSize: 12, color: Volt.t3)),
                ],
              ),
              Row(
                children: [
                  for (final (i, pose) in Pose.values.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _Slot(
                        label: poseName(l, pose),
                        photo: todays[pose],
                        onTap: () => todays[pose] == null ? _take(pose) : _open(todays[pose]!),
                      ),
                    ),
                  ],
                ],
              ),
              Muted(l.photosNote),
            ],
          ),
        ),
        if (fromDay != null && latest != null)
          VCard(
            child: GapCol(
              gap: 12,
              cross: CrossAxisAlignment.stretch,
              children: [
                Eyebrow(l.compareLbl),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in Pose.values)
                      VChip(label: poseName(l, p), on: _pose == p, onTap: () => setState(() => _pose = p)),
                  ],
                ),
                Row(
                  children: [
                    for (final (i, (d, p)) in [fromDay, latest].indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: GapCol(
                          gap: 6,
                          children: [
                            _Slot(label: '', photo: p, onTap: () => _open(p)),
                            Text(
                              i == 0 ? _date(context, d) : l.latestOn(_date(context, d)),
                              style: TextStyle(fontSize: 12.5, color: Volt.t2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Muted(l.compareFrom),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (d, _) in withPose.skip(1)) ...[
                        VChip(label: _date(context, d), on: d == fromDay.$1, onTap: () => setState(() => _from = d)),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )
        else if (days.isNotEmpty)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.compareNeedsTwo)),
      ],
    );
  }
}

String _date(BuildContext context, String day) =>
    DateFormat('d MMM', Localizations.localeOf(context).toString()).format(DateTime.parse(day));

class _Slot extends ConsumerWidget {
  const _Slot({required this.label, required this.photo, required this.onTap});
  final String label;
  final ProgressPhoto? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Pressable(
      onTap: onTap,
      label: photo == null ? l.addPhotoOf(label) : label,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: smooth(
            BoxDecoration(
              color: Volt.card2,
              borderRadius: BorderRadius.circular(16),
              border: photo == null ? Border.all(color: Volt.line2) : null,
            ),
          ),
          child: photo == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VIcon('camera', size: 22, color: Volt.brandInk),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Volt.t2),
                    ),
                  ],
                )
              : Image(image: ref.read(photoStoreProvider).image(photo!), fit: BoxFit.cover, gaplessPlayback: true),
        ),
      ),
    );
  }
}
