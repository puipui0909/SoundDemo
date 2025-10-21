import 'package:flutter/material.dart';
import '../models/interface/has_title_and_image.dart';
import '../models/artist.dart';
import '../models/user.dart';

class CoverAppbar extends StatelessWidget {
  final dynamic item; // có thể là Artist, AppUser, hoặc HasTitleAndImage

  const CoverAppbar({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    String title = '';
    String imageUrl = '';

    // 🔹 Xác định kiểu dữ liệu
    if (item is HasTitleAndImage) {
      title = (item as HasTitleAndImage).displayTitle;
      imageUrl = (item as HasTitleAndImage).displayImageUrl;
    } else if (item is Artist) {
      title = item.name;
      imageUrl = item.imageUrl ?? '';
    } else if (item is AppUser) {
      title = item.fullName.isNotEmpty ? item.fullName : (item.email ?? 'User');
      imageUrl =
      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(title)}';
    } else {
      title = 'Không xác định';
      imageUrl = '';
    }

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          var top = constraints.biggest.height;
          return FlexibleSpaceBar(
            title: top <= kToolbarHeight + 50
                ? Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
            background: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: Image.network(
                    imageUrl.isNotEmpty
                        ? imageUrl
                        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(title)}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 120,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (top > kToolbarHeight + 50)
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 37,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black54,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
