import 'package:flutter/material.dart';

class AdminActionButtons extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? deleteConfirmTitle;
  final String? deleteConfirmMessage;

  const AdminActionButtons({
    super.key,
    this.onEdit,
    this.onDelete,
    this.deleteConfirmTitle,
    this.deleteConfirmMessage,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    if (onDelete == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(deleteConfirmTitle ?? 'Xác nhận xóa'),
        content: Text(deleteConfirmMessage ?? 'Bạn có chắc muốn xóa mục này không?'),
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
      onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu không có nút nào thì không hiển thị gì cả
    if (onEdit == null && onDelete == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: onEdit,
            tooltip: 'Sửa',
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Xóa',
          ),
      ],
    );
  }
}
