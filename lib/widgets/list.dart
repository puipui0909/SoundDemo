import 'package:flutter/material.dart';

class ListWidget<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) getTitle;       // cách lấy title
  final String? Function(T) getCoverUrl;   // cách lấy ảnh
  final void Function(BuildContext, T) onTap; // xử lý khi click
  final List<Widget> Function(BuildContext, T)? actionsBuilder;

  const ListWidget({
    super.key,
    required this.items,
    required this.getTitle,
    required this.getCoverUrl,
    required this.onTap,
    this.actionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final coverUrl = getCoverUrl(item);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              coverUrl ?? "",
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(Icons.music_note),
              ),
            ),
          ),
          title: Text(
            getTitle(item),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => onTap(context, item),
          trailing: actionsBuilder != null
              ? Row(
            mainAxisSize: MainAxisSize.min,
            children: actionsBuilder!(context, item),
          )
              : null,
        );
      },
    );
  }
}
