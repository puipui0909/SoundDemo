import 'package:flutter/material.dart';
import 'package:spotify_clone/service/song_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spotify_clone/Screens/album_screen.dart';
import 'package:spotify_clone/Screens/player_screen.dart';
import 'package:spotify_clone/models/album.dart';
import 'package:spotify_clone/widgets/cover_appbar.dart';
import 'package:spotify_clone/widgets/list.dart';

import '../models/artist.dart';
import '../models/song.dart';
import '../models/user.dart';
import '../widgets/edit_dialog/edit_album_dialog.dart';
import '../widgets/edit_dialog/edit_delete_button.dart';
import '../widgets/edit_dialog/edit_song_dialog.dart';
import 'main_page/upload/upload_screen.dart';

class ArtistOrUserScreen extends StatefulWidget {
  final String? artistId;
  final String? userId;
  final bool isAdmin;

  const ArtistOrUserScreen({
    super.key,
    this.artistId,
    this.userId,
    this.isAdmin = false,
  });

  @override
  State<ArtistOrUserScreen> createState() => _ArtistOrUserScreenState();
}

class _ArtistOrUserScreenState extends State<ArtistOrUserScreen> {
  final supabase = Supabase.instance.client;

  Future<dynamic> _fetchProfile() async {
    if (widget.artistId != null) {
      final response = await supabase
          .from('artists')
          .select()
          .eq('id', widget.artistId!)
          .maybeSingle();
      if (response == null) return null;
      return Artist.fromMap(response);
    } else if (widget.userId != null) {
      final response = await supabase
          .from('users')
          .select()
          .eq('id', widget.userId!)
          .maybeSingle();
      if (response == null) return null;
      return AppUser.fromMap(response);
    }
    return null;
  }

  Future<List<Song>> _fetchSongs() async {
    final queryField = widget.artistId != null ? 'artist_id' : 'user_id';
    final targetId = widget.artistId ?? widget.userId;

    final response = await supabase.from('songs').select().eq(queryField, targetId!);
    return (response as List).map((e) => Song.fromMap(e)).toList();
  }

  Future<List<Album>> _fetchAlbums() async {
    final queryField = widget.artistId != null ? 'artist_id' : 'user_id';
    final targetId = widget.artistId ?? widget.userId;

    final response = await supabase.from('albums').select().eq(queryField, targetId!);
    return (response as List).map((e) => Album.fromMap(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _fetchProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text("Không tìm thấy dữ liệu")),
          );
        }

        final profile = snapshot.data!;
        final String title =
        (profile is Artist) ? profile.name : (profile.fullName.isNotEmpty ? profile.fullName : profile.email ?? 'User');
        final String imageUrl = (profile is Artist)
            ? profile.avatarUrl
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(title)}';

        return Scaffold(
          floatingActionButton: widget.isAdmin
              ? FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadScreen(
                    artistId: widget.artistId,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          )
              : null,
          body: CustomScrollView(
            slivers: [
              CoverAppbar(
                item: profile,
              ),

              // --- Bài hát ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 17),
                      Text(
                        widget.artistId != null ? "Bài hát nổi bật" : "Bài hát của người dùng",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<List<Song>>(
                        future: _fetchSongs(),
                        builder: (context, songSnapshot) {
                          if (songSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!songSnapshot.hasData || songSnapshot.data!.isEmpty) {
                            return const Text("Chưa có bài hát nào");
                          }

                          final songs = songSnapshot.data!;
                          return ListWidget<Song>(
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
                            actionsBuilder: widget.isAdmin
                                ? (context, song) => [
                              AdminActionButtons(
                                onEdit: () async {
                                  final updated = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => EditSongDialog(song: song),
                                  );
                                  if (updated == true) setState(() {});
                                },
                                onDelete: () async {
                                  try {
                                    await SongService().deleteSong(song);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã xóa bài hát')),
                                    );
                                    setState(() {});
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Xóa thất bại: $e')),
                                    );
                                  }
                                },
                                deleteConfirmTitle: 'Xác nhận',
                                deleteConfirmMessage:
                                'Bạn có chắc muốn xóa "${song.title}" không?',
                              ),
                            ]
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // --- Album ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 17),
                      Text(
                        widget.artistId != null ? "Album" : "Album của người dùng",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      FutureBuilder<List<Album>>(
                        future: _fetchAlbums(),
                        builder: (context, albumSnapshot) {
                          if (albumSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!albumSnapshot.hasData || albumSnapshot.data!.isEmpty) {
                            return const Text("Chưa có album nào");
                          }

                          final albums = albumSnapshot.data!;
                          return ListWidget<Album>(
                            items: albums,
                            getTitle: (album) => album.title,
                            getCoverUrl: (album) => album.coverUrl,
                            onTap: (context, album) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AlbumScreen(albumId: album.id),
                                ),
                              );
                            },
                            actionsBuilder: widget.isAdmin
                                ? (context, album) => [
                              AdminActionButtons(
                                onEdit: () async {
                                  final updated = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => EditAlbumDialog(album: album),
                                  );
                                  if (updated == true) setState(() {});
                                },
                                onDelete: () async {
                                  try {
                                    await supabase
                                        .from('albums')
                                        .delete()
                                        .eq('id', album.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã xóa album')),
                                    );
                                    setState(() {});
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Xóa thất bại: $e')),
                                    );
                                  }
                                },
                                deleteConfirmTitle: 'Xác nhận',
                                deleteConfirmMessage:
                                'Bạn có chắc muốn xóa album "${album.title}" không?',
                              ),
                            ]
                                : null,
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
