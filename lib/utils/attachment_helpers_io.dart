import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class AttachmentHelpers {
  static bool get supportsFileSystem => !kIsWeb;

  static Future<bool> fileExists(String path) async {
    if (kIsWeb) return false;
    return File(path).exists();
  }

  static File imageFile(String path) => File(path);

  static Future<void> ensureDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  static Future<void> copyFileTo(String srcPath, String destPath) async {
    final src = File(srcPath);
    await src.copy(destPath);
  }

  static Future<void> revealInExplorer(String filePath) async {
    if (kIsWeb) return;
    try {
      await Process.run('explorer', ['/select,', filePath]);
    } catch (_) {}
  }

  static Future<void> openForPrint(String filePath) async {
    if (kIsWeb) return;
    try {
      await Process.run('rundll32', ['url.dll,FileProtocolHandler', filePath]);
    } catch (_) {}
  }
}
