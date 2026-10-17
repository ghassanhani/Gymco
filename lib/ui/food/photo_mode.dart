import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/cloud.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import '../me/account_screen.dart' show cloudMessage;

/// Photograph the plate; the server names what it sees, the user picks the
/// foods and sets the amounts. It never guesses grams.
class PhotoMode extends ConsumerStatefulWidget {
  const PhotoMode({super.key, required this.onPick});

  /// One of the suggested foods was tapped.
  final ValueChanged<PhotoFood> onPick;

  @override
  ConsumerState<PhotoMode> createState() => _PhotoModeState();
}

class _PhotoModeState extends ConsumerState<PhotoMode> {
  Uint8List? _shot;
  bool _reading = false;
  List<PhotoFood>? _foods;
  int? _left;
  CloudFailure? _failure;

  Future<void> _take({required bool camera}) async {
    final jpeg = await ref.read(photoPickerProvider).pick(camera: camera);
    if (jpeg == null || !mounted) return;
    setState(() {
      _shot = jpeg;
      _reading = true;
      _foods = null;
      _failure = null;
    });
    try {
      final (foods, left) = await ref
          .read(cloudProvider)
          .scanPhoto(jpeg, languageCode: Localizations.localeOf(context).languageCode);
      if (!mounted) return;
      setState(() {
        _foods = foods;
        _left = left;
      });
    } on CloudException catch (e) {
      if (!mounted) return;
      setState(() {
        _failure = e.failure;
        if (e.failure == CloudFailure.dailyCap) _left = 0;
      });
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Widget _note(String icon, String text, {Color color = Volt.t3, Color? edge}) => VCard(
    tight: true,
    border: Border.all(color: edge ?? Volt.line2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: VIcon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Muted(text)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cloud = ref.watch(cloudProvider);
    final email = ref.watch(accountProvider).value ?? cloud.email;

    if (!cloud.available) return _note('info', l.photoNotSetUp);
    if (email == null) {
      return GapCol(
        gap: 12,
        cross: CrossAxisAlignment.stretch,
        children: [
          _note('info', l.photoNeedsAccount),
          VBtn(label: l.signInAction, expand: true, onTap: () => context.push('/account')),
        ],
      );
    }

    final foods = _foods;
    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        if (_shot == null || (foods == null && !_reading))
          _Capture(onCamera: () => _take(camera: true), onLibrary: () => _take(camera: false), text: l.photoPrompt)
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.memory(
                    _shot!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(color: Volt.card),
                  ),
                ),
                if (_reading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: const Color(0x990A0B09),
                      child: Center(
                        child: GapCol(
                          gap: 12,
                          cross: CrossAxisAlignment.center,
                          children: [
                            const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Volt.brand),
                            ),
                            Muted(l.readingPlate, color: Volt.t1),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (_failure case final f?) _note('warn', cloudMessage(l, f), color: Volt.warn, edge: Volt.warnEdge),
        if (foods != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: Eyebrow(l.plateThings(foods.length))),
                if (foods.isNotEmpty) Muted(l.tapToConfirm),
              ],
            ),
          ),
          if (foods.isNotEmpty)
            VList(
              children: [
                for (final f in foods)
                  VItem(
                    semantics: f.local,
                    onTap: () => widget.onPick(f),
                    children: [
                      ItemText(f.local, sub: f.sure ? l.fairlyConfident : l.notSureCheck),
                      const Pick(),
                    ],
                  ),
              ],
            ),
          _note('warn', l.photoAmountNote, color: Volt.warn, edge: Volt.warnEdge),
          VBtn(
            label: l.photoAgain,
            kind: BtnKind.ghost,
            icon: 'camera',
            expand: true,
            onTap: () => _take(camera: true),
          ),
        ],
        if (_left != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Muted(l.scansLeft(_left!), align: TextAlign.center),
          ),
      ],
    );
  }
}

/// The dashed "photograph the plate" card, with a way into the library.
class _Capture extends StatelessWidget {
  const _Capture({required this.onCamera, required this.onLibrary, required this.text});
  final VoidCallback onCamera;
  final VoidCallback onLibrary;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GapCol(
      gap: 10,
      cross: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: l.takePhoto,
          child: GestureDetector(
            onTap: onCamera,
            child: CustomPaint(
              foregroundPainter: _Dashed(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
                decoration: BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(24)),
                child: GapCol(
                  gap: 12,
                  cross: CrossAxisAlignment.center,
                  children: [
                    const IconBtn('camera', label: '', onTap: null, iconSize: 22, color: Volt.t2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Muted(text, align: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        VBtn(label: l.choosePhoto, kind: BtnKind.ghost, expand: true, onTap: onLibrary),
      ],
    );
  }
}

/// `border-style: dashed` in line-2, on the card's 24 radius.
class _Dashed extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)).deflate(0.5);
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = Volt.line2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashed old) => false;
}
