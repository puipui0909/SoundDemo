import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/song.dart';

class LikedSongService {
  static final LikedSongService instance = LikedSongService._internal();
  LikedSongService._internal();

  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  /// 🔹 Stream realtime danh sách bài hát đã like của user
  Stream<List<Song>> likedSongsStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('song_likes')
        .stream(primaryKey: ['id']) // lắng nghe toàn bộ table
        .asyncMap((rows) async {
      // Lọc các like của user ở đây
      final userRows = rows.where((r) => r['user_id'] == user.id).toList();

      if (userRows.isEmpty) return <Song>[];

      final songIds = userRows.map((r) => r['song_id']).toList();

      final songsData =
      await _supabase.from('songs').select().inFilter('id', songIds);

      final songs = (songsData as List)
          .map((s) => Song.fromMap(s as Map<String, dynamic>))
          .toList();

      songs.sort((a, b) {
        final aTime = userRows.firstWhere((r) => r['song_id'] == a.id)['created_at'];
        final bTime = userRows.firstWhere((r) => r['song_id'] == b.id)['created_at'];
        return bTime.compareTo(aTime);
      });

      return songs;
    });
  }

  /// 🔹 Stream theo dõi 1 bài hát có được user like không
  Stream<List<Map<String, dynamic>>> likeStreamForSong(String songId,
      String userId) {
    return _supabase
        .from('song_likes')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) =>
        rows
            .where((row) =>
        row['song_id'] == songId && row['user_id'] == userId)
            .toList());
  }

  /// 🔹 Kiểm tra trạng thái like (nếu cần)
  Future<bool> isLiked(String songId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final res = await _supabase
        .from('song_likes')
        .select('id')
        .eq('user_id', user.id)
        .eq('song_id', songId)
        .maybeSingle();

    return res != null;
  }

  /// 🔹 Like bài hát
  Future<void> likeSong(Song song) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('song_likes').insert({
      'user_id': user.id,
      'song_id': song.id,
    });
  }

  Future<void> unlikeSong(String songId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('song_likes')
        .delete()
        .eq('user_id', user.id)
        .eq('song_id', songId);
  }
}

