import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:spotify_clone/main.dart';


class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key});

  // Chiều cao cố định của Mini-Player (quan trọng cho padding)
  static const double miniPlayerHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    // 1. Lắng nghe MediaItem hiện tại (bài hát đang phát)
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;

        // Nếu không có bài hát nào (mediaItem là null), không hiển thị mini-player
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        // Nếu có bài hát, xây dựng giao diện mini-player
        return Container(
          height: miniPlayerHeight,
          // Sử dụng màu nền tối, có thể làm mờ để người dùng nhận biết
          color: Colors.black.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // 1. Ảnh/Icon bài hát
              _buildThumbnail(mediaItem),
              const SizedBox(width: 10),

              // 2. Tên Bài Hát & Nghệ Sĩ
              Expanded(
                child: _buildTitleAndArtist(mediaItem),
              ),

              // 3. Nút Play/Pause
              StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playbackState = snapshot.data;
                  final processingState = playbackState?.processingState;
                  final isPlaying = playbackState?.playing ?? false;

                  // Hiển thị loading nếu đang tải/buffering
                  if (processingState == AudioProcessingState.loading ||
                      processingState == AudioProcessingState.buffering) {
                    return const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  // Hiển thị nút Play/Pause
                  return IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                      size: 35,
                    ),
                    onPressed: isPlaying ? audioHandler.pause : audioHandler.play,
                  );
                },
              ),

              // 4. Nút Next (Tùy chọn)
              _buildSkipNextButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(MediaItem item) {
    // Sử dụng artUri nếu có
    if (item.artUri != null) {
      // Trong ứng dụng thực tế, bạn sẽ dùng CachedNetworkImage
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(item.artUri!.toString()),
      );
    }
    // Icon mặc định
    return const Icon(Icons.music_note, color: Colors.white, size: 30);
  }

  Widget _buildTitleAndArtist(MediaItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          item.artist ?? 'Unknown Artist',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSkipNextButton() {
    return IconButton(
      icon: const Icon(
        Icons.skip_next,
        color: Colors.white,
        size: 35,
      ),
      onPressed: AudioService.skipToNext,
    );
  }
}