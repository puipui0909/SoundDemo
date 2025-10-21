import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String itemName; // tên hiển thị trong dialog (vd: tên bài hát, album)
  final String? title;   // tiêu đề dialog (có thể null => mặc định "Xoá")
  final String? message; // nội dung dialog (nếu muốn custom)

  const ConfirmDeleteDialog({
    super.key,
    required this.itemName,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? "Xoá"),
      content: Text(
        message ?? "Bạn có chắc muốn xoá '$itemName'?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Huỷ"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Xoá"),
        ),
      ],
    );
  }
}
