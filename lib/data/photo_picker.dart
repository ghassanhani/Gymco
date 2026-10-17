import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// The camera or the photo library, as a JPEG small enough to send.
abstract class PhotoPicker {
  Future<Uint8List?> pick({required bool camera});
}

class DevicePhotoPicker implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<Uint8List?> pick({required bool camera}) async {
    // A quality setting makes both platforms hand back a JPEG.
    final f = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );
    return f?.readAsBytes();
  }
}
