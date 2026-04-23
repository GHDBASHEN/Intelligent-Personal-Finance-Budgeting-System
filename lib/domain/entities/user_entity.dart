class UserEntity {
  final String? id;
  final String username;
  final String email;
  final String password;
  final String? profileImageUrl;
  final String? preferredCurrency;
  final String? phoneNumber;
  final DateTime? createdAt;

  UserEntity({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.profileImageUrl,
    this.preferredCurrency,
    this.phoneNumber,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'profileImageUrl': profileImageUrl,
      'preferredCurrency': preferredCurrency,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id']?.toString(),
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      preferredCurrency: map['preferredCurrency'],
      phoneNumber: map['phoneNumber'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  UserEntity copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? profileImageUrl,
    String? preferredCurrency,
    String? phoneNumber,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}