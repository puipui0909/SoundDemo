import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spotify_clone/Screens/main_page/upload/upload_screen.dart';
import 'package:spotify_clone/widgets/custom_appbar.dart';
import 'package:spotify_clone/models/song.dart';
import 'package:spotify_clone/widgets/list.dart';
import '../../features/search/my_search_delegate.dart';
import 'package:spotify_clone/models/user.dart';
import '../../models/album.dart';
import '../../service/user_service.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/edit_dialog/edit_album_dialog.dart';
import '../../widgets/edit_dialog/edit_song_dialog.dart';
import '../album_screen.dart';
import '../player_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserService _service = UserService();
  final String? userId;
  final bool isAdmin;

  ProfileScreen({
    super.key,
    this.userId,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final idToShow = userId ?? currentUser?.id;

    if (idToShow == null) {
      return const Scaffold(
        body: Center(child: Text("Không thể xác định người dùng.")),
      );
    }

    final isCurrentUser = (currentUser?.id == idToShow);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: isCurrentUser ? 'MY PROFILE' : 'PROFILE',
          action: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: MySearchDelegate());
            },
          ),
        ),
        body: Column(
          children: [
            StreamBuilder<AppUser?>(
              stream: _service.streamUserById(idToShow),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                final user = snapshot.data;
                if (user == null) {
                  return const Center(
                    child: Text("Không tìm thấy thông tin người dùng."),
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(
                            user.initials,
                            style: const TextStyle(fontSize: 32),
                          )
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (isCurrentUser || isAdmin)
                              TextButton.icon(
                                onPressed: () async {
                                  final nameController =
                                  TextEditingController(text: user.fullName);
                                  File? selectedImage;

                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            title:
                                            const Text("Chỉnh sửa thông tin"),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final picker = ImagePicker();
                                                      final pickedFile =
                                                      await picker.pickImage(
                                                        source:
                                                        ImageSource.gallery,
                                                        imageQuality: 75,
                                                      );
                                                      if (pickedFile != null) {
                                                        setState(() {
                                                          selectedImage = File(
                                                              pickedFile.path);
                                                        });
                                                      }
                                                    },
                                                    child: CircleAvatar(
                                                      radius: 40,
                                                      backgroundImage:
                                                      selectedImage != null
                                                          ? FileImage(
                                                          selectedImage!)
                                                          : (user.avatarUrl !=
                                                          null
                                                          ? NetworkImage(
                                                          user.avatarUrl!)
                                                          : null)
                                                      as ImageProvider?,
                                                      child: (selectedImage ==
                                                          null &&
                                                          user.avatarUrl ==
                                                              null)
                                                          ? const Icon(
                                                          Icons.add_a_photo,
                                                          size: 32)
                                                          : null,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  TextField(
                                                    controller: nameController,
                                                    decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                      "Tên hiển thị mới",
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text("Hủy"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final newName =
                                                  nameController.text.trim();

                                                  if (newName.isNotEmpty) {
                                                    await _service
                                                        .updateUserFullName(
                                                        user.id, newName);
                                                  }

                                                  if (selectedImage != null) {
                                                    await _service
                                                        .updateUserAvatar(
                                                        user.id,
                                                        selectedImage!);
                                                  }

                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          "Đã cập nhật thông tin người dùng!"),
                                                    ),
                                                  );
                                                },
                                                child: const Text("Lưu"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text("Chỉnh sửa"),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Vai trò: ${user.role}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),

            const TabBar(
              tabs: [
                Tab(text: 'Songs'),
                Tab(text: 'Albums'),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  SongsTab(
                      userId: idToShow,
                      isCurrentUser: isCurrentUser,
                      isAdmin: isAdmin),
                  AlbumsTab(
                      userId: idToShow,
                      isCurrentUser: isCurrentUser,
                      isAdmin: isAdmin),
                ],
              ),
            ),
          ],
        ),

        floatingActionButton: (isCurrentUser || isAdmin)
            ? FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const UploadScreen()),
            );
          },
          child: const Icon(Icons.add),
        )
            : null,
      ),
    );
  }
}

// ----------------------------------------------------------------------

class SongsTab extends StatelessWidget {
  final supabase = Supabase.instance.client;
  final String userId;
  final bool isCurrentUser;
  final bool isAdmin;

  SongsTab({
    super.key,
    required this.userId,
    required this.isCurrentUser,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Song>>(
      stream: supabase
          .from('songs')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((rows) {
        final list = rows.map((row) => Song.fromMap(row)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final songs = snapshot.data ?? [];
        if (songs.isEmpty) {
          return const Center(child: Text("Chưa có bài hát nào"));
        }

        return ListWidget<Song>(
          items: songs,
          getTitle: (song) => song.title,
          getCoverUrl: (song) => song.coverUrl,
          onTap: (context, song) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen.single(song: song),
              ),
            );
          },
          actionsBuilder: (context, song) {
            if (!(isCurrentUser || isAdmin)) return [];
            return [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  final updated = await showDialog<bool>(
                    context: context,
                    builder: (context) => EditSongDialog(song: song),
                  );
                  if (updated == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Đã cập nhật ${song.title}")),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        ConfirmDeleteDialog(itemName: song.title),
                  );
                  if (confirm == true) {
                    await supabase.from('songs').delete().eq('id', song.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Đã xoá '${song.title}'")),
                    );
                  }
                },
              ),
            ];
          },
        );
      },
    );
  }
}

// ----------------------------------------------------------------------

class AlbumsTab extends StatelessWidget {
  final supabase = Supabase.instance.client;
  final String userId;
  final bool isCurrentUser;
  final bool isAdmin;

  AlbumsTab({
    super.key,
    required this.userId,
    required this.isCurrentUser,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Album>>(
      stream: supabase
          .from('albums')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .map((rows) => rows.map((row) => Album.fromMap(row)).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final albums = snapshot.data ?? [];
        if (albums.isEmpty) {
          return const Center(child: Text("Chưa có album nào"));
        }

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
          actionsBuilder: (context, album) {
            if (!(isCurrentUser || isAdmin)) return [];
            return [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () async {
                  final updated = await showDialog<bool>(
                    context: context,
                    builder: (_) => EditAlbumDialog(album: album),
                  );
                  if (updated == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Đã cập nhật album '${album.title}'")),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        ConfirmDeleteDialog(itemName: album.title),
                  );
                  if (confirm == true) {
                    await supabase.from('albums').delete().eq('id', album.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Đã xoá album '${album.title}'")),
                    );
                  }
                },
              ),
            ];
          },
        );
      },
    );
  }
}
