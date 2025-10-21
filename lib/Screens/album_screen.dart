import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spotify_clone/Screens/player_screen.dart';
import 'package:spotify_clone/widgets/list.dart';

import '../models/album.dart';
import '../models/song.dart';
import '../widgets/cover_appbar.dart';

class AlbumScreen extends StatefulWidget {
  final String albumId;
  const AlbumScreen({super.key, required this.albumId});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final supabase = Supabase.instance.client;

  Future<Album?> _fetchAlbum() async {
    final response = await supabase
        .from('albums')
        .select()
        .eq('id', widget.albumId)
        .maybeSingle();

    if (response == null) return null;
    return Album.fromMap(response);
  }

  Future<List<Song>> _fetchSongs() async {
    final response = await supabase
        .from('songs')
        .select()
        .eq('album_id', widget.albumId);

    return (response as List)
        .map((e) => Song.fromMap(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Album?>(
      future: _fetchAlbum(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text("Album không tồn tại")),
          );
        }

        final album = snapshot.data!;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              CoverAppbar(item: album),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 17),
                      FutureBuilder<List<Song>>(
                        future: _fetchSongs(),
                        builder: (context, songSnapshot) {
                          if (songSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!songSnapshot.hasData || songSnapshot.data!.isEmpty) {
                            return const Text('Chưa có bài hát nào');
                          }

                          final songs = songSnapshot.data!;
                          return ListWidget(
                            items: songs,
                            getTitle: (song) => song.title,
                            getCoverUrl: (song) => song.coverUrl,
                            onTap: (context, song) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayerScreen(playlist: songs,
                                    initialIndex: songs.indexOf(song),),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
