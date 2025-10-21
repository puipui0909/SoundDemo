import 'package:flutter/material.dart';
import '../models/song.dart';
import '../service/liked_songs_service.dart';

class LikeButton extends StatelessWidget {
  final Song song;
  const LikeButton({Key? key, required this.song}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = LikedSongService.instance;
    final user = service.currentUser;

    if (user == null) {
      return const Icon(Icons.favorite_border, color: Colors.grey);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.likeStreamForSong(song.id, user.id),
      builder: (context, snapshot) {
        final isLiked = (snapshot.data ?? []).isNotEmpty;

        return IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isLiked),
              color: isLiked ? Colors.redAccent : Colors.grey,
            ),
          ),
          onPressed: () async {
            if (isLiked) {
              await service.unlikeSong(song.id);
            } else {
              await service.likeSong(song);
            }
          },
        );
      },
    );
  }
}
