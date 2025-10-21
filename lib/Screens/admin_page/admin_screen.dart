import 'package:flutter/material.dart';
import 'package:spotify_clone/Screens/artist_screen.dart';
import '../../features/search/my_search_delegate.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../../service/artist_service.dart';
import '../../service/song_service.dart';
import '../../widgets/custom_appbar.dart';

import '../../widgets/edit_dialog/edit_artist_dialog.dart';
import '../../widgets/edit_dialog/edit_delete_button.dart';
import '../../widgets/list.dart';
import '../../widgets/edit_dialog/edit_song_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final SongService _songService = SongService();
  final ArtistService _artistService = ArtistService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

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
        title: 'ADMIN',
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Songs'),
              Tab(text: 'Artists'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsTab(),
                _buildArtistsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (_) => const EditArtistDialog(),
          );

          if (result == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Danh sách nghệ sĩ đã được cập nhật')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 🟢 SONGS TAB
  Widget _buildSongsTab() {
    return StreamBuilder<List<Song>>(
      stream: _songService.getSongsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final songs = snapshot.data!;
        if (songs.isEmpty) {
          return const Center(child: Text('Chưa có bài hát nào.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: ListWidget<Song>(
            items: songs,
            getTitle: (song) => song.title,
            getCoverUrl: (song) => song.coverUrl,
            onTap: (context, song) async {
              final updated = await showDialog<bool>(
                context: context,
                builder: (_) => EditSongDialog(song: song), // ✅ dùng trực tiếp
              );
              if (updated == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã cập nhật bài hát')),
                );
              }
            },
            actionsBuilder: (context, song) =>
            [
              AdminActionButtons(
                onEdit: () async {
                  final updated = await showDialog<bool>(
                    context: context,
                    builder: (_) => EditSongDialog(song: song),
                  );
                  if (updated == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật bài hát')),
                    );
                  }
                },
                onDelete: () async {
                  try {
                    await _songService.deleteSong(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa bài hát')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Xóa thất bại: $e')),
                    );
                  }
                },
                deleteConfirmTitle: 'Xác nhận',
                deleteConfirmMessage: 'Bạn có chắc muốn xóa "${song
                    .title}" không?',
              ),

            ],
          ),
        );
      },
    );
  }

  /// ARTISTS TAB
  Widget _buildArtistsTab() {
    return StreamBuilder<List<Artist>>(
      stream: _artistService.getArtistsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final artists = snapshot.data!;
        if (artists.isEmpty) {
          return const Center(child: Text('Chưa có nghệ sĩ nào.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: ListWidget<Artist>(
            items: artists,
            getTitle: (artist) => artist.name,
            getCoverUrl: (artist) => artist.avatarUrl,
            onTap: (context, artist) async {
                Navigator.push(
                    context,
                  MaterialPageRoute(
                    builder: (_) => ArtistOrUserScreen(
                        artistId: artist.id,
                        isAdmin: true,),
                  ),
                );
            },
            actionsBuilder: (context, artist) =>
            [
              AdminActionButtons(
                onEdit: () async {
                  final updated = await showDialog<bool>(
                    context: context,
                    builder: (_) => EditArtistDialog(artist: artist),
                  );
                  if (updated == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã cập nhật nghệ sĩ')),
                    );
                  }
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        AlertDialog(
                          title: const Text('Xác nhận'),
                          content: Text('Bạn có chắc muốn xóa nghệ sĩ "${artist
                              .name}" không?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    try {
                      await _artistService.deleteArtist(artist);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa nghệ sĩ')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Xóa thất bại: $e')),
                      );
                    }
                  }
                },
                deleteConfirmTitle: 'Xác nhận',
                deleteConfirmMessage: 'Bạn có chắc muốn xóa "${artist
                    .name}" không?',
              ),
            ],
          ),
        );
      },
    );
  }
}
