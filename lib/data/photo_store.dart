import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

enum Pose { front, side, back }

/// One progress photo: the day it was taken and the pose.
class ProgressPhoto {
  const ProgressPhoto({required this.day, required this.pose, required this.path});
  final String day;
  final Pose pose;
  final String path;
}

/// Progress photos stay on the phone: never uploaded, never in a backup.
abstract class PhotoStore {
  Future<List<ProgressPhoto>> list();
  Future<void> save(String day, Pose pose, Uint8List jpeg);
  Future<void> delete(ProgressPhoto p);
  ImageProvider image(ProgressPhoto p);
}

/// Files named `<day>_<pose>.jpg` in the app's own folder.
class DevicePhotoStore implements PhotoStore {
  Future<Directory>? _dir;
  Future<Directory> get _folder => _dir ??= () async {
    final d = Directory('${(await getApplicationDocumentsDirectory()).path}/progress');
    await d.create(recursive: true);
    return d;
  }();

  @override
  Future<List<ProgressPhoto>> list() async {
    final out = <ProgressPhoto>[];
    await for (final f in (await _folder).list()) {
      final name = f.uri.pathSegments.last;
      final m = RegExp(r'^(\d{4}-\d{2}-\d{2})_(front|side|back)\.jpg$').firstMatch(name);
      if (m != null) out.add(ProgressPhoto(day: m[1]!, pose: Pose.values.byName(m[2]!), path: f.path));
    }
    return out;
  }

  @override
  Future<void> save(String day, Pose pose, Uint8List jpeg) async {
    final f = File('${(await _folder).path}/${day}_${pose.name}.jpg');
    await f.writeAsBytes(jpeg, flush: true);
    // A retake under the same name must not show the old picture.
    await FileImage(f).evict();
  }

  @override
  Future<void> delete(ProgressPhoto p) async {
    final f = File(p.path);
    if (await f.exists()) await f.delete();
    await FileImage(f).evict();
  }

  @override
  ImageProvider image(ProgressPhoto p) => FileImage(File(p.path));
}

/// In memory, for tests.
class MemoryPhotoStore implements PhotoStore {
  final _photos = <String, Uint8List>{};

  @override
  Future<List<ProgressPhoto>> list() async => [
    for (final k in _photos.keys)
      ProgressPhoto(day: k.split('_').first, pose: Pose.values.byName(k.split('_').last), path: k),
  ];

  @override
  Future<void> save(String day, Pose pose, Uint8List jpeg) async => _photos['${day}_${pose.name}'] = jpeg;

  @override
  Future<void> delete(ProgressPhoto p) async => _photos.remove(p.path);

  @override
  ImageProvider image(ProgressPhoto p) => MemoryImage(_photos[p.path] ?? Uint8List(0));
}
