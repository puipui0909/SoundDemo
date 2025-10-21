import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotify_clone/service/album_service.dart';
import '../../../service/song_service.dart';

class UploadSongForm extends StatefulWidget {
  final String? artistId;

  const UploadSongForm({Key? key, this.artistId}) : super(key: key);

  @override
  State<UploadSongForm> createState() => _UploadSongFormState();
}

class _UploadSongFormState extends State<UploadSongForm> {
  final TextEditingController _titleController = TextEditingController();
  File? _audioFile;
  File? _coverFile;
  String? _albumId;
  String? _artistId;
  int? _duration;

  final SongService _songService = SongService();
  final AlbumService _albumService = AlbumService();

  List<Map<String, dynamic>> _albums = [];

  @override
  void initState() {
    super.initState();
    _artistId = widget.artistId;
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      List<Map<String, dynamic>> albums = [];

      if (_artistId != null && _artistId!.isNotEmpty) {
        // 🔹 Nếu form được truyền artistId (admin đang thêm cho artist cụ thể)
        albums = await _albumService.getAlbumsByArtistId(_artistId!);
      } else {
        // 🔹 Nếu là người dùng tự upload bài hát
        albums = await _albumService.getUserAlbums();
      }

      setState(() {
        _albums = albums;
        _albumId = _albums.isNotEmpty ? _albums.first['id'].toString() : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Không load được albums: $e")),
        );
      }
    }
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() => _audioFile = file);

      // Lấy duration bằng just_audio
      final player = AudioPlayer();
      await player.setFilePath(file.path);
      setState(() => _duration = player.duration?.inSeconds ?? 0);
      await player.dispose();
    }
  }

  Future<void> _pickCoverFile() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _coverFile = File(picked.path);
      });
    }
  }

  Future<void> _uploadSong() async {
    if (_titleController.text.isEmpty || _audioFile == null || _duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }

    try {
      await _songService.uploadSong(
        title: _titleController.text,
        audioFile: _audioFile!,
        coverFile: _coverFile,
        albumId: _albumId ?? '',
        artistId: _artistId ?? '',
        duration: _duration!,
      );

      if (!mounted) return;

      // Hiện thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload thành công!")),
      );

      // 🔹 Quay lại trang Profile
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Tên bài hát"),
          ),
          const SizedBox(height: 10),

          // Chọn file nhạc
          TextField(
            controller: TextEditingController(
              text: _audioFile != null ? _audioFile!.path.split('/').last : "",
            ),
            readOnly: true,
            decoration: InputDecoration(
              labelText: "File nhạc",
              suffixIcon: IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _pickAudioFile,
              ),
            ),
          ),
          if (_duration != null) Text("Duration: $_duration giây"),

          const SizedBox(height: 10),

// Chọn ảnh bìa
          TextField(
            controller: TextEditingController(
              text: _coverFile != null ? _coverFile!.path.split('/').last : "",
            ),
            readOnly: true,
            decoration: InputDecoration(
              labelText: "Ảnh bìa",
              suffixIcon: IconButton(
                icon: const Icon(Icons.image),
                onPressed: _pickCoverFile,
              ),
            ),
          ),


          const SizedBox(height: 20),

          // Dropdown chọn album
          DropdownButtonFormField<String>(
            value: _albumId,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text("Đĩa đơn"),
              ),
              ..._albums.map((album) => DropdownMenuItem(
                value: album['id'].toString(),
                child: Text(album['title']),
              )),
            ],
            onChanged: (val) {
              setState(() => _albumId = val);
            },
            decoration: const InputDecoration(labelText: "Chọn album"),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: _uploadSong,
            child: const Text("Upload Bài Hát"),
          ),
        ],
      ),
    );
  }
}
