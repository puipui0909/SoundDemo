import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/artist.dart';
import '../../service/artist_service.dart';

class EditArtistDialog extends StatefulWidget {
  final Artist? artist; // null nếu thêm mới

  const EditArtistDialog({super.key, this.artist});

  bool get isNew => artist == null;

  @override
  State<EditArtistDialog> createState() => _EditArtistDialogState();
}

class _EditArtistDialogState extends State<EditArtistDialog> {
  final _artistService = ArtistService();
  final _nameController = TextEditingController();
  File? _newImageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.artist?.name ?? '';
  }

  /// Chọn ảnh mới từ thư viện
  Future<void> _pickNewImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImageFile = File(picked.path);
      });
    }
  }

  /// Lưu/thêm artist
  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tên không được để trống')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isNew) {
        // 🔹 Thêm mới artist
        await _artistService.addArtist(name: newName, imageFile: _newImageFile);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm nghệ sĩ')));
        }
      } else {
        // 🔹 Cập nhật artist
        final updatedArtist = widget.artist!.copyWith(name: newName);
        await _artistService.updateArtist(updatedArtist, newImageFile: _newImageFile);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cập nhật nghệ sĩ thành công')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isNew ? 'Thêm nghệ sĩ' : 'Chỉnh sửa nghệ sĩ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          GestureDetector(
            onTap: _pickNewImage,
            child: CircleAvatar(
              radius: 45,
              backgroundImage: _newImageFile != null
                  ? FileImage(_newImageFile!)
                  : (widget.artist?.avatarUrl.isNotEmpty ?? false
                  ? NetworkImage(widget.artist!.avatarUrl)
                  : const AssetImage('assets/placeholder.jpg'))
              as ImageProvider,
              child: const Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.camera_alt, size: 22, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tên nghệ sĩ
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên nghệ sĩ'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          child: _isSaving
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(widget.isNew ? 'Thêm' : 'Lưu'),
        ),
      ],
    );
  }
}
