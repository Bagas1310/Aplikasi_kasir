class UserModel {
  final int? id;
  final String name;
  final String username;
  final String password;
  final String role;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.username,
    required this.password,
    this.role = 'staff',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOwner => role == 'owner';

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'username': username,
    'password': password,
    'role': role,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as int?,
    name: map['name'] as String,
    username: map['username'] as String,
    password: map['password'] as String,
    role: map['role'] as String? ?? 'staff',
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  UserModel copyWith({
    int? id,
    String? name,
    String? username,
    String? password,
    String? role,
    DateTime? createdAt,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    username: username ?? this.username,
    password: password ?? this.password,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
  );
}
