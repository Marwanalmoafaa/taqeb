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

  static Future<void> initialize() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/google_client_secret.json',
      );

      // التحقق من أن الملف ليس فارغًا
      if (response.trim().isEmpty) {
        throw Exception('Google client secret file is empty');
      }

      final Map<String, dynamic> data = json.decode(response);
      final clientId = data['web']['client_id'];

      _googleSignIn = GoogleSignIn(
        clientId: clientId,
        scopes: ['email', 'profile'],
      );
      print('تم تهيئة Google Sign-In بنجاح');
    } catch (e) {
      print('تعذر تهيئة Google Sign-In: $e');
      print('سيتم العمل بتسجيل الدخول بالإيميل فقط');
      // Google Sign-In not configured, continue without it
      _googleSignIn = null;
    }
  }

  static Future<User?> signInWithGoogle({bool rememberMe = true}) async {
    // التحقق من توفر Google Sign-In
    if (_googleSignIn == null) {
      throw Exception(
        'Google Sign-In غير مكون. يرجى استخدام تسجيل الدخول بالإيميل',
      );
    }

    try {
      final String response = await rootBundle.loadString(
        'assets/google_client_secret.json',
      );

      // التحقق من أن الملف ليس فارغًا
      if (response.trim().isEmpty) {
        throw Exception(
          'ملف تكوين Google فارغ. يرجى تكوين Google Sign-In أولاً',
        );
      }

      final Map<String, dynamic> data = json.decode(response);
      final clientId = data['web']['client_id'];
      final clientSecret = data['web']['client_secret'];

      final redirectUri = 'http://localhost:8080';
      final server = await HttpServer.bind('localhost', 8080);
      _redirectServer = server;

      final state = _generateRandomString(32);
      final codeVerifier = _generateRandomString(128);
      final codeChallenge = _generateCodeChallenge(codeVerifier);

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

      if (await canLaunchUrl(authUri)) {
        await launchUrl(authUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'لا يمكن فتح المتصفح';
      }

      final authCode = await _listenForOAuthCallback(server, state);
      if (authCode == null) throw 'فشل في الحصول على رمز التفويض من Google';

      final tokenData = await _exchangeCodeForTokens(
        authCode,
        clientId,
        clientSecret,
        redirectUri,
        codeVerifier,
      );
      if (tokenData == null) throw 'فشل في الحصول على رمز الوصول من Google';

      final userInfo = await _getUserInfoFromGoogle(tokenData['access_token']);
      if (userInfo == null)
        throw 'فشل في الحصول على معلومات المستخدم من Google';

      final user = User(
        id: userInfo['id'],
        email: userInfo['email'],
        name: userInfo['name'],
        photoUrl: userInfo['picture'],
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

  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static Future<String?> _listenForOAuthCallback(
    HttpServer server,
    String expectedState,
  ) async {
    try {
      await for (final request in server) {
        final uri = request.uri;
        request.response
          ..statusCode = 200
          ..headers.set('content-type', 'text/html; charset=utf-8')
          ..write('''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تعقيب - تم تسجيل الدخول بنجاح</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            text-align: center;
        }
        
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px 30px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            border: 1px solid rgba(255, 255, 255, 0.2);
            max-width: 400px;
            animation: slideIn 0.6s ease-out;
        }
        
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .icon {
            font-size: 64px;
            margin-bottom: 20px;
            animation: bounce 2s infinite;
        }
        
        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% {
                transform: translateY(0);
            }
            40% {
                transform: translateY(-10px);
            }
            60% {
                transform: translateY(-5px);
            }
        }
        
        h1 {
            font-size: 28px;
            margin-bottom: 15px;
            font-weight: 600;
        }
        
        p {
            font-size: 16px;
            line-height: 1.6;
            margin-bottom: 20px;
            opacity: 0.9;
        }
        
        .brand {
            font-size: 20px;
            font-weight: bold;
            color: #FFD700;
            margin-top: 20px;
        }
        
        .close-btn {
            background: rgba(255, 255, 255, 0.2);
            border: 1px solid rgba(255, 255, 255, 0.3);
            color: white;
            padding: 12px 24px;
            border-radius: 25px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s ease;
            margin-top: 15px;
        }
        
        .close-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">✅</div>
        <h1>تم تسجيل الدخول بنجاح!</h1>
        <p>تم ربط حسابك في Google بنجاح مع تطبيق تعقيب</p>
        <p>يمكنك الآن إغلاق هذه النافذة والعودة إلى التطبيق</p>
        <div class="brand">تعقيب</div>
        <button class="close-btn" onclick="window.close()">إغلاق النافذة</button>
    </div>
    
    <script>
        // إغلاق النافذة تلقائياً بعد 3 ثوانٍ
        setTimeout(() => {
            window.close();
        }, 3000);
        
        // إضافة تأثير عند تحميل الصفحة
        document.addEventListener('DOMContentLoaded', () => {
            document.body.style.opacity = '0';
            document.body.style.transition = 'opacity 0.5s ease';
            setTimeout(() => {
                document.body.style.opacity = '1';
            }, 100);
        });
    </script>
</body>
</html>
          ''');
        await request.response.close();

        final code = uri.queryParameters['code'];
        final state = uri.queryParameters['state'];
        final error = uri.queryParameters['error'];

        await _closeRedirectServer();
        if (error != null) throw 'OAuth error: $error';
        if (code != null && state == expectedState) return code;
        return null;
      }
    } catch (e) {
      await _closeRedirectServer();
      throw 'خطأ في استقبال رد OAuth: ${e.toString()}';
    }
    return null;
  }

  static Future<void> _closeRedirectServer() async {
    try {
      await _redirectServer?.close(force: true);
      _redirectServer = null;
    } catch (e) {
      print('Error closing redirect server: $e');
    }
  }

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

  static Future<User?> signInWithEmail(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      if (!_isValidEmail(email)) throw 'البريد الإلكتروني غير صحيح';
      if (password.length < 6) throw 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        if (existingUser['password'] != _hashPassword(password)) {
          throw 'كلمة المرور غير صحيحة';
        }
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

  static Future<User?> signUpWithEmail(
    String email,
    String password,
    String name, {
    bool rememberMe = true,
  }) async {
    try {
      if (!_isValidEmail(email)) throw 'البريد الإلكتروني غير صحيح';
      if (password.length < 6) throw 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      if (name.trim().isEmpty) throw 'يرجى إدخال الاسم';

      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        throw 'هذا البريد الإلكتروني مسجل مسبقاً';
      }

      final userId = _generateUserId(email);
      await _saveUserCredentials(userId, email, password, name);

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

  static Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
      await _clearUserData();
      _currentUser = null;
    } catch (error) {
      print('Error signing out: $error');
    }
  }

  static User? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  static Future<User?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (!rememberMe) return null;
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

  static Future<void> _saveUserLocally(User user, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toMap()));
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  static Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_rememberMeKey);
  }

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

  static Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsString = prefs.getString('user_credentials_$email');
    if (credentialsString != null) {
      return json.decode(credentialsString);
    }
    return null;
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'taqeb_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  static String _generateUserId(String email) {
    final bytes = utf8.encode(
      email + DateTime.now().millisecondsSinceEpoch.toString(),
    );
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  static bool isSessionExpired() {
    if (_currentUser == null) return true;
    final sessionDuration = DateTime.now().difference(_currentUser!.loginTime);
    const maxSessionDuration = Duration(days: 30);
    return sessionDuration > maxSessionDuration;
  }

  static Future<void> updateUser(User updatedUser) async {
    _currentUser = updatedUser;
    if (updatedUser.rememberMe) {
      await _saveUserLocally(updatedUser, true);
    }
  }
}
