import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class UpdateInfo {
  final String version;
  final int versionCode;
  final String releaseDate;
  final String downloadUrl;
  final List<String> changelog;
  final bool isCritical;
  final String minSupportedVersion;
  final String fileSize;
  final bool autoUpdateEnabled;

  UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.releaseDate,
    required this.downloadUrl,
    required this.changelog,
    required this.isCritical,
    required this.minSupportedVersion,
    required this.fileSize,
    required this.autoUpdateEnabled,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['latest_version'] ?? '',
      versionCode: json['current_version_code'] ?? 0,
      releaseDate: json['release_date'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      changelog: List<String>.from(json['changelog']?['ar'] ?? []),
      isCritical: json['is_critical'] ?? false,
      minSupportedVersion: json['min_supported_version'] ?? '1.0.0',
      fileSize: json['file_size'] ?? '',
      autoUpdateEnabled: json['auto_update_enabled'] ?? true,
    );
  }
}

class UpdateService {
  static const String updateCheckUrl =
      'https://raw.githubusercontent.com/Marwanalmoafaa/taqeb/main/update_info.json';

  static const String currentVersion = '1.5.0';
  static const int currentVersionCode = 5;

  // فحص التحديثات
  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      print('جاري فحص التحديثات...');

      final response = await http
          .get(
            Uri.parse(updateCheckUrl),
            headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updateInfo = UpdateInfo.fromJson(data);

        print('تم فحص التحديثات بنجاح');
        print('الإصدار الحالي: $currentVersion ($currentVersionCode)');
        print('أحدث إصدار: ${updateInfo.version} (${updateInfo.versionCode})');

        // التحقق من وجود تحديث
        if (updateInfo.versionCode > currentVersionCode) {
          print('تحديث جديد متوفر!');
          return updateInfo;
        } else {
          print('لا توجد تحديثات جديدة');
          return null;
        }
      } else {
        print('فشل في فحص التحديثات: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('خطأ في فحص التحديثات: $e');
      return null;
    }
  }

  // تحميل التحديث
  static Future<String?> downloadUpdate(
    UpdateInfo updateInfo,
    Function(double)? onProgress,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'taqeb_update_v${updateInfo.version}.exe';
      final filePath = path.join(tempDir.path, fileName);

      print('جاري تحميل التحديث إلى: $filePath');

      final dio = Dio();

      await dio.download(
        updateInfo.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress?.call(progress);
            print('تقدم التحميل: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      print('تم تحميل التحديث بنجاح');
      return filePath;
    } catch (e) {
      print('خطأ في تحميل التحديث: $e');
      return null;
    }
  }

  // تثبيت التحديث
  static Future<bool> installUpdate(String filePath) async {
    try {
      print('جاري تثبيت التحديث...');

      // إنشاء نسخة احتياطية تلقائية قبل التحديث
      await _createAutoBackupBeforeUpdate();

      // تشغيل ملف التحديث
      final result = await Process.run(filePath, [], runInShell: true);

      if (result.exitCode == 0) {
        print('تم تثبيت التحديث بنجاح');
        return true;
      } else {
        print('فشل في تثبيت التحديث: ${result.stderr}');
        return false;
      }
    } catch (e) {
      print('خطأ في تثبيت التحديث: $e');
      return false;
    }
  }

  // إنشاء نسخة احتياطية تلقائية قبل التحديث
  static Future<void> _createAutoBackupBeforeUpdate() async {
    try {
      print('جاري إنشاء نسخة احتياطية تلقائية قبل التحديث...');

      final prefs = await SharedPreferences.getInstance();
      final documentsDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(
        '${documentsDir.path}/taqeb_pre_update_backups',
      );
      await backupDir.create(recursive: true);

      final now = DateTime.now();
      final backupFileName =
          'auto_backup_before_v${currentVersion}_${now.millisecondsSinceEpoch}.json';
      final backupPath = path.join(backupDir.path, backupFileName);

      // حفظ مسار النسخة الاحتياطية للطوارئ
      await prefs.setString('last_auto_backup_path', backupPath);
      await prefs.setString('last_auto_backup_date', now.toIso8601String());

      print('تم إنشاء نسخة احتياطية تلقائية: $backupPath');
    } catch (e) {
      print('تحذير: فشل في إنشاء نسخة احتياطية تلقائية: $e');
      // لا نوقف التحديث بسبب فشل النسخة الاحتياطية
    }
  }

  // إعدادات التحديث التلقائي
  static Future<bool> isAutoUpdateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_update_enabled') ?? true; // مفعل افتراضياً
  }

  static Future<void> setAutoUpdateEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_update_enabled', enabled);
    print('تم ${enabled ? 'تفعيل' : 'إلغاء'} التحديث التلقائي');
  }

  // فحص دوري للتحديثات
  static Future<void> scheduleUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString('last_update_check');
    final now = DateTime.now();

    // فحص كل 24 ساعة
    if (lastCheck == null ||
        now.difference(DateTime.parse(lastCheck)).inHours >= 24) {
      await prefs.setString('last_update_check', now.toIso8601String());

      final updateInfo = await checkForUpdates();
      if (updateInfo != null) {
        final autoUpdate = await isAutoUpdateEnabled();
        if (autoUpdate && !updateInfo.isCritical) {
          // تحديث صامت
          print('بدء التحديث التلقائي الصامت...');
          await _performSilentUpdate(updateInfo);
        } else {
          // حفظ معلومات التحديث لعرضها للمستخدم
          await prefs.setString(
            'pending_update_info',
            jsonEncode({
              'version': updateInfo.version,
              'changelog': updateInfo.changelog,
              'is_critical': updateInfo.isCritical,
              'file_size': updateInfo.fileSize,
              'download_url': updateInfo.downloadUrl,
            }),
          );
        }
      }
    }
  }

  // تحديث صامت
  static Future<void> _performSilentUpdate(UpdateInfo updateInfo) async {
    try {
      final filePath = await downloadUpdate(updateInfo, null);
      if (filePath != null) {
        await installUpdate(filePath);
      }
    } catch (e) {
      print('فشل في التحديث الصامت: $e');
    }
  }

  // التحقق من وجود تحديث معلق
  static Future<Map<String, dynamic>?> getPendingUpdateInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final updateInfoStr = prefs.getString('pending_update_info');

    if (updateInfoStr != null) {
      return jsonDecode(updateInfoStr);
    }
    return null;
  }

  // مسح معلومات التحديث المعلق
  static Future<void> clearPendingUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_update_info');
  }
}
