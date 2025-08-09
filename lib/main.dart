import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/services/auth_service.dart';
import 'package:taqeb/screens/dashboard_page.dart';
import 'package:taqeb/screens/login_screen.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/utils/theme.dart';
import 'package:taqeb/utils/theme_provider.dart';

// نقطة البداية للتطبيق
void main() async {
  // تأكد من تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة خدمة المصادقة أولاً
  await AuthService.initialize();

  // تهيئة قاعدة البيانات (بدون مستخدم في البداية)
  await DatabaseService.initialize();

  // تشغيل التطبيق
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// المفتاح العام للتنقل
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// الصنف الرئيسي للتطبيق
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // تكوين الوضع الكامل للشاشة
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: themeProvider.isDarkMode
            ? AppColors.darkBackground
            : Colors.white,
        statusBarIconBrightness: themeProvider.isDarkMode
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarIconBrightness: themeProvider.isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return MaterialApp(
      // عنوان التطبيق
      title: 'تميز إداري',

      // تطبيق السمات (Themes)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      // إخفاء شعار التصحيح
      debugShowCheckedModeBanner: false,

      // الصفحة الرئيسية
      home: const AppShell(),

      // مفتاح التنقل العام
      navigatorKey: navigatorKey,

      // إعدادات اللغة العربية
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

/// كلاس للتحكم في شاشة البداية والمصادقة
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // التحقق من وجود جلسة مستخدم محفوظة
      final user = await AuthService.restoreSession();
      final isLoggedIn = user != null && !AuthService.isSessionExpired();

      if (isLoggedIn) {
        // تبديل قاعدة البيانات للمستخدم المستعاد
        await DatabaseService.switchUser(user.id);
      }

      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // شاشة تحميل
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4A90E2), Color(0xFF7B68EE)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_center, size: 80, color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'تميز إداري',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }

    // توجيه المستخدم حسب حالة تسجيل الدخول
    return _isLoggedIn ? const DashboardPage() : const LoginScreen();
  }
}
