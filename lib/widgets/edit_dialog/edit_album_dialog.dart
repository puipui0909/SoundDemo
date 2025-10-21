import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/album.dart';

class EditAlbumDialog extends StatefulWidget {
  final Album album;

  const EditAlbumDialog({super.key, required this.album});

  @override
  State<EditAlbumDialog> createState() => _EditAlbumDialogState();
}

class _EditAlbumDialogState extends State<EditAlbumDialog> {
  final supabase = Supabase.instance.client;

  late TextEditingController _titleController;
  late TextEditingController _coverUrlController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.album.title);
    _coverUrlController = TextEditingController(text: widget.album.coverUrl);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      try {
        final fileName =
            "images/albums/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";

        // upload lên bucket "media"
        await supabase.storage.from("media").upload(fileName, file);

        // lấy public url
        final publicUrl = supabase.storage.from("media").getPublicUrl(fileName);

        setState(() {
          _coverUrlController.text = publicUrl;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi upload ảnh bìa: $e")),
          );
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      await supabase.from('albums').update({
        'title': _titleController.text,
        'cover_url': _coverUrlController.text,
      }).eq('id', widget.album.id);

      if (mounted) {
        Navigator.pop(context, true); // trả về true nếu có thay đổi
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi cập nhật album: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Chỉnh sửa album"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Tên album"),
            ),
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
          ],
        ),
      ),
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
