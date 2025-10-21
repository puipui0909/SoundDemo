import 'package:flutter/material.dart';
import 'package:spotify_clone/models/artist.dart';
import 'package:spotify_clone/widgets/like_button.dart';
import '../../models/song.dart';
import '../../Screens/player_screen.dart';
import '../../Screens/artist_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MediaType { song, artist }

class MediaItem extends StatelessWidget {
  final MediaType type;
  final Song? song;
  final List<Song>? playlist; // ✅ danh sách bài hát
  final Artist? artist;
  final int? index; // ✅ vị trí bài trong danh sách

  final double width;
  final double height;

  const MediaItem.song({
    super.key,
    required this.song,
    this.width = 147,
    this.height = 193,
    this.playlist,
    this.index,
  })  : type = MediaType.song,
        artist = null;

  const MediaItem.artist({
    super.key,
    required this.artist,
    this.width = 147,
    this.height = 147,
  })  : type = MediaType.artist,
        song = null,
        playlist = null,
        index = null;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MediaType.song:
        return _buildSongItem(context);
      case MediaType.artist:
        return _buildArtistItem(context);
    }
  }

  /// ================= SONG ITEM =================
  Widget _buildSongItem(BuildContext context) {
    final songData = song!;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "guest";

    return InkWell(
      onTap: () {
        if (playlist != null && index != null) {
          // ✅ Có playlist → mở theo danh sách
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                playlist: playlist!,
                initialIndex: index!,
              ),
            ),
          );
        } else {
          // ✅ fallback: chỉ có 1 bài → dùng constructor phụ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerScreen.single(song: songData),
            ),
          );
        }
      },

      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                songData.coverUrl ?? "",
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: width,
                  height: height,
                  color: Colors.purple[300],
                  child: const Icon(Icons.music_note, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 3),

            /// Tên bài hát
            Text(
              songData.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            /// Artist name + like button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Lấy artist từ Supabase
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: Supabase.instance.client
                        .from('artists')
                        .select()
                        .eq('id', songData.artistId)
                        .maybeSingle(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("Đang tải...");
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const Text("Unknown Artist");
                      }
                      final artistData = snapshot.data!;
                      return Text(
                        artistData['name'] ?? "Unknown Artist",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),

                /// Like button + đếm likes
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('song_likes')
                      .stream(primaryKey: ['id'])
                      .eq('song_id', songData.id),
                  builder: (context, snapshot) {
                    final allLikes = snapshot.data ?? [];
                    final isLiked =
                    allLikes.any((row) => row['user_id'] == userId);

                    return Column(
                      children: [
                        LikeButton(song: songData),
                        Text(
                          allLikes.length.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  /// ================= ARTIST ITEM =================
  Widget _buildArtistItem(BuildContext context) {
    final artistData = artist!;
    return InkWell(
      onTap: () {
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: ArtistOrUserScreen(artistId: artistData.id),
          withNavBar: true,
          pageTransitionAnimation: PageTransitionAnimation.cupertino,
        );
      },
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            ClipOval(
              child: Image.network(
                artistData.avatarUrl,
                width: width,
                height: width,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: width,
                  height: width,
                  color: Colors.grey[300],
                  child: const Icon(Icons.account_circle, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              artistData.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
