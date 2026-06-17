class UserModel {
  const UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.profileImagePath,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String profileImagePath;
  final DateTime createdAt;

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    String? profileImagePath,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'profile_image_path': profileImagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      profileImagePath: map['profile_image_path'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
