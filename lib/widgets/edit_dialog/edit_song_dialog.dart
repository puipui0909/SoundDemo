import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/song.dart';

class EditSongDialog extends StatefulWidget {
  final Song song;

  const EditSongDialog({super.key, required this.song});

  @override
  State<EditSongDialog> createState() => _EditSongDialogState();
}

class _EditSongDialogState extends State<EditSongDialog> {
  final supabase = Supabase.instance.client;

  late TextEditingController _titleController;
  late TextEditingController _coverUrlController;
  String? _selectedAlbumId;

  bool _isSaving = false;


  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _coverUrlController = TextEditingController(text: widget.song.coverUrl);
    _selectedAlbumId = widget.song.albumId; // null = đĩa đơn
  }

  @override
  void dispose() {
    _titleController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  /// Chọn và upload ảnh bìa lên Supabase Storage
  /// Chọn và upload ảnh bìa lên Supabase Storage
  Future<void> _pickCoverFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return; // Người dùng hủy

    final file = File(picked.path);
    final fileName =
        "images/covers/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";

    try {
      // ✅ Upload (cho phép ghi đè nếu trùng)
      await supabase.storage
          .from("media")
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));

      // ✅ Lấy public URL
      final publicUrl = supabase.storage.from("media").getPublicUrl(fileName);

      setState(() {
        _coverUrlController.text = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tải ảnh bìa thành công!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi upload ảnh bìa: $e")),
      );
    }
  }

  /// 💾 Lưu thay đổi vào Supabase
  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tên bài hát không được để trống")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await supabase.from('songs').update({
        'title': _titleController.text.trim(),
        'cover_url': _coverUrlController.text.trim(),
        'album_id': _selectedAlbumId?.isEmpty == true ? null : _selectedAlbumId,
      }).eq('id', widget.song.id);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi cập nhật: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Chỉnh sửa bài hát"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 📝 Tên bài hát
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Tên bài hát"),
            ),

            const SizedBox(height: 12),

            // 🖼️ Ảnh bìa
            TextField(
              controller: _coverUrlController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Ảnh bìa",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickCoverFile,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🎵 Dropdown Album
            FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase.from('albums').select(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Lỗi tải albums: ${snapshot.error}");
                }
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final albums = snapshot.data!;
                if (albums.isEmpty) {
                  return const Text("Chưa có album nào");
                }

                return DropdownButtonFormField<String>(
                  value: _selectedAlbumId ?? "",
                  decoration: const InputDecoration(labelText: "Album"),
                  items: [
                    const DropdownMenuItem(
                      value: "",
                      child: Text("Đĩa đơn"),
                    ),
                    ...albums.map((album) => DropdownMenuItem(
                      value: album['id'].toString(),
                      child: Text(album['title']),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedAlbumId = (val == "" ? null : val);
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),

      // 🧭 Nút hành động
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          child: _isSaving
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Lưu"),
        ),
      ],
    );
  }
}
