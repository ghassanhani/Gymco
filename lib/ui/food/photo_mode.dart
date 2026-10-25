import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/cloud.dart';
import '../../data/meal_reader.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import '../me/account_screen.dart' show cloudMessage;
import 'confirm_log.dart';
import '../../state/config_providers.dart';

/// Photograph the plate, say or write what is on it, or both. The server
/// names the foods and estimates each portion; foods the phone knows keep the
/// database's figures, the rest are logged as AI estimates. Every amount can
/// be changed before it goes in.
class PhotoMode extends ConsumerStatefulWidget {
  const PhotoMode({super.key, required this.meal, required this.onSearch, required this.onDone});
  final Meal meal;

  /// A food neither the phone nor the model could put numbers on.
  final ValueChanged<String> onSearch;

  /// Everything chosen was logged.
  final ValueChanged<int> onDone;

  @override
  ConsumerState<PhotoMode> createState() => _PhotoModeState();
}

class _Row {
  _Row(this.guess, this.food);
  final PhotoFood guess;
  final Food? food;
  bool added = false;

  double get grams => guess.grams ?? food?.servingGrams ?? 100;
  double get kcal => (food?.kcal ?? 0) * grams / 100;
}

class _PhotoModeState extends ConsumerState<PhotoMode> {
  final _note = TextEditingController();
  Uint8List? _shot;
  bool _reading = false;
  bool _listening = false;
  List<_Row>? _rows;
  int? _left;
  CloudFailure? _failure;

  @override
  void dispose() {
    if (_listening) ref.read(dictationProvider).stop();
    _note.dispose();
    super.dispose();
  }

  Future<void> _take({required bool camera}) async {
    final jpeg = await ref.read(photoPickerProvider).pick(camera: camera);
    if (jpeg == null || !mounted) return;
    await _scan(jpeg);
  }

  /// Reads the photo and the note; either may be missing, not both.
  Future<void> _scan(Uint8List? jpeg) async {
    final lang = Localizations.localeOf(context).languageCode;
    if (_listening) await _toggleDictation();
    if (!mounted) return;
    setState(() {
      _shot = jpeg;
      _reading = true;
      _rows = null;
      _failure = null;
    });
    try {
      final (foods, left) = await ref
          .read(cloudProvider)
          .scanPhoto(jpeg, languageCode: lang, note: _note.text, bucket: ref.read(installBucketProvider));
      final db = ref.read(dbProvider);
      final rows = [for (final f in foods) _Row(f, await resolveEstimate(db, f))];
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  Future<void> _toggleDictation() async {
    final d = ref.read(dictationProvider);
    if (_listening) {
      await d.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final before = _note.text.trim();
    final ok = await d.start(
      languageCode: Localizations.localeOf(context).languageCode,
      onWords: (w) {
        if (!mounted) return;
        setState(() => _note.text = before.isEmpty ? w : '$before $w');
      },
    );
    if (mounted) setState(() => _listening = ok);
  }

  /// Opens one food to check its amount, and comes back to the list.
  Future<void> _open(_Row r) async {
    if (r.food == null) return widget.onSearch(r.guess.name);
    final added = await context.push<bool>(
      '/serving/${Uri.encodeComponent(r.food!.id)}?meal=${widget.meal.name}&grams=${r.grams.round()}&back=1&confirm=1',
    );
    if (added == true && mounted) setState(() => r.added = true);
  }

  Future<void> _addAll(List<_Row> rows) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmLog(
      context,
      meal: mealName(l, widget.meal).toLowerCase(),
      lines: [
        for (final r in rows)
          (
            name: foodName(context, r.food!.id, r.food!.name),
            grams: r.grams,
            kcal: r.kcal,
            protein: r.food!.protein * r.grams / 100,
          ),
      ],
    );
    if (!ok || !mounted) return;
    final day = ref.read(todayKeyProvider);
    final logs = ref.read(logActionsProvider);
    for (final r in rows) {
      await logs.add(LogEntry.of(r.food!, day: day, meal: widget.meal, grams: r.grams));
      r.added = true;
    }
    if (mounted) widget.onDone(rows.length);
  }

  Widget _card(String icon, String text, {Color? color, Color? edge}) => VCard(
    tight: true,
    border: Border.all(color: edge ?? Volt.line2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: VIcon(icon, size: 17, color: color ?? Volt.t3),
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

    if (!cloud.available) return _card('info', l.photoNotSetUp);
    if (email == null) {
      return GapCol(
        gap: 12,
        cross: CrossAxisAlignment.stretch,
        children: [
          _card('info', l.photoNeedsAccount),
          VBtn(label: l.signInAction, expand: true, onTap: () => context.push('/account')),
        ],
      );
    }

    final rows = _rows;
    final open = [...?rows?.where((r) => r.food != null && !r.added)];
    final total = open.fold<double>(0, (s, r) => s + r.kcal);

    final noteBox = Stack(
      children: [
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          maxLength: ref.watch(remoteConfigProvider).photoNoteMaxChars,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 15, height: 1.45, color: Volt.t1),
          decoration: InputDecoration(
            hintText: l.photoNoteHint,
            hintMaxLines: 3,
            counterText: '',
            filled: true,
            fillColor: Volt.field,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 13, 52, 13),
            border: SmoothInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: SmoothInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Volt.lime),
            ),
          ),
        ),
        if (ref.watch(remoteConfigProvider).dictate)
          PositionedDirectional(
            end: 6,
            top: 6,
            child: IconBtn(
              'mic',
              label: l.dictateNote,
              size: 38,
              iconSize: 18,
              background: _listening ? Volt.brand : Volt.card2,
              color: _listening ? Volt.ink : Volt.t2,
              onTap: _toggleDictation,
            ),
          ),
      ],
    );

    return GapCol(
      gap: 12,
      cross: CrossAxisAlignment.stretch,
      children: [
        if (_shot == null && rows == null && !_reading) ...[
          _Capture(onCamera: () => _take(camera: true), onLibrary: () => _take(camera: false), text: l.photoPrompt),
          noteBox,
          if (_note.text.trim().isNotEmpty) AiBtn(label: l.estimateFromNote, onTap: () => _scan(null)),
        ] else ...[
          if (_shot != null)
            ClipSmooth(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.memory(
                      _shot!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(color: Volt.card),
                    ),
                  ),
                  if (_reading) const Positioned.fill(child: _Reading()),
                ],
              ),
            )
          else if (_reading)
            const SizedBox(height: 120, child: _Reading()),
          if (_note.text.trim().isNotEmpty && !_reading) _card('list', _note.text.trim()),
        ],
        if (_failure case final f?) _card('warn', cloudMessage(l, f), color: Volt.warn, edge: Volt.warnEdge),
        if (rows != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: Eyebrow(l.plateThings(rows.length))),
                if (rows.isNotEmpty) Muted(l.tapToConfirm),
              ],
            ),
          ),
          if (rows.isNotEmpty)
            VList(
              children: [
                for (final r in rows)
                  VItem(
                    semantics: r.guess.local,
                    onTap: r.added ? null : () => _open(r),
                    children: [
                      ItemText(
                        r.guess.local,
                        sub: r.food == null
                            ? l.notInDbSearch
                            : [
                                l.aboutGramsKcal(fmtInt(context, r.grams), fmtInt(context, r.kcal)),
                                if (r.food!.source == 'ai') l.aiEstimateShort else if (!r.guess.sure) l.notSureCheck,
                              ].join(' · '),
                      ),
                      if (r.added) VIcon('check', size: 20, color: Volt.accentInk) else const Pick(),
                    ],
                  ),
              ],
            ),
          _card('warn', l.photoAmountNote, color: Volt.warn, edge: Volt.warnEdge),
          if (open.isNotEmpty)
            VBtn(label: l.addAllKcal(open.length, fmtInt(context, total)), expand: true, onTap: () => _addAll(open)),
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

class _Reading extends StatelessWidget {
  const _Reading();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0x990A0B09),
    child: Center(
      child: GapCol(
        gap: 12,
        cross: CrossAxisAlignment.center,
        children: [
          SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Volt.lime)),
          Muted(AppLocalizations.of(context).readingPlate, color: Volt.t1),
        ],
      ),
    ),
  );
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
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onCamera,
            child: CustomPaint(
              foregroundPainter: _Dashed(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
                decoration: smooth(
                  BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(18), border: Volt.edge),
                ),
                child: GapCol(
                  gap: 12,
                  cross: CrossAxisAlignment.center,
                  children: [
                    // The AI reads the photo: its mark, with the camera in it.
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: aiGradient),
                      ),
                      child: const VIcon('camera', size: 24, color: Color(0xFF0B0F14), strokeWidth: 1.8),
                    ),
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
    final path = const SmoothBorder(borderRadius: BorderRadius.all(Radius.circular(18)))
        .getOuterPath((Offset.zero & size).deflate(0.5));
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
