import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taqeb/models/user.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static GoogleSignIn? _googleSignIn;
  static User? _currentUser;
  static const String _userKey = 'current_user';
  static const String _rememberMeKey = 'remember_me';
  static HttpServer? _redirectServer;

  // تهيئة خدمة Google Sign In
  static Future<void> initialize() async {
    try {
      // قراءة ملف Google Client Secret
      final String response = await rootBundle.loadString(
        'assets/google_client_secret.json',
      );
      final Map<String, dynamic> data = json.decode(response);
      final clientId = data['web']['client_id'];

      _googleSignIn = GoogleSignIn(
        clientId: clientId,
        scopes: ['email', 'profile'],
      );
    } catch (e) {
      print('Error initializing Google Sign In: $e');
      rethrow;
    }
  }

  // تسجيل الدخول عن طريق Google مع HTTP Server محلي
  static Future<User?> signInWithGoogle({bool rememberMe = true}) async {
    try {
      // قراءة بيانات OAuth من ملف الإعدادات
      final String response = await rootBundle.loadString(
        'assets/google_client_secret.json',
      );
      final Map<String, dynamic> data = json.decode(response);
      final clientId = data['web']['client_id'];
      final clientSecret = data['web']['client_secret'];

      // بدء HTTP Server محلي على port 8080
      final redirectUri = 'http://localhost:8080';
      final server = await HttpServer.bind('localhost', 8080);
      _redirectServer = server;

      // إنشاء state و code_verifier للأمان
      final state = _generateRandomString(32);
      final codeVerifier = _generateRandomString(128);
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // بناء رابط تسجيل الدخول
      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'email profile openid',
        'access_type': 'offline',
        'prompt': 'select_account',
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      });

      // فتح المتصفح
      if (await canLaunchUrl(authUri)) {
        await launchUrl(authUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'لا يمكن فتح المتصفح';
      }

      // انتظار رد OAuth من المتصفح
      final authCode = await _listenForOAuthCallback(server, state);

      if (authCode == null) {
        throw 'فشل في الحصول على رمز التفويض من Google';
      }

      // تبديل authorization code بـ access token
      final tokenData = await _exchangeCodeForTokens(
        authCode,
        clientId,
        clientSecret,
        redirectUri,
        codeVerifier,
      );

      if (tokenData == null) {
        throw 'فشل في الحصول على رمز الوصول من Google';
      }

      // الحصول على معلومات المستخدم
      final userInfo = await _getUserInfoFromGoogle(tokenData['access_token']);

      if (userInfo == null) {
        throw 'فشل في الحصول على معلومات المستخدم من Google';
      }

      // إنشاء كائن المستخدم
      final user = User(
        id: userInfo['id'],
        email: userInfo['email'],
        name: userInfo['name'],
        photoUrl: userInfo['picture'], // إضافة صورة Google
        loginTime: DateTime.now(),
        rememberMe: rememberMe,
      );

      _currentUser = user;
      await _saveUserLocally(user, rememberMe);

      return user;
    } catch (error) {
      print('Error signing in with Google: $error');
      await _closeRedirectServer();
      rethrow;
    }
  }

  // إنشاء string عشوائي للأمان
  static String _generateRandomString(int length) {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // إنشاء code challenge للـ PKCE
  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // الاستماع لرد OAuth من المتصفح
  static Future<String?> _listenForOAuthCallback(
    HttpServer server,
    String expectedState,
  ) async {
    try {
      await for (final request in server) {
        final uri = request.uri;

        // إرسال صفحة نجاح للمتصفح
        request.response
          ..statusCode = 200
          ..headers.set('content-type', 'text/html; charset=utf-8')
          ..write('''
            <!DOCTYPE html>
            <html dir="rtl">
            <head>
              <meta charset="utf-8">
              <title>تم تسجيل الدخول بنجاح</title>
              <style>
                body { 
                  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
                  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                  margin: 0; padding: 20px; text-align: center; color: white;
                }
                .container { 
                  max-width: 400px; margin: 100px auto; background: white; 
                  border-radius: 15px; padding: 30px; color: #333; box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                }
                .success-icon { font-size: 48px; color: #4CAF50; margin-bottom: 20px; }
                h1 { color: #333; margin-bottom: 10px; }
                p { color: #666; line-height: 1.6; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="success-icon">✅</div>
                <h1>تم تسجيل الدخول بنجاح!</h1>
                <p>يمكنك الآن إغلاق هذه النافذة والعودة إلى تطبيق تميز إداري.</p>
              </div>
              <script>
                setTimeout(() => {
                  window.close();
                }, 3000);
              </script>
            </body>
            </html>
          ''');
        await request.response.close();

        // التحقق من وجود authorization code
        final code = uri.queryParameters['code'];
        final state = uri.queryParameters['state'];
        final error = uri.queryParameters['error'];

        await _closeRedirectServer();

        if (error != null) {
          throw 'OAuth error: $error';
        }

        if (code != null && state == expectedState) {
          return code;
        }

        return null;
      }
    } catch (e) {
      await _closeRedirectServer();
      throw 'خطأ في استقبال رد OAuth: ${e.toString()}';
    }
    return null;
  }

  // إغلاق HTTP Server
  static Future<void> _closeRedirectServer() async {
    try {
      await _redirectServer?.close(force: true);
      _redirectServer = null;
    } catch (e) {
      print('Error closing redirect server: $e');
    }
  }

  // تبديل رمز التفويض بـ access token
  static Future<Map<String, dynamic>?> _exchangeCodeForTokens(
    String code,
    String clientId,
    String clientSecret,
    String redirectUri,
    String codeVerifier,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Token exchange failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error exchanging code for tokens: $e');
      return null;
    }
  }

  // الحصول على معلومات المستخدم من Google
  static Future<Map<String, dynamic>?> _getUserInfoFromGoogle(
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
          'Failed to get user info: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getting user info from Google: $e');
      return null;
    }
  }

  // تسجيل الدخول عن طريق البريد الإلكتروني (محلي)
  static Future<User?> signInWithEmail(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      // التحقق من صحة البريد الإلكتروني
      if (!_isValidEmail(email)) {
        throw 'البريد الإلكتروني غير صحيح';
      }

      // التحقق من كلمة المرور (يمكن تخصيصها حسب الحاجة)
      if (password.length < 6) {
        throw 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      }

      // التحقق من وجود المستخدم مسبقاً
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        // التحقق من كلمة المرور
        if (existingUser['password'] != _hashPassword(password)) {
          throw 'كلمة المرور غير صحيحة';
        }

        // إنشاء كائن المستخدم
        final user = User(
          id: existingUser['id'],
          email: email,
          name: existingUser['name'],
          loginTime: DateTime.now(),
          rememberMe: rememberMe,
        );

        _currentUser = user;
        await _saveUserLocally(user, rememberMe);
        return user;
      } else {
        throw 'المستخدم غير موجود. يرجى إنشاء حساب جديد أولاً.';
      }
    } catch (error) {
      print('Error signing in with email: $error');
      rethrow;
    }
  }

  // إنشاء حساب جديد
  static Future<User?> signUpWithEmail(
    String email,
    String password,
    String name, {
    bool rememberMe = true,
  }) async {
    try {
      // التحقق من صحة البيانات
      if (!_isValidEmail(email)) {
        throw 'البريد الإلكتروني غير صحيح';
      }

      if (password.length < 6) {
        throw 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      }

      if (name.trim().isEmpty) {
        throw 'يرجى إدخال الاسم';
      }

      // التحقق من عدم وجود المستخدم مسبقاً
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        throw 'هذا البريد الإلكتروني مسجل مسبقاً';
      }

      // إنشاء معرف فريد للمستخدم
      final userId = _generateUserId(email);

      // حفظ بيانات المستخدم الجديد
      await _saveUserCredentials(userId, email, password, name);

      // إنشاء كائن المستخدم
      final user = User(
        id: userId,
        email: email,
        name: name,
        loginTime: DateTime.now(),
        rememberMe: rememberMe,
      );

      _currentUser = user;
      await _saveUserLocally(user, rememberMe);

      return user;
    } catch (error) {
      print('Error signing up with email: $error');
      rethrow;
    }
  }

  // تسجيل الخروج
  static Future<void> signOut() async {
    try {
      // تسجيل الخروج من Google
      await _googleSignIn?.signOut();

      // مسح بيانات المستخدم المحلية
      await _clearUserData();

      _currentUser = null;
    } catch (error) {
      print('Error signing out: $error');
    }
  }

  // الحصول على المستخدم الحالي
  static User? get currentUser => _currentUser;

  // التحقق من حالة تسجيل الدخول
  static bool get isLoggedIn => _currentUser != null;

  // استعادة جلسة المستخدم
  static Future<User?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (!rememberMe) {
        return null; // المستخدم لم يختر "تذكرني"
      }

      final userData = prefs.getString(_userKey);
      if (userData != null) {
        final userMap = json.decode(userData);
        _currentUser = User.fromMap(userMap);
        return _currentUser;
      }
    } catch (error) {
      print('Error restoring session: $error');
    }
    return null;
  }

  // حفظ بيانات المستخدم محلياً
  static Future<void> _saveUserLocally(User user, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toMap()));
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  // مسح بيانات المستخدم المحلية
  static Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_rememberMeKey);
  }

  // حفظ بيانات اعتماد المستخدم
  static Future<void> _saveUserCredentials(
    String userId,
    String email,
    String password,
    String name,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userCredentials = {
      'id': userId,
      'email': email,
      'password': _hashPassword(password),
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(
      'user_credentials_$email',
      json.encode(userCredentials),
    );
  }

  // البحث عن المستخدم بالبريد الإلكتروني
  static Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsString = prefs.getString('user_credentials_$email');
    if (credentialsString != null) {
      return json.decode(credentialsString);
    }
    return null;
  }

  // تشفير كلمة المرور
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'taqeb_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // التحقق من صحة البريد الإلكتروني
  static bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  // إنشاء معرف فريد للمستخدم
  static String _generateUserId(String email) {
    final bytes = utf8.encode(
      email + DateTime.now().millisecondsSinceEpoch.toString(),
    );
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // التحقق من انتهاء صلاحية الجلسة (اختياري)
  static bool isSessionExpired() {
    if (_currentUser == null) return true;

    final sessionDuration = DateTime.now().difference(_currentUser!.loginTime);
    const maxSessionDuration = Duration(days: 30); // 30 يوم

    return sessionDuration > maxSessionDuration;
  }

  // تحديث بيانات المستخدم
  static Future<void> updateUser(User updatedUser) async {
    _currentUser = updatedUser;
    if (updatedUser.rememberMe) {
      await _saveUserLocally(updatedUser, true);
    }
  }
}
