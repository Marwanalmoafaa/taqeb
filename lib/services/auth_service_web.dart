import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taqeb/models/user.dart';

// Web-friendly AuthService: no dart:io, no local HTTP server.
// For Google Sign-In on web, you should configure OAuth Client for web
// and use the official google_sign_in package which supports web.
class AuthService {
  static User? _currentUser;
  static const String _userKey = 'current_user';
  static const String _rememberMeKey = 'remember_me';

  static Future<void> initialize() async {
    // Optionally read any web config here if needed.
    try {
      await restoreSession();
    } catch (_) {}
  }

  static Future<User?> signInWithGoogle({bool rememberMe = true}) async {
    // Minimal stub to avoid build break. Replace with google_sign_in web flow if needed.
    throw UnsupportedError('تسجيل Google غير مفعّل على الويب حالياً');
  }

  static Future<User?> signInWithEmail(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
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
  }

  static Future<User?> signUpWithEmail(
    String email,
    String password,
    String name, {
    bool rememberMe = true,
  }) async {
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
  }

  static Future<void> signOut() async {
    await _clearUserData();
    _currentUser = null;
  }

  static User? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  static Future<User?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (!rememberMe) return null;
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      final userMap = json.decode(userData);
      _currentUser = User.fromMap(userMap);
      return _currentUser;
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
    // Simplified; okay for local mock use
    return 'h:${password}_2024';
  }

  static bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  static String _generateUserId(String email) {
    return '${email.hashCode}_${DateTime.now().millisecondsSinceEpoch}'
        .substring(0, 16);
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
