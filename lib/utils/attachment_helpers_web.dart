class AttachmentHelpers {
  static bool get supportsFileSystem => false;

  static Future<bool> fileExists(String path) async => false;

  static dynamic imageFile(String path) {
    // Not used on web (guarded). Returning null to avoid usage.
    return null;
  }

  static Future<void> ensureDir(String path) async {}

  static Future<void> copyFileTo(String srcPath, String destPath) async {}

  static Future<void> revealInExplorer(String filePath) async {}

  static Future<void> openForPrint(String filePath) async {}
}
