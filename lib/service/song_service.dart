import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';

class SongService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔹 Stream real-time tất cả bài hát
  Stream<List<Song>> getSongsStream() {
    return _supabase
        .from('songs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => Song.fromMap(r)).toList());
  }

  /// 🔹 Lấy danh sách bài hát 1 lần
  Future<List<Song>> getSongsOnce() async {
    final response = await _supabase
        .from('songs')
        .select()
        .order('created_at', ascending: false);
    return response.map<Song>((r) => Song.fromMap(r)).toList();
  }

  /// 🔹 Upload file nhạc + cover + lưu metadata vào bảng songs
  Future<Song> uploadSong({
    required String title,
    required File audioFile,
    File? coverFile,
    String? albumId,      // Có thể null
    String? artistId,     // Có thể null
    required int duration,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception("User chưa đăng nhập");
      }

      // ----- Upload Audio -----
      final audioFileName =
          "audio/${DateTime.now().millisecondsSinceEpoch}_${audioFile.path.split('/').last}";
      await _supabase.storage.from("media").upload(
        audioFileName,
        audioFile,
        fileOptions: const FileOptions(upsert: false),
      );
      final audioUrl =
      _supabase.storage.from("media").getPublicUrl(audioFileName);

      // ----- Upload Cover (nếu có) -----
      String? coverUrl;
      if (coverFile != null) {
        final coverFileName =
            "images/${DateTime.now().millisecondsSinceEpoch}_${coverFile.path.split('/').last}";
        await _supabase.storage.from("media").upload(
          coverFileName,
          coverFile,
          fileOptions: const FileOptions(upsert: false),
        );
        coverUrl =
            _supabase.storage.from("media").getPublicUrl(coverFileName);
      }

      // ----- Xác định chủ sở hữu -----
      String? userId;
      String? finalArtistId;

      if (artistId != null && artistId.trim().isNotEmpty) {
        // ✅ Admin upload cho artist
        userId = null;
        finalArtistId = artistId;
      } else {
        // ✅ User upload cho chính mình
        userId = currentUser.id;
        finalArtistId = null;
      }

      // ----- Tạo map dữ liệu để insert -----
      final Map<String, dynamic> songData = {
        "title": title,
        "audio_url": audioUrl,
        "cover_url": coverUrl,
        "user_id": userId,
        "artist_id": finalArtistId,
        "album_id": (albumId != null && albumId.trim().isNotEmpty) ? albumId : null,
        "like_count": 0,
        "duration": duration,
        "created_at": DateTime.now().toIso8601String(),
      };

      print("🟩 [UploadSong] Insert data: $songData");

      // ----- Insert vào bảng songs -----
      final response =
      await _supabase.from("songs").insert(songData).select().maybeSingle();

      if (response == null) {
        throw Exception("Insert song thất bại: không có dữ liệu trả về");
      }

      print("✅ [UploadSong] Thành công: $response");
      return Song.fromMap(response);
    } catch (e, stack) {
      print("❌ [UploadSong] Lỗi: $e\n$stack");
      throw Exception("Upload song failed: $e");
    }
  }

  /// 🔹 Cập nhật bài hát
  Future<void> updateSong(Song song) async {
    try {
      await _supabase.from('songs').update(song.toMap()).eq('id', song.id);
    } catch (e) {
      throw Exception("Update song failed: $e");
    }
  }

  /// 🔹 Xóa bài hát (bao gồm file nhạc & cover)
  Future<void> deleteSong(Song song) async {
    try {
      if (song.audioUrl.isNotEmpty) {
        final audioPath = Uri.parse(song.audioUrl).path;
        final fileName = audioPath.split("/media/").last;
        if (fileName.isNotEmpty) {
          await _supabase.storage.from("media").remove([fileName]);
        }
      }

      if (song.coverUrl.isNotEmpty) {
        final coverPath = Uri.parse(song.coverUrl).path;
        final fileName = coverPath.split("/media/").last;
        if (fileName.isNotEmpty) {
          await _supabase.storage.from("media").remove([fileName]);
        }
      }

      await _supabase.from("songs").delete().eq("id", song.id);
    } catch (e) {
      throw Exception("Delete song failed: $e");
    }
  }

  /// 🔹 Lấy tất cả bài hát của 1 artist
  Future<List<Song>> getSongsByArtist(String artistId) async {
    final response = await _supabase
        .from('songs')
        .select()
        .eq('artist_id', artistId)
        .order('created_at', ascending: false);
    return response.map<Song>((r) => Song.fromMap(r)).toList();
  }

  /// 🔹 Lấy tất cả bài hát của 1 album
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    final response = await _supabase
        .from('songs')
        .select()
        .eq('album_id', albumId)
        .order('created_at', ascending: false);
    return response.map<Song>((r) => Song.fromMap(r)).toList();
  }

  /// 🔹 Lấy bài hát của user hiện tại
  Future<List<Song>> getSongsByCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _supabase
        .from('songs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response.map<Song>((r) => Song.fromMap(r)).toList();
  }
}
