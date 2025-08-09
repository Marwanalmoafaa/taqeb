import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      final response = await http
          .get(
            Uri.parse(updateCheckUrl),
            headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updateInfo = UpdateInfo.fromJson(data);
        if (updateInfo.versionCode > currentVersionCode) {
          return updateInfo;
        }
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> downloadUpdate(
    UpdateInfo updateInfo,
    Function(double)? onProgress,
  ) async {
    return null; // Not supported on web
  }

  static Future<bool> installUpdate(String filePath) async {
    return false; // Not supported on web
  }

  static Future<bool> isAutoUpdateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_update_enabled') ?? true;
  }

  static Future<void> setAutoUpdateEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_update_enabled', enabled);
  }

  static Future<void> scheduleUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString('last_update_check');
    final now = DateTime.now();
    if (lastCheck == null ||
        now.difference(DateTime.parse(lastCheck)).inHours >= 24) {
      await prefs.setString('last_update_check', now.toIso8601String());
      final updateInfo = await checkForUpdates();
      if (updateInfo != null) {
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

  static Future<Map<String, dynamic>?> getPendingUpdateInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final updateInfoStr = prefs.getString('pending_update_info');
    if (updateInfoStr != null) {
      return jsonDecode(updateInfoStr);
    }
    return null;
  }

  static Future<void> clearPendingUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_update_info');
  }
}
