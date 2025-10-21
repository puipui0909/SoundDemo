import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/artist.dart';

class ArtistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔹 Stream tất cả artist (real-time)
  Stream<List<Artist>> getArtistsStream() {
    return _supabase
        .from('artists')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => Artist.fromMap(r)).toList());
  }

  /// 🔹 Lấy danh sách artist một lần (non-realtime)
  Future<List<Artist>> fetchAll() async {
    try {
      final data = await _supabase
          .from('artists')
          .select()
          .order('created_at', ascending: false);

      return (data as List).map((map) => Artist.fromMap(map)).toList();
    } catch (e) {
      throw Exception("Fetch artists failed: $e");
    }
  }

  /// 🔹 Thêm artist mới (có upload ảnh nếu có)
  Future<void> addArtist({
    required String name,
    File? imageFile,
  }) async {
    try {
      String? avatarUrl;
      if (imageFile != null) {
        final fileName =
            "images/artists/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}";
        await _supabase.storage.from('media').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: false),
        );
        avatarUrl = _supabase.storage.from('media').getPublicUrl(fileName);
      }

      await _supabase.from('artists').insert({
        'name': name,
        'avatar_url': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception("Add artist failed: $e");
    }
  }

  /// 🔹 Cập nhật artist (có thể thay ảnh)
  Future<void> updateArtist(Artist artist, {File? newImageFile}) async {
    try {
      String? avatarUrl = artist.avatarUrl;

      // Nếu có ảnh mới thì upload lại
      if (newImageFile != null) {
        final fileName =
            "images/artists/${DateTime.now().millisecondsSinceEpoch}_${newImageFile.path.split('/').last}";
        await _supabase.storage.from('media').upload(
          fileName,
          newImageFile,
          fileOptions: const FileOptions(upsert: true),
        );
        avatarUrl = _supabase.storage.from('media').getPublicUrl(fileName);
      }

      await _supabase.from('artists').update({
        'name': artist.name,
        'avatar_url': avatarUrl,
      }).eq('id', artist.id);
    } catch (e) {
      throw Exception("Update artist failed: $e");
    }
  }

  /// 🔹 Xóa artist (và ảnh nếu có)
  Future<void> deleteArtist(Artist artist) async {
    try {
      // Xóa ảnh trong storage nếu có
      if (artist.avatarUrl.isNotEmpty) {
        final imagePath = Uri.parse(artist.avatarUrl).path;
        final fileName = imagePath.split("/media/").last;
        await _supabase.storage.from("media").remove([fileName]);
      }

      // Xóa bản ghi trong DB
      await _supabase.from('artists').delete().eq('id', artist.id);
    } catch (e) {
      throw Exception("Delete artist failed: $e");
    }
  }
}
