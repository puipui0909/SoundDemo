import 'package:flutter/material.dart';
import '../../features/search/my_search_delegate.dart';
import '../../models/song.dart';
import '../../service/liked_songs_service.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/list.dart';
import '../player_screen.dart';

class LibraryScreen extends StatelessWidget {
  final LikedSongService service = LikedSongService.instance;

  LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        action: IconButton(
          onPressed: () {
            showSearch(
              context: context,
              delegate: MySearchDelegate(),
            );
          },
          icon: const Icon(Icons.search),
        ),
        title: 'LIBRARY',
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: StreamBuilder<List<Song>>(
          stream: service.likedSongsStream(),
          initialData: const [],
          builder: (context, snapshot) {
            // 🔄 Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final songs = snapshot.data ?? [];

            // 🫥 Empty state
            if (songs.isEmpty) {
              return const Center(
                child: Text(
                  "Chưa có bài hát yêu thích nào",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            // 🎵 Hiển thị danh sách
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Text(
                    "Bài hát ưa thích",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListWidget(
                    items: songs,
                    getTitle: (song) => song.title,
                    getCoverUrl: (song) => song.coverUrl,
                    onTap: (context, song) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            playlist: songs,
                            initialIndex: songs.indexOf(song),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
