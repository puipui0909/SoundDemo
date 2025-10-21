import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlbumService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔹 Upload file lên Supabase Storage và trả về public URL
  Future<String> _uploadFile({
    required File file,
    required String folder,
  }) async {
    final fileName =
        "$folder/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";

    try {
      await _supabase.storage.from('media').upload(fileName, file);
      return _supabase.storage.from('media').getPublicUrl(fileName);
    } catch (e) {
      throw Exception("Upload file thất bại: $e");
    }
  }

  /// 🔹 Upload album (ảnh bìa + metadata)
  /// Nếu admin thêm album cho artist → truyền [artistId]
  /// Nếu user thường thêm → không cần truyền [artistId]
  Future<void> uploadAlbum({
    required String title,
    required File coverImage,
    String? artistId,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("Người dùng chưa đăng nhập");
    }

    try {
      // 1️⃣ Upload ảnh bìa
      final coverUrl = await _uploadFile(
        file: coverImage,
        folder: "images/albums",
      );

      // 2️⃣ Chuẩn bị dữ liệu
      String? userId;
      String? finalArtistId;

      if (artistId != null && artistId.isNotEmpty) {
        // ✅ Trường hợp admin upload cho 1 artist cụ thể
        userId = null;
        finalArtistId = artistId;
      } else {
        // ✅ Trường hợp user thường tự upload album
        userId = currentUser.id;
        finalArtistId = null;
      }

      final data = {
        "title": title,
        "cover_url": coverUrl,
        "user_id": userId,
        "artist_id": finalArtistId,
        "created_at": DateTime.now().toIso8601String(),
      };

      final response =
      await _supabase.from("albums").insert(data).select().maybeSingle();

      if (response == null) throw Exception("Không thể tạo album mới");

      print("✅ Upload album thành công: $response");
    } catch (e) {
      print("❌ Upload album thất bại: $e");
      rethrow;
    }
  }

  /// 🔹 Lấy danh sách album của user hiện tại
  Future<List<Map<String, dynamic>>> getUserAlbums() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception("Người dùng chưa đăng nhập");
    }

    try {
      final response = await _supabase
          .from("albums")
          .select()
          .eq("user_id", currentUser.id)
          .order("created_at", ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception("Lấy danh sách album thất bại: $e");
    }
  }

  /// 🔹 Lấy danh sách album theo artist_id (dùng cho admin)
  Future<List<Map<String, dynamic>>> getAlbumsByArtistId(String artistId) async {
    try {
      final response = await _supabase
          .from('albums')
          .select()
          .eq('artist_id', artistId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception("Lấy danh sách album theo artist thất bại: $e");
    }
  }
}
