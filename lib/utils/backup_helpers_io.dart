import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class BackupHelpers {
  static bool get supportsFileSystem => !kIsWeb;

  // Write JSON bytes to file using save dialog
  static Future<void> saveJsonBytes(
    List<int> bytes,
    String suggestedName,
  ) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ النسخة الاحتياطية (JSON)',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (outputFile == null) return;
    final file = File(outputFile);
    await file.writeAsBytes(bytes);
  }

  static Future<void> saveBytesWithDialog(
    List<int> bytes, {
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
  }) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (outputFile == null) return;
    final file = File(outputFile);
    await file.writeAsBytes(bytes);
  }

  static Future<String> readFileAsString(String filePath) async {
    final file = File(filePath);
    return file.readAsString();
  }

  // Create a temp directory for full backup
  static Future<Directory> createTempBackupDir() async {
    final tempDir = await getTemporaryDirectory();
    final backupDir = Directory(
      path.join(
        tempDir.path,
        'taqeb_backup_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await backupDir.create(recursive: true);
    return backupDir;
  }

  // Write string to file inside a directory
  static Future<File> writeString(
    Directory dir,
    String name,
    String content,
  ) async {
    final file = File(path.join(dir.path, name));
    await file.writeAsString(content);
    return file;
  }

  static Future<Directory> ensureSubdir(Directory dir, String name) async {
    final d = Directory(path.join(dir.path, name));
    await d.create(recursive: true);
    return d;
  }

  // Copy a file if exists. Returns new name mapping entry.
  static Future<String?> copyIfExists(
    String srcPath,
    Directory targetDir,
    String newFileName,
  ) async {
    final src = File(srcPath);
    if (await src.exists()) {
      final dest = File(path.join(targetDir.path, newFileName));
      await src.copy(dest.path);
      return dest.path;
    }
    return null;
  }

  // Zip a directory, return zip path
  static Future<String> zipDirectory(Directory sourceDir) async {
    final archive = Archive();
    await _addDirectoryToArchive(archive, sourceDir, '');
    final zipData = ZipEncoder().encode(archive)!;
    final zipFile = File('${sourceDir.path}.zip');
    await zipFile.writeAsBytes(zipData);
    return zipFile.path;
  }

  static Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath,
  ) async {
    final entities = await dir.list().toList();
    for (final entity in entities) {
      final relativePath = basePath.isEmpty
          ? path.basename(entity.path)
          : '$basePath/${path.basename(entity.path)}';
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, relativePath);
      }
    }
  }

  // Save zip to user chosen location
  static Future<void> saveZipToUserLocation(
    String zipPath, {
    String? suggestedName,
  }) async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ النسخة الاحتياطية الشاملة',
      fileName: suggestedName ?? path.basename(zipPath),
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (outputFile == null) return;
    final src = File(zipPath);
    await src.copy(outputFile);
  }

  // Restore from zip
  static Future<Map<String, dynamic>> restoreFromZip(String zipFilePath) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(
      path.join(
        tempDir.path,
        'restore_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await extractDir.create(recursive: true);

    try {
      final zipFile = File(zipFilePath);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final extractedFile = File(path.join(extractDir.path, file.name));
        if (file.isFile) {
          await extractedFile.create(recursive: true);
          await extractedFile.writeAsBytes(file.content as List<int>);
        }
      }
      final dataFile = File(path.join(extractDir.path, 'data.json'));
      if (!await dataFile.exists()) throw Exception('data.json غير موجود');
      final jsonString = await dataFile.readAsString();
      return {'extractDir': extractDir.path, 'data': jsonDecode(jsonString)};
    } catch (e) {
      rethrow;
    } finally {
      // caller may clean up extractDir after attachments processed
    }
  }

  static Future<Map<String, String>> copyRestoredAttachments(
    String extractDirPath,
  ) async {
    final attachmentsIndex = File(
      path.join(extractDirPath, 'attachments_index.json'),
    );
    if (!await attachmentsIndex.exists()) return {};
    final indexContent = await attachmentsIndex.readAsString();
    final mapping = Map<String, String>.from(jsonDecode(indexContent));

    final attachmentsDir = Directory(path.join(extractDirPath, 'attachments'));
    if (!await attachmentsDir.exists()) return {};

    final documentsDir = await getApplicationDocumentsDirectory();
    final restoredAttachmentsDir = Directory(
      path.join(documentsDir.path, 'taqeb_attachments'),
    );
    await restoredAttachmentsDir.create(recursive: true);

    final Map<String, String> newPaths = {};

    for (final entry in mapping.entries) {
      final backupName = entry.value;
      final backupFile = File(path.join(attachmentsDir.path, backupName));
      if (await backupFile.exists()) {
        final newFileName =
            '${DateTime.now().millisecondsSinceEpoch}_$backupName';
        final newFile = File(
          path.join(restoredAttachmentsDir.path, newFileName),
        );
        await backupFile.copy(newFile.path);
        newPaths[entry.key] = newFile.path;
      }
    }
    return newPaths;
  }
}
