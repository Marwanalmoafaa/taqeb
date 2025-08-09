import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DownloadHelper {
  // Save bytes to a chosen path (desktop flow handles picker elsewhere).
  static Future<String> saveBytes(
    List<int> bytes,
    String suggestedFileName,
  ) async {
    final dir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, suggestedFileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return filePath;
  }
}
