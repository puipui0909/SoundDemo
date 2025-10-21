import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../service/album_service.dart';

class UploadAlbumForm extends StatefulWidget {
  final String? artistId; // ✅ thêm thuộc tính artistId

  const UploadAlbumForm({Key? key, this.artistId}) : super(key: key);

  @override
  State<UploadAlbumForm> createState() => _UploadAlbumFormState();
}

class _UploadAlbumFormState extends State<UploadAlbumForm> {
  final _titleController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  final _albumService = AlbumService();

  /// Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  /// Upload album
  Future<void> _uploadAlbum() async {
    if (_titleController.text.trim().isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hãy nhập tên và chọn ảnh bìa")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _albumService.uploadAlbum(
        title: _titleController.text.trim(),
        coverImage: _selectedImage!,
        artistId: widget.artistId, // ✅ truyền xuống service
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Album đã được upload")),
      );

      // reset form
      _titleController.clear();
      setState(() => _selectedImage = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi upload: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Tên album"),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
                : Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey,
                  width: 1.5,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    "Chọn ảnh bìa album",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadAlbum,
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Upload Album"),
          ),
        ],
      ),
    );
  }
}
