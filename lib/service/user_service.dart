import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';

class UserService {
  final supabase = Supabase.instance.client;

  /// Lấy user hiện tại 1 lần
  Future<AppUser?> getCurrentUser() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      print('Không có user đăng nhập trong auth');
      return null;
    }

    final response = await supabase
        .from('users')
        .select()
        .eq('id', currentUser.id)
        .maybeSingle();

    print('📦 Query result getCurrentUser: $response');

    if (response == null) {
      print('Không tìm thấy user trong bảng users');
      return null;
    }

    return AppUser.fromMap(response);
  }

  /// Lấy stream user hiện tại
  Stream<AppUser?> streamCurrentUser() {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      print('Không có user đăng nhập trong auth');
      return Stream.value(null);
    }

    return supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', currentUser.id)
        .map((rows) {
      print('📦 Stream rows: $rows');
      if (rows.isEmpty) {
        print('Stream không tìm thấy user trong bảng users');
        return null;
      }
      return AppUser.fromMap(rows.first);
    });
  }

  /// Update full name
  Future<void> updateUserFullName(String uid, String newName) async {
    final response = await supabase
        .from('users')
        .update({'full_name': newName})
        .eq('id', uid);

    print('Update response: $response');
  }

  /// Lấy stream user theo ID
  Stream<AppUser?> streamUserById(String id) {
    final supabase = Supabase.instance.client;
    return supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((rows) => rows.isNotEmpty
        ? AppUser.fromMap(Map<String, dynamic>.from(rows.first))
        : null);
  }

  /// Upload avatar lên Supabase Storage và cập nhật link vào bảng users
  Future<String?> updateUserAvatar(String userId, File imageFile) async {
    try {
      // Upload file vào bucket "avatars"
      final fileExt = imageFile.path.split('.').last;
      final filePath = 'public/$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await supabase.storage.from('media').upload(filePath, imageFile, fileOptions: const FileOptions(upsert: true));

      // Lấy public URL
      final publicUrl = supabase.storage.from('media').getPublicUrl(filePath);

      // Cập nhật vào bảng users
      await supabase.from('users').update({'avatar_url': publicUrl}).eq('id', userId);

      print('Avatar updated successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Lỗi khi cập nhật avatar: $e');
      return null;
    }
  }
}
