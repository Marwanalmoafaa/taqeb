import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 4)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final DateTime loginTime;

  @HiveField(5)
  final bool rememberMe;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.loginTime,
    this.rememberMe = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    DateTime? loginTime,
    bool? rememberMe,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      loginTime: loginTime ?? this.loginTime,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'loginTime': loginTime.toIso8601String(),
      'rememberMe': rememberMe,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      loginTime: DateTime.parse(map['loginTime']),
      rememberMe: map['rememberMe'] ?? false,
    );
  }
}
