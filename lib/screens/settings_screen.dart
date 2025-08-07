import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taqeb/utils/theme_provider.dart';
import 'package:taqeb/widgets/theme_switcher.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/screens/statistics_screen.dart';
import 'package:taqeb/screens/archive_screen.dart';
import 'package:taqeb/services/auth_service.dart';
import 'package:taqeb/screens/login_screen.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/models/company.dart';
import 'package:taqeb/models/account.dart';
import 'package:taqeb/models/transaction.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:taqeb/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoUpdateEnabled = true;
  bool _hasNewUpdate = false;
  Map<String, dynamic>? _pendingUpdateInfo;
  bool _isCheckingUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadUpdateSettings();
    _checkForPendingUpdates();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.primaryDark;
    final subtitleColor = isDark ? Colors.white70 : AppColors.textLight;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: ListView(
        children: [
          Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),

          // مربع بيانات المستخدم وتسجيل الخروج
          Card(
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'معلومات المستخدم',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // معلومات المستخدم
                  FutureBuilder(
                    future: _getUserInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final user = AuthService.currentUser;
                      if (user == null) {
                        return _buildUserInfo(
                          'غير مسجل الدخول',
                          '',
                          Icons.person_off,
                          Colors.grey,
                        );
                      }

                      return Column(
                        children: [
                          _buildUserInfo(
                            user.name.isNotEmpty ? user.name : 'مستخدم',
                            user.email,
                            Icons.person,
                            Colors.blue,
                          ),
                          const SizedBox(height: 16),

                          // زر تسجيل الخروج
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showLogoutDialog(context),
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text(
                                'تسجيل الخروج',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // قسم النسخ الاحتياطي والاستعادة
          Card(
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'النسخ الاحتياطي والاستعادة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'احم بياناتك من الضياع بإنشاء نسخ احتياطية',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                  const SizedBox(height: 20),

                  // زر إنشاء نسخة احتياطية
                  _buildActionButton(
                    context: context,
                    icon: Icons.cloud_upload,
                    title: 'إنشاء نسخة احتياطية شاملة',
                    subtitle:
                        'حفظ جميع البيانات والمرفقات (الشركات، العمال، الحسابات، الملفات)',
                    onTap: () => _createBackup(context),
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),

                  // زر استعادة النسخة الاحتياطية
                  _buildActionButton(
                    context: context,
                    icon: Icons.cloud_download,
                    title: 'استعادة نسخة احتياطية',
                    subtitle:
                        'استيراد البيانات والمرفقات من ملف نسخة احتياطية (ZIP أو JSON)',
                    onTap: () => _restoreBackup(context),
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  // زر تصدير البيانات
                  _buildActionButton(
                    context: context,
                    icon: Icons.file_download,
                    title: 'تصدير إلى Excel',
                    subtitle: 'تصدير جميع البيانات كملف Excel',
                    onTap: () => _exportData(context),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // قسم الأدوات والتقارير
          Card(
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'الأدوات والتقارير',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // زر الإحصائيات
                  _buildActionButton(
                    context: context,
                    icon: Icons.bar_chart,
                    title: 'الإحصائيات',
                    subtitle: 'تقارير ورسوم بيانية شاملة',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      );
                    },
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  // زر الأرشيف
                  _buildActionButton(
                    context: context,
                    icon: Icons.archive,
                    title: 'الأرشيف',
                    subtitle: 'المؤسسات والمعاملات المؤرشفة',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ArchiveScreen(),
                        ),
                      );
                    },
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // قسم التحديثات التلقائية
          Card(
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.system_update, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'التحديثات التلقائية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      if (_hasNewUpdate) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حدّث التطبيق تلقائياً للحصول على أحدث المميزات والإصلاحات',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                  const SizedBox(height: 20),

                  // إعداد التحديث التلقائي
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                      color: AppColors.primary.withOpacity(0.05),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _autoUpdateEnabled
                              ? Icons.auto_awesome
                              : Icons.auto_awesome_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'التحديث التلقائي',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                _autoUpdateEnabled
                                    ? 'سيتم تحديث التطبيق تلقائياً عند توفر إصدار جديد'
                                    : 'سيتطلب موافقتك قبل التحديث',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoUpdateEnabled,
                          onChanged: (value) {
                            setState(() {
                              _autoUpdateEnabled = value;
                            });
                            _saveAutoUpdateSetting(value);
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // زر فحص التحديثات يدوياً
                  _buildActionButton(
                    context: context,
                    icon: _isCheckingUpdates ? Icons.sync : Icons.refresh,
                    title: 'فحص التحديثات',
                    subtitle: _hasNewUpdate
                        ? 'تحديث جديد متوفر!'
                        : 'البحث عن تحديثات جديدة يدوياً',
                    onTap: () => _isCheckingUpdates
                        ? null
                        : _checkForUpdates(manual: true),
                    color: _hasNewUpdate ? Colors.green : Colors.blue,
                  ),

                  // عرض معلومات التحديث المعلق
                  if (_pendingUpdateInfo != null) ...[
                    const SizedBox(height: 16),
                    _buildUpdateInfoWidget(),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.color_lens, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'المظهر',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'تبديل الثيم:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 16),
                      ThemeModeSelector(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'حول التطبيق',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'الإصدار: 1.5.0',
                    style: TextStyle(fontSize: 16, color: subtitleColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تم تصميم البرنامج بواسطة: مروان المعافاء',
                    style: TextStyle(fontSize: 16, color: subtitleColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'للتواصل والدعم الفني: 0531053213',
                    style: TextStyle(fontSize: 16, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'الخصوصية والأمان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '🔒 خصوصية تامة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• جميع البيانات محفوظة محلياً على جهازك فقط',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• لا يتم رفع أي ملفات أو بيانات إلى الإنترنت',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• أمان كامل لمعلومات مؤسستك وعمالك',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• تحكم كامل في بياناتك بدون أي مشاركة خارجية',
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة للحصول على معلومات المستخدم
  Future<void> _getUserInfo() async {
    // مجرد دالة لإثارة إعادة البناء
  }

  // دالة بناء معلومات المستخدم
  Widget _buildUserInfo(String name, String email, IconData icon, Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : AppColors.primaryDark;
    final subtitleColor = isDark ? Colors.white70 : AppColors.textLight;
    final user = AuthService.currentUser;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        color: color.withOpacity(0.05),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // صورة المستخدم أو أيقونة احترافية
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: user != null && user.photoUrl != null
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color, color.withOpacity(0.7)],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child:
                    user != null &&
                        user.photoUrl != null &&
                        user.photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          user.photoUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.transparent,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'م',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: user != null && email.isNotEmpty
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'م',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Icon(
                                Icons.person_off,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
              ),
              const SizedBox(width: 20),

              // معلومات المستخدم
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: subtitleColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (user != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            color: subtitleColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getLoginTimeText(user.loginTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // شارة الحالة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: user != null
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: user != null
                        ? Colors.green.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user != null ? Icons.check_circle : Icons.error_outline,
                      color: user != null ? Colors.green : Colors.grey,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user != null ? 'متصل' : 'غير متصل',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: user != null ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة لتحويل وقت تسجيل الدخول إلى نص مفهوم
  String _getLoginTimeText(DateTime loginTime) {
    final now = DateTime.now();
    final difference = now.difference(loginTime);

    if (difference.inMinutes < 1) {
      return 'منذ لحظات';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 30) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return 'منذ ${(difference.inDays / 30).floor()} شهر';
    }
  }

  // حوار تسجيل الخروج
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.red),
              SizedBox(width: 8),
              Text('تسجيل الخروج'),
            ],
          ),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        );
      },
    );
  }

  // تنفيذ تسجيل الخروج
  Future<void> _performLogout(BuildContext context) async {
    try {
      await AuthService.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دالة بناء زر العمل
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : AppColors.primaryDark;
    final subtitleColor = isDark ? Colors.white70 : AppColors.textLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: subtitleColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // إنشاء نسخة احتياطية شاملة مع المرفقات
  Future<void> _createBackup(BuildContext context) async {
    try {
      // عرض حوار التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('جاري إنشاء النسخة الاحتياطية الشاملة...'),
              ],
            ),
          );
        },
      );

      // إنشاء مجلد مؤقت للنسخة الاحتياطية
      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory(
        '${tempDir.path}/taqeb_backup_${DateTime.now().millisecondsSinceEpoch}',
      );
      await backupDir.create(recursive: true);

      try {
        // 1. جمع البيانات
        final backupData = await _gatherAllData();
        print('تم جمع البيانات بنجاح');

        // 2. حفظ ملف البيانات JSON
        final dataFile = File('${backupDir.path}/data.json');
        await dataFile.writeAsString(jsonEncode(backupData));
        print('تم حفظ البيانات في data.json');

        // 3. إنشاء مجلد للمرفقات
        final attachmentsDir = Directory('${backupDir.path}/attachments');
        await attachmentsDir.create();

        // 4. نسخ جميع الملفات المرفقة
        final attachmentPaths = await _collectAndCopyAttachments(
          attachmentsDir,
        );
        print('تم نسخ ${attachmentPaths.length} مرفق');

        // 5. إنشاء ملف فهرس المرفقات
        final indexFile = File('${backupDir.path}/attachments_index.json');
        await indexFile.writeAsString(jsonEncode(attachmentPaths));
        print('تم إنشاء فهرس المرفقات');

        // 6. ضغط كل شيء إلى ملف ZIP
        final zipPath = await _createZipFile(backupDir);
        print('تم إنشاء ملف ZIP: $zipPath');

        // إغلاق حوار التحميل
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // اختيار مكان الحفظ
        final now = DateTime.now();
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ النسخة الاحتياطية الشاملة',
          fileName:
              'taqeb_full_backup_${now.toIso8601String().split('T')[0]}.zip',
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );

        if (outputFile != null) {
          // نسخ الملف المضغوط إلى المكان المختار
          final zipFile = File(zipPath);
          await zipFile.copy(outputFile);
          print('تم حفظ الملف في: $outputFile');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ تم إنشاء النسخة الاحتياطية الشاملة بنجاح!\n📁 تحتوي على البيانات والمرفقات',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } else {
          print('لم يتم اختيار مكان للحفظ');
        }

        // تنظيف المجلد المؤقت
        await backupDir.delete(recursive: true);
      } catch (e) {
        // تنظيف المجلد المؤقت في حالة الخطأ
        if (await backupDir.exists()) {
          await backupDir.delete(recursive: true);
        }
        rethrow;
      }
    } catch (e, stackTrace) {
      print('خطأ في إنشاء النسخة الاحتياطية: $e');
      print('Stack trace: $stackTrace');

      // إغلاق حوار التحميل في حالة الخطأ
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إنشاء النسخة الاحتياطية:\n${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  // جمع ونسخ جميع الملفات المرفقة
  Future<Map<String, String>> _collectAndCopyAttachments(
    Directory attachmentsDir,
  ) async {
    final Map<String, String> attachmentPaths = {};
    final companies = DatabaseService.getAllCompanies(includeArchived: true);
    int fileCounter = 1;

    for (final company in companies) {
      // معالجة مرفقات الشركة
      if (company.companyAttachments.isNotEmpty) {
        for (final attachment in company.companyAttachments) {
          if (attachment['path'] != null) {
            final originalFile = File(attachment['path']);
            if (await originalFile.exists()) {
              final extension = path.extension(attachment['path']);
              final newFileName =
                  'company_${company.name}_${fileCounter}$extension';
              final newFile = File('${attachmentsDir.path}/$newFileName');

              try {
                await originalFile.copy(newFile.path);
                attachmentPaths[attachment['path']] = newFileName;
                fileCounter++;
              } catch (e) {
                print('خطأ في نسخ ملف: ${attachment['path']} - $e');
              }
            }
          }
        }
      }

      // معالجة مرفقات العمال
      if (company.workers.isNotEmpty) {
        for (
          int workerIndex = 0;
          workerIndex < company.workers.length;
          workerIndex++
        ) {
          final worker = company.workers[workerIndex];
          if (worker['attachments'] != null && worker['attachments'] is List) {
            final attachments = worker['attachments'] as List;
            for (final attachment in attachments) {
              if (attachment['path'] != null) {
                final originalFile = File(attachment['path']);
                if (await originalFile.exists()) {
                  final extension = path.extension(attachment['path']);
                  final workerName = worker['name'] ?? 'worker_$workerIndex';
                  final newFileName =
                      'worker_${company.name}_${workerName}_${fileCounter}$extension';
                  final newFile = File('${attachmentsDir.path}/$newFileName');

                  try {
                    await originalFile.copy(newFile.path);
                    attachmentPaths[attachment['path']] = newFileName;
                    fileCounter++;
                  } catch (e) {
                    print('خطأ في نسخ ملف عامل: ${attachment['path']} - $e');
                  }
                }
              }
            }
          }
        }
      }
    }

    return attachmentPaths;
  }

  // إنشاء ملف ZIP مضغوط
  Future<String> _createZipFile(Directory sourceDir) async {
    final archive = Archive();

    // إضافة جميع الملفات إلى الأرشيف
    await _addDirectoryToArchive(archive, sourceDir, '');

    // ترميز الأرشيف إلى ZIP
    final zipData = ZipEncoder().encode(archive);

    // حفظ الملف المضغوط
    final zipFile = File('${sourceDir.path}.zip');
    await zipFile.writeAsBytes(zipData!);

    return zipFile.path;
  }

  // إضافة مجلد إلى الأرشيف بشكل تكراري
  Future<void> _addDirectoryToArchive(
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
        final file = ArchiveFile(relativePath, bytes.length, bytes);
        archive.addFile(file);
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, relativePath);
      }
    }
  }

  // استعادة نسخة احتياطية شاملة
  Future<void> _restoreBackup(BuildContext context) async {
    try {
      // اختيار ملف النسخة الاحتياطية
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'], // دعم كل من ZIP والـ JSON القديم
        dialogTitle: 'اختيار ملف النسخة الاحتياطية',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final isZipFile = filePath.toLowerCase().endsWith('.zip');

        // عرض تحذير
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('تحذير مهم'),
                ],
              ),
              content: Text(
                'ستتم إزالة جميع البيانات الحالية واستبدالها بالبيانات من النسخة الاحتياطية.'
                '${isZipFile ? '\n\nسيتم أيضاً استعادة جميع الملفات المرفقة.' : ''}\n\nهل أنت متأكد؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('موافق'),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          // عرض حوار التحميل
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text(
                      isZipFile
                          ? 'جاري استعادة البيانات والمرفقات...'
                          : 'جاري استعادة البيانات...',
                    ),
                  ],
                ),
              );
            },
          );

          if (isZipFile) {
            await _restoreFromZipBackup(filePath);
          } else {
            await _restoreFromJsonBackup(filePath);
          }

          // إغلاق حوار التحميل
          Navigator.of(context).pop();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isZipFile
                      ? '✅ تم استعادة البيانات والمرفقات بنجاح!'
                      : '✅ تم استعادة البيانات بنجاح!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      // إغلاق حوار التحميل في حالة الخطأ
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في استعادة البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  // استعادة من ملف ZIP
  Future<void> _restoreFromZipBackup(String zipFilePath) async {
    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(
      '${tempDir.path}/restore_${DateTime.now().millisecondsSinceEpoch}',
    );
    await extractDir.create(recursive: true);

    try {
      // قراءة ملف ZIP
      final zipFile = File(zipFilePath);
      final bytes = await zipFile.readAsBytes();

      // استخراج الملفات
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final fileName = file.name;
        final extractedFile = File('${extractDir.path}/$fileName');

        if (file.isFile) {
          await extractedFile.create(recursive: true);
          await extractedFile.writeAsBytes(file.content as List<int>);
        }
      }

      // قراءة ملف البيانات
      final dataFile = File('${extractDir.path}/data.json');
      if (await dataFile.exists()) {
        final jsonString = await dataFile.readAsString();
        final backupData = jsonDecode(jsonString);

        // استعادة البيانات
        await _restoreAllData(backupData);

        // استعادة المرفقات
        final indexFile = File('${extractDir.path}/attachments_index.json');
        if (await indexFile.exists()) {
          await _restoreAttachments(extractDir, indexFile);
        }
      } else {
        throw Exception('ملف البيانات غير موجود في النسخة الاحتياطية');
      }
    } finally {
      // تنظيف المجلد المؤقت
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }

  // استعادة من ملف JSON (النظام القديم)
  Future<void> _restoreFromJsonBackup(String jsonFilePath) async {
    final file = File(jsonFilePath);
    final jsonString = await file.readAsString();
    final backupData = jsonDecode(jsonString);
    await _restoreAllData(backupData);
  }

  // استعادة المرفقات
  Future<void> _restoreAttachments(Directory extractDir, File indexFile) async {
    try {
      final indexContent = await indexFile.readAsString();
      final attachmentPaths = Map<String, String>.from(
        jsonDecode(indexContent),
      );

      final attachmentsDir = Directory('${extractDir.path}/attachments');
      if (!await attachmentsDir.exists()) return;

      // إنشاء مجلد للمرفقات المستعادة
      final documentsDir = await getApplicationDocumentsDirectory();
      final restoredAttachmentsDir = Directory(
        '${documentsDir.path}/taqeb_attachments',
      );
      await restoredAttachmentsDir.create(recursive: true);

      // استعادة كل ملف وتحديث المسارات في قاعدة البيانات
      final companies = DatabaseService.getAllCompanies(includeArchived: true);

      for (final company in companies) {
        // تحديث مرفقات الشركة
        for (final attachment in company.companyAttachments) {
          final originalPath = attachment['path'];
          if (originalPath != null &&
              attachmentPaths.containsKey(originalPath)) {
            final backupFileName = attachmentPaths[originalPath]!;
            final backupFile = File('${attachmentsDir.path}/$backupFileName');

            if (await backupFile.exists()) {
              final newFileName =
                  '${DateTime.now().millisecondsSinceEpoch}_$backupFileName';
              final newFile = File(
                '${restoredAttachmentsDir.path}/$newFileName',
              );
              await backupFile.copy(newFile.path);
              attachment['path'] = newFile.path;
            }
          }
        }

        // تحديث مرفقات العمال
        for (final worker in company.workers) {
          if (worker['attachments'] != null && worker['attachments'] is List) {
            final attachments = worker['attachments'] as List;
            for (final attachment in attachments) {
              final originalPath = attachment['path'];
              if (originalPath != null &&
                  attachmentPaths.containsKey(originalPath)) {
                final backupFileName = attachmentPaths[originalPath]!;
                final backupFile = File(
                  '${attachmentsDir.path}/$backupFileName',
                );

                if (await backupFile.exists()) {
                  final newFileName =
                      '${DateTime.now().millisecondsSinceEpoch}_$backupFileName';
                  final newFile = File(
                    '${restoredAttachmentsDir.path}/$newFileName',
                  );
                  await backupFile.copy(newFile.path);
                  attachment['path'] = newFile.path;
                }
              }
            }
          }
        }

        // حفظ التغييرات في قاعدة البيانات
        await company.save();
      }
    } catch (e) {
      print('خطأ في استعادة المرفقات: $e');
      // لا نرمي الخطأ هنا حتى لا توقف عملية استعادة البيانات
    }
  }

  // تصدير البيانات
  Future<void> _exportData(BuildContext context) async {
    try {
      // حفظ البيانات مباشرة بصيغة CSV للاستخدام في Excel
      // عرض حوار التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('جاري تصدير البيانات إلى Excel...'),
              ],
            ),
          );
        },
      );

      // جمع البيانات
      final allData = await _gatherAllData();
      final csvContent = _convertToCSV(allData);

      // إغلاق حوار التحميل
      Navigator.of(context).pop();

      // حفظ الملف
      final now = DateTime.now();
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'تصدير البيانات إلى Excel',
        fileName: 'taqeb_data_${now.toIso8601String().split('T')[0]}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        // إضافة BOM للعربية في Excel
        await file.writeAsString(
          '\uFEFF$csvContent',
          encoding: Encoding.getByName('utf-8')!,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم تصدير البيانات إلى Excel بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // إغلاق حوار التحميل في حالة الخطأ
      Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في تصدير البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // جمع جميع البيانات من قاعدة البيانات
  // دالة لتحويل أي DateTime موجود في البيانات إلى string
  dynamic _convertDateTimeToString(dynamic data) {
    if (data is DateTime) {
      return data.toIso8601String();
    } else if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key, _convertDateTimeToString(value)),
      );
    } else if (data is List) {
      return data.map((item) => _convertDateTimeToString(item)).toList();
    } else {
      return data;
    }
  }

  Future<Map<String, dynamic>> _gatherAllData() async {
    try {
      final companies = DatabaseService.getAllCompanies(includeArchived: true);
      final accounts = DatabaseService.getAllAccounts();
      final transactions = DatabaseService.getAllTransactions();

      final now = DateTime.now();

      return {
        'version': '1.0',
        'exported_at': now.toIso8601String(),
        'data': {
          'companies_count': companies.length,
          'accounts_count': accounts.length,
          'transactions_count': transactions.length,
          'companies': companies
              .map(
                (company) => {
                  'name': company.name,
                  'ownerId': company.ownerId,
                  'ownerPhone': company.ownerPhone,
                  'ownerExtra': _convertDateTimeToString(company.ownerExtra),
                  'companyData': _convertDateTimeToString(company.companyData),
                  'workers': _convertDateTimeToString(company.workers),
                  'isArchived': company.isArchived,
                  'companyAttachments': _convertDateTimeToString(
                    company.companyAttachments,
                  ),
                },
              )
              .toList(),
          'accounts': accounts
              .map(
                (account) => {
                  'name': account.name,
                  'totalDue': account.totalDue,
                  'totalPaid': account.totalPaid,
                  'remaining': account.remaining,
                  'dueDate': account.dueDate.toIso8601String(),
                  'items': _convertDateTimeToString(account.items),
                  'lastModified': account.lastModified.toIso8601String(),
                  'documents': account.documents
                      .map(
                        (doc) => {
                          'name': doc.name,
                          'number': doc.number,
                          'expiryDate': doc.expiryDate.toIso8601String(),
                          'createdAt': doc.createdAt.toIso8601String(),
                        },
                      )
                      .toList(),
                },
              )
              .toList(),
          'transactions': transactions
              .map(
                (transaction) => {
                  'content': transaction.content,
                  'isDone': transaction.isDone,
                  'createdAt': transaction.createdAt.toIso8601String(),
                },
              )
              .toList(),
          'summary': {
            'total_companies': companies.length,
            'total_accounts': accounts.length,
            'total_transactions': transactions.length,
          },
        },
      };
    } catch (e) {
      print('خطأ في جمع البيانات: $e');
      rethrow;
    }
  }

  // استعادة جميع البيانات
  Future<void> _restoreAllData(Map<String, dynamic> backupData) async {
    try {
      // التحقق من صحة البيانات
      if (backupData['data'] == null) {
        throw Exception('ملف النسخة الاحتياطية غير صحيح');
      }

      final data = backupData['data'];

      // إظهار معلومات الاستعادة
      final companiesCount = data['companies_count'] ?? 0;
      final accountsCount = data['accounts_count'] ?? 0;
      final transactionsCount = data['transactions_count'] ?? 0;

      // محو البيانات الحالية
      await DatabaseService.clearAllData();

      // استعادة الشركات
      if (data['companies'] != null) {
        for (var companyData in data['companies']) {
          final company = Company.fromMap(companyData);
          await DatabaseService.addCompany(company);
        }
      }

      // استعادة الحسابات
      if (data['accounts'] != null) {
        for (var accountData in data['accounts']) {
          final account = AccountModel.fromMap(accountData);
          await DatabaseService.addAccount(account);
        }
      }

      // استعادة المعاملات
      if (data['transactions'] != null) {
        for (var transactionData in data['transactions']) {
          final transaction = TransactionModel.fromMap(transactionData);
          await DatabaseService.addTransaction(transaction);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ تم استعادة جميع البيانات بنجاح!\n'
              '🏢 $companiesCount شركة\n'
              '👥 $accountsCount حساب\n'
              '💰 $transactionsCount معاملة\n\n'
              '🎉 جميع البيانات جاهزة للاستخدام',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في استعادة البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // تحويل البيانات إلى CSV
  String _convertToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // إضافة معلومات التصدير
    buffer.writeln('تقرير تعقيب');

    // التعامل الآمن مع التاريخ
    final exportedAt = data['exported_at'];
    String dateStr = 'غير محدد';
    if (exportedAt is String) {
      try {
        final date = DateTime.parse(exportedAt);
        dateStr = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        dateStr = exportedAt;
      }
    }

    buffer.writeln('تاريخ التصدير: $dateStr');
    buffer.writeln('الإصدار: ${data['version']}');
    buffer.writeln();

    // إضافة بيانات الشركات
    if (data['data']['companies'] != null &&
        data['data']['companies'].isNotEmpty) {
      buffer.writeln('=== الشركات ===');
      buffer.writeln(
        'اسم الشركة,رقم المالك,هاتف المالك,حالة الأرشيف,عدد العمال',
      );
      for (var company in data['data']['companies']) {
        final workersCount = (company['workers'] as List?)?.length ?? 0;
        buffer.writeln(
          '${company['name']},${company['ownerId']},${company['ownerPhone']},${company['isArchived'] ? 'مؤرشف' : 'نشط'},$workersCount',
        );
      }
      buffer.writeln();
    }

    // إضافة بيانات الحسابات
    if (data['data']['accounts'] != null &&
        data['data']['accounts'].isNotEmpty) {
      buffer.writeln('=== الحسابات ===');
      buffer.writeln(
        'اسم الحساب,إجمالي المستحقات,إجمالي المدفوع,المتبقي,تاريخ الاستحقاق,عدد الوثائق',
      );
      for (var account in data['data']['accounts']) {
        final documentsCount = (account['documents'] as List?)?.length ?? 0;
        buffer.writeln(
          '${account['name']},${account['totalDue']},${account['totalPaid']},${account['remaining']},${account['dueDate']?.split('T')[0] ?? ''},${documentsCount}',
        );
      }
      buffer.writeln();
    }

    // إضافة بيانات المعاملات
    if (data['data']['transactions'] != null &&
        data['data']['transactions'].isNotEmpty) {
      buffer.writeln('=== المعاملات ===');
      buffer.writeln('المحتوى,حالة الإنجاز,تاريخ الإنشاء');
      for (var transaction in data['data']['transactions']) {
        buffer.writeln(
          '${transaction['content']},${transaction['isDone'] ? 'مكتمل' : 'قيد الانتظار'},${transaction['createdAt']?.split('T')[0] ?? ''}',
        );
      }
      buffer.writeln();
    }

    // إضافة الملخص
    buffer.writeln('=== الملخص ===');
    buffer.writeln('إجمالي الشركات,${data['data']['companies_count']}');
    buffer.writeln('إجمالي الحسابات,${data['data']['accounts_count']}');
    buffer.writeln('إجمالي المعاملات,${data['data']['transactions_count']}');

    return buffer.toString();
  }

  // دوال إدارة التحديثات
  Future<void> _loadUpdateSettings() async {
    try {
      final autoUpdate = await UpdateService.isAutoUpdateEnabled();
      setState(() {
        _autoUpdateEnabled = autoUpdate;
      });
    } catch (e) {
      print('خطأ في تحميل إعدادات التحديث: $e');
    }
  }

  Future<void> _checkForPendingUpdates() async {
    try {
      final pendingUpdate = await UpdateService.getPendingUpdateInfo();
      if (pendingUpdate != null) {
        setState(() {
          _hasNewUpdate = true;
          _pendingUpdateInfo = pendingUpdate;
        });
      }
    } catch (e) {
      print('خطأ في فحص التحديثات المعلقة: $e');
    }
  }

  Future<void> _saveAutoUpdateSetting(bool enabled) async {
    try {
      await UpdateService.setAutoUpdateEnabled(enabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? '✅ تم تفعيل التحديث التلقائي'
                  : '⚠️ تم إيقاف التحديث التلقائي',
            ),
            backgroundColor: enabled ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('خطأ في حفظ إعدادات التحديث: $e');
    }
  }

  Future<void> _checkForUpdates({bool manual = false}) async {
    if (_isCheckingUpdates) return;

    setState(() {
      _isCheckingUpdates = true;
    });

    try {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 جاري البحث عن تحديثات...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      final updateInfo = await UpdateService.checkForUpdates();

      setState(() {
        _isCheckingUpdates = false;
      });

      if (updateInfo != null) {
        setState(() {
          _hasNewUpdate = true;
          _pendingUpdateInfo = {
            'version': updateInfo.version,
            'changelog': updateInfo.changelog,
            'is_critical': updateInfo.isCritical,
            'file_size': updateInfo.fileSize,
            'download_url': updateInfo.downloadUrl,
          };
        });

        if (mounted) {
          if (_autoUpdateEnabled && !updateInfo.isCritical) {
            // بدء التحديث التلقائي
            _showAutoUpdateDialog(updateInfo);
          } else {
            // عرض معلومات التحديث للمستخدم
            _showUpdateAvailableDialog(updateInfo);
          }
        }
      } else {
        if (manual && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ لا توجد تحديثات جديدة. أنت تستخدم أحدث إصدار!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCheckingUpdates = false;
      });

      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في فحص التحديثات: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showAutoUpdateDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.green),
              SizedBox(width: 8),
              Text('تحديث تلقائي'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('سيبدأ التحديث التلقائي إلى الإصدار ${updateInfo.version}'),
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('جاري التحضير...', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _autoUpdateEnabled = false;
                });
                _saveAutoUpdateSetting(false);
              },
              child: const Text('إلغاء التحديث التلقائي'),
            ),
          ],
        );
      },
    );

    // بدء التحديث بعد ثانيتين
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _performUpdate(updateInfo);
      }
    });
  }

  void _showUpdateAvailableDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                updateInfo.isCritical
                    ? Icons.priority_high
                    : Icons.new_releases,
                color: updateInfo.isCritical ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(updateInfo.isCritical ? 'تحديث مهم!' : 'تحديث جديد متوفر!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الإصدار الجديد: ${updateInfo.version}'),
              Text('حجم الملف: ${updateInfo.fileSize}'),
              const SizedBox(height: 16),
              Text(
                'ما الجديد:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ...updateInfo.changelog.map(
                (change) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(change)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (!updateInfo.isCritical)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('لاحقاً'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performUpdate(updateInfo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: updateInfo.isCritical
                    ? Colors.red
                    : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('تحديث الآن'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performUpdate(UpdateInfo updateInfo) async {
    double downloadProgress = 0.0;
    bool isDownloading = true;

    // عرض حوار التقدم
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Row(
                children: [
                  Icon(Icons.download, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('جاري التحديث'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDownloading) ...[
                    const Text('جاري تحميل التحديث...'),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: downloadProgress),
                    const SizedBox(height: 8),
                    Text('${(downloadProgress * 100).toInt()}%'),
                  ] else ...[
                    const Text('جاري تثبيت التحديث...'),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    try {
      // تحميل التحديث
      final filePath = await UpdateService.downloadUpdate(updateInfo, (
        progress,
      ) {
        if (mounted) {
          // تحديث حوار التقدم
          // Note: في الواقع نحتاج StatefulBuilder لتحديث الحوار
          downloadProgress = progress;
        }
      });

      if (filePath != null) {
        isDownloading = false;

        // تثبيت التحديث
        final success = await UpdateService.installUpdate(filePath);

        if (mounted) {
          Navigator.of(context).pop(); // إغلاق حوار التقدم

          if (success) {
            // مسح معلومات التحديث المعلق
            await UpdateService.clearPendingUpdate();
            setState(() {
              _hasNewUpdate = false;
              _pendingUpdateInfo = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '✅ تم تثبيت التحديث بنجاح! سيتم إعادة تشغيل التطبيق...',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ فشل في تثبيت التحديث. حاول مرة أخرى لاحقاً.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ فشل في تحميل التحديث. تحقق من الاتصال بالإنترنت.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في التحديث: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildUpdateInfoWidget() {
    if (_pendingUpdateInfo == null) return const SizedBox();

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : AppColors.primaryDark;
    final subtitleColor = isDark ? Colors.white70 : AppColors.textLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
        color: Colors.green.withOpacity(0.1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.new_releases, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'تحديث جديد: ${_pendingUpdateInfo!['version']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                _pendingUpdateInfo!['file_size'] ?? '',
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // عرض بعض الميزات الجديدة
          if (_pendingUpdateInfo!['changelog'] != null) ...[
            Text(
              'ما الجديد:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            ...((_pendingUpdateInfo!['changelog'] as List)
                .take(2)
                .map(
                  (change) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $change',
                      style: TextStyle(fontSize: 13, color: subtitleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )),
            if ((_pendingUpdateInfo!['changelog'] as List).length > 2)
              Text(
                '... والمزيد',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final updateInfo = UpdateInfo(
                      version: _pendingUpdateInfo!['version'],
                      versionCode: 0,
                      releaseDate: '',
                      downloadUrl: _pendingUpdateInfo!['download_url'] ?? '',
                      changelog: List<String>.from(
                        _pendingUpdateInfo!['changelog'] ?? [],
                      ),
                      isCritical: _pendingUpdateInfo!['is_critical'] ?? false,
                      minSupportedVersion: '',
                      fileSize: _pendingUpdateInfo!['file_size'] ?? '',
                      autoUpdateEnabled: true,
                    );
                    _showUpdateAvailableDialog(updateInfo);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'عرض التحديث',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  await UpdateService.clearPendingUpdate();
                  setState(() {
                    _hasNewUpdate = false;
                    _pendingUpdateInfo = null;
                  });
                },
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'إخفاء',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
