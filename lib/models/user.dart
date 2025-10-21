import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String fullName;
  final String? email;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.fullName,
    this.email,
    this.role = 'user',
    this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => fullName.isEmpty ? id : fullName;
  String get initials =>
      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

  /// convert AppUser -> Map để lưu vào Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// convert Supabase row -> AppUser
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? '',
      email: map['email'],
      role: map['role'] ?? 'user',
      avatarUrl: map['avatar_url'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// update fullname trong Supabase
  static Future<void> updateUserFullName(String id, String newName) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('users')
        .update({'full_name': newName})
        .eq('id', id)
        .select();
  }

  /// update avatar trong Supabase
  static Future<void> updateUserAvatar(String id, String? newAvatarUrl) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('users')
        .update({'avatar_url': newAvatarUrl}) // Có thể null
        .eq('id', id)
        .select();
  }
  static Future<AppUser?> fetchCurrentUser() async {
    final supabase = Supabase.instance.client;
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;

    final data = await supabase
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (data == null) return null;

    return AppUser.fromMap(data);
  }
}
