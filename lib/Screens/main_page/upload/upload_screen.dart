import 'package:flutter/material.dart';
import 'package:spotify_clone/Screens/main_page/upload/upload_album.dart';
import 'package:spotify_clone/Screens/main_page/upload/upload_song.dart';

class UploadScreen extends StatefulWidget {
  final String? artistId;
  const UploadScreen({Key? key, this.artistId}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm mới"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Bài hát", icon: Icon(Icons.music_note)),
            Tab(text: "Album", icon: Icon(Icons.album)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          UploadSongForm(artistId: widget.artistId),
          UploadAlbumForm(artistId: widget.artistId),
        ],
      ),

    );
  }
}

