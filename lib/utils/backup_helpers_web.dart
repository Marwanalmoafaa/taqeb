class BackupHelpers {
  static bool get supportsFileSystem => false;

  static Future<void> saveJsonBytes(
    List<int> bytes,
    String suggestedName,
  ) async {
    // On web, use DownloadHelper directly from UI; keep stub for API symmetry
    // Intentionally left blank
  }

  static Future<dynamic> createTempBackupDir() async => null;
  static Future<dynamic> writeString(dynamic _, String __, String ___) async {}
  static Future<dynamic> ensureSubdir(dynamic _, String __) async {}
  static Future<String?> copyIfExists(
    String srcPath,
    dynamic targetDir,
    String newFileName,
  ) async => null;
  static Future<String> zipDirectory(dynamic sourceDir) async => '';
  static Future<void> saveZipToUserLocation(
    String zipPath, {
    String? suggestedName,
  }) async {}

  static Future<Map<String, dynamic>> restoreFromZip(
    String zipFilePath,
  ) async => {};
  static Future<Map<String, String>> copyRestoredAttachments(
    String extractDirPath,
  ) async => {};

  static Future<void> saveBytesWithDialog(
    List<int> bytes, {
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
  }) async {}

  static Future<String> readFileAsString(String filePath) async => '';
}
