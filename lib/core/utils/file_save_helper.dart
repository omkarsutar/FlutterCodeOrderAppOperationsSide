import 'dart:typed_data';

import 'file_save_helper_stub.dart'
    if (dart.library.html) 'file_save_helper_web.dart';

abstract class FileSaveHelper {
  static Future<void> saveAndDownloadFile({
    required Uint8List bytes,
    required String fileName,
  }) => throw UnimplementedError();
}

class UniversalFileSaver extends FileSaveHelper {
  static Future<void> saveAndDownloadFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    return await saveFile(bytes: bytes, fileName: fileName);
  }
}
