import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:spotify_clone/Screens/album_screen.dart';
import 'package:spotify_clone/Screens/player_screen.dart';
import 'package:spotify_clone/Screens/artist_screen.dart';
import 'package:spotify_clone/Screens/main_page/profile_screen.dart';

import 'package:spotify_clone/models/song.dart';
import 'package:spotify_clone/models/album.dart';
import 'package:spotify_clone/models/artist.dart';
import 'package:spotify_clone/models/user.dart';

class MySearchDelegate extends SearchDelegate {
  final _supabase = Supabase.instance.client;

  List<Song> _allSongs = [];
  List<Artist> _allArtists = [];
  List<Album> _allAlbums = [];
  List<AppUser> _allUsers = [];

  bool _isLoaded = false;
  String? _currentUserRole;

  /// 🔹 Load role của current user (admin / user)
  Future<void> _loadCurrentUserRole() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final res = await _supabase
        .from('users')
        .select('role')
        .eq('id', currentUser.id)
        .maybeSingle();

    _currentUserRole = res?['role'] ?? 'user';
  }

  /// 🔹 Load tất cả dữ liệu 1 lần từ Supabase
  Future<void> _loadAllData() async {
    final songRes = await _supabase.from('songs').select();
    final artistRes = await _supabase.from('artists').select();
    final albumRes = await _supabase.from('albums').select();
    final userRes = await _supabase.from('users').select('id, full_name, email, role');

    _allSongs = (songRes as List).map((map) => Song.fromMap(map)).toList();
    _allArtists = (artistRes as List).map((map) => Artist.fromMap(map)).toList();
    _allAlbums = (albumRes as List).map((map) => Album.fromMap(map)).toList();
    _allUsers = (userRes as List)
        .map((map) => AppUser.fromMap(Map<String, dynamic>.from(map)))
        .toList();

    await _loadCurrentUserRole();
    _isLoaded = true;
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text("Nhập để tìm kiếm..."));
    }

    return FutureBuilder(
      future: _isLoaded ? Future.value() : _loadAllData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final lowerQuery = query.toLowerCase();

        final songs = _allSongs
            .where((s) => s.title.toLowerCase().contains(lowerQuery))
            .toList();

        final albums = _allAlbums
            .where((al) => al.title.toLowerCase().contains(lowerQuery))
            .toList();

        final artists = _allArtists
            .where((a) => a.name.toLowerCase().contains(lowerQuery))
            .toList();

        final users = _allUsers
            .where((u) =>
        (u.fullName.toLowerCase().contains(lowerQuery)) ||
            (u.email?.toLowerCase().contains(lowerQuery) ?? false))
            .toList();

        if (songs.isEmpty &&
            artists.isEmpty &&
            albums.isEmpty &&
            users.isEmpty) {
          return const Center(child: Text("Không tìm thấy kết quả"));
        }

        return ListView(
          children: [
            if (songs.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Bài hát",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...songs.map((s) => ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(s.title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen.single(song: s),
                    ),
                  );
                },
              )),
            ],
            if (artists.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Nghệ sĩ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...artists.map((a) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(a.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistOrUserScreen(
                        artistId: a.id,
                        isAdmin: false,
                      ),
                    ),
                  );
                },
              )),
            ],
            if (albums.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Album",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...albums.map((al) => ListTile(
                leading: const Icon(Icons.album),
                title: Text(al.title),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlbumScreen(albumId: al.id),
                    ),
                  );
                },
              )),
            ],
            if (users.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Người dùng",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...users.map((u) => ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(
                  u.fullName.isNotEmpty ? u.fullName : (u.email ?? 'Không tên'),
                ),
                subtitle: Text(u.email ?? ''),
                onTap: () {
                  final currentUser = _supabase.auth.currentUser;

                  // Nếu chưa đăng nhập, xem như user thường
                  final isCurrentUser = currentUser != null && currentUser.id == u.id;

                  if (_currentUserRole == 'admin' || isCurrentUser) {
                    // 🔹 Admin hoặc người dùng đang xem chính mình → mở ProfileScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: u.id),
                      ),
                    );
                  } else {
                    // 🔹 User thường xem người khác → mở ArtistOrUserScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistOrUserScreen(userId: u.id),
                      ),
                    );
                  }
                },
              )),
            ],
          ],
        );
      },
    );
  }
}
