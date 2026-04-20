// lib/domain/entities/user_entity.dart
class UserEntity {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String? profilePicturePath;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String defaultCurrency;

  UserEntity({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.profilePicturePath,
    this.createdAt,
    this.updatedAt,
    this.defaultCurrency = 'USD',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'profile_picture_path': profilePicturePath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'default_currency': defaultCurrency,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      profilePicturePath: map['profile_picture_path'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      defaultCurrency: map['default_currency'] ?? 'USD',
    );
  }
  
  UserEntity copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? profilePicturePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? defaultCurrency,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    );
  }
}