import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/training.dart';
import '../../l10n/app_localizations.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

/// The exercise's first photo as a rounded thumbnail; tapping it opens the
/// photos full screen. Falls back to the equipment badge when there is no
/// photo, while it loads, or when photos are off.
class ExThumb extends ConsumerWidget {
  const ExThumb(this.exercise, {super.key, this.size = 52});
  final Exercise? exercise;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = exercise;
    if (e == null || e.images.isEmpty || !ref.watch(showExercisePhotosProvider)) {
      return SizedBox.square(
        dimension: size,
        child: Center(child: ExAv(e?.badge ?? '··')),
      );
    }
    final radius = BorderRadius.circular(size * 0.3);
    final badge = Container(
      color: Volt.card2,
      alignment: Alignment.center,
      child: e.badge == '•'
          ? VIcon('dumb', size: size * 0.4, color: Volt.t3)
          : Text(
              e.badge,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.22, color: Volt.t3),
            ),
    );
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return Semantics(
      container: true,
      button: true,
      label: AppLocalizations.of(context).showPhotosOf(e.name),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showExercisePhotos(context, e),
        child: Hero(
          tag: 'exphoto:${e.id}:0',
          child: ClipRRect(
            borderRadius: radius,
            child: SizedBox.square(
              dimension: size,
              child: Image(
                image: ResizeImage.resizeIfNeeded(px, null, ref.watch(exerciseImageProvider)(e.imageUrl(0))),
                fit: BoxFit.cover,
                frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : badge,
                errorBuilder: (_, _, _) => badge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The exercise's photos, large: swipe between them, pinch to zoom.
Future<void> showExercisePhotos(BuildContext context, Exercise e, {int initial = 0}) => Navigator.of(context).push(
  PageRouteBuilder<void>(
    opaque: false,
    barrierColor: const Color(0xFA0A0B09),
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => _PhotoViewer(exercise: e, initial: initial),
    transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
  ),
);

class _PhotoViewer extends ConsumerStatefulWidget {
  const _PhotoViewer({required this.exercise, required this.initial});
  final Exercise exercise;
  final int initial;

  @override
  ConsumerState<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends ConsumerState<_PhotoViewer> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _at = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final e = widget.exercise;
    final n = e.images.length;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Volt.t1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconBtn('close', label: l.closePhotos, onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: n,
                onPageChanged: (i) => setState(() => _at = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: Hero(
                        tag: 'exphoto:${e.id}:$i',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image(
                            image: ref.watch(exerciseImageProvider)(e.imageUrl(i)),
                            fit: BoxFit.contain,
                            frameBuilder: (_, child, frame, sync) => sync || frame != null
                                ? child
                                : SizedBox.square(
                                    dimension: 28,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Volt.lime),
                                  ),
                            errorBuilder: (_, _, _) => Muted(l.photoUnavailable),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (n > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < n; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _at ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _at ? Volt.lime : Volt.line2,
                          borderRadius: BorderRadius.circular(999),
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
