import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
import 'package:spotify_clone/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../widgets/like_button.dart';

import 'package:spotify_clone/main.dart';
import 'package:audio_service/audio_service.dart';
import '../service/audio_handler.dart';

class PlayerScreen extends StatefulWidget {
  final List<Song> playlist;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.playlist,
    required this.initialIndex,
  });

  factory PlayerScreen.single({
    Key? key,
    required Song song,
  }) {
    return PlayerScreen(
      key: key,
      playlist: [song],
      initialIndex: 0,
    );
  }

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final supabase = Supabase.instance.client;
  AppUser? _currentUser;

  // Lấy Index từ AudioHandler
  int get currentIndex => audioHandler.playbackState.value.queueIndex ?? 0;

  // Lấy bài hát hiện tại
  Song? get currentSong {
    // Lấy chỉ mục từ AudioHandler
    final index = audioHandler.playbackState.value.queueIndex;

    // Kiểm tra tính hợp lệ
    if (index != null && index >= 0 && index < widget.playlist.length) {
      return widget.playlist[index];
    }

    // Trả về null nếu không có index hợp lệ hoặc playlist rỗng
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initPlaylist();
    _loadUser();
  }

  Future<void>_loadUser() async{
    final currentuser = await AppUser.fetchCurrentUser();
    setState(() => _currentUser = currentuser   );
  }

  Future<void> _initPlaylist() async {
    // 1. Chuyển đổi Playlist sang MediaItem
    final mediaItems = widget.playlist
        .map((s) => MediaItem(
      id: s.audioUrl!,
      title: s.title,
      artist: s.artistId,
      album: 'Spotify Clone',
      artUri: Uri.parse(s.coverUrl ?? ''),
      duration: s.duration != null
          ? Duration(milliseconds: s.duration! * 1000)
          : null,
    ))
        .toList();

    // 2. Gọi hàm khởi tạo Playlist trong AudioHandler
    // Ép kiểu thành AudioPlayerHandler để gọi initAndPlayPlaylist
    if (audioHandler is AudioPlayerHandler) {
      await (audioHandler as AudioPlayerHandler).initAndPlayPlaylist(
        mediaItems: mediaItems,
        initialIndex: widget.initialIndex,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      rxdart.Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        // Lấy vị trí từ PlaybackState (được cập nhật thường xuyên)
        audioHandler.playbackState.map((state) => state.updatePosition),
        // Lấy vị trí buffered từ PlaybackState
        audioHandler.playbackState.map((state) => state.bufferedPosition),
        // Lấy duration từ MediaItem (cập nhật khi bài hát chuyển)
        audioHandler.mediaItem.map((item) => item?.duration),
            (position, buffered, duration) {
              // SỬ DỤNG DURATION TỪ MEDIAITEM (Đã được cập nhật từ just_audio)
              // Nếu duration từ MediaItem là null, dùng duration từ database (đã nhân 1000)
              final finalDuration = duration ?? (currentSong?.duration != null
                ? Duration(milliseconds: currentSong!.duration! * 1000)
                : Duration.zero);

              return PositionData(position, buffered, finalDuration);
            },
      );

  Future<Artist?> _fetchArtist(String artistId) async {
    final response = await supabase
        .from('artists')
        .select()
        .eq('id', artistId)
        .maybeSingle();
    if (response == null) return null;
    return Artist.fromMap(response);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: audioHandler.playbackState.map((state) => state.queueIndex).distinct(),
      builder: (context, snapshot) {

        final song = currentSong;

        if (song == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              backgroundColor: Colors.transparent,
              title: const Text("Now Playing"),
              centerTitle: true,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text("Loading music...", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
            backgroundColor: Colors.transparent,
            title: const Text("Now Playing"),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                /// Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    song.coverUrl ?? "",
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 300,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note, size: 100),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                /// Title + Artist + Like
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<Artist?>(
                            future: _fetchArtist(song.artistId!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text("Loading artist...");
                              }
                              if (snapshot.hasError || snapshot.data == null) {
                                return const Text("Unknown Artist");
                              }
                              return Text(
                                snapshot.data!.name,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    LikeButton(song: song),
                  ],
                ),
                const SizedBox(height: 32),

                /// Progress bar
                StreamBuilder<PositionData>(
                  stream: _positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;
                    final duration = positionData?.duration.inMilliseconds.toDouble() ?? 1.0;
                    final position = positionData?.position.inMilliseconds.toDouble() ?? 0.0;
                    final safeValue = position.clamp(0.0, duration);

                    return Column(
                      children: [
                        Slider(
                          activeColor: Colors.green,
                          inactiveColor: Colors.grey,
                          min: 0.0,
                          max: duration > 0 ? duration : 1.0,
                          value: safeValue,
                          onChanged: (_) {},
                          onChangeEnd: (value) {
                            audioHandler.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(
                                  positionData?.position ?? Duration.zero),
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              _formatDuration(
                                  positionData?.duration ?? Duration.zero),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                /// Controls
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState, // Lắng nghe PlaybackState
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    final playing = state?.playing ?? false;

                    // Kiểm tra Controls có sẵn (Skip Next/Previous)
                    final hasPrevious = state?.controls.contains(MediaControl.skipToPrevious) ?? false;
                    final hasNext = state?.controls.contains(MediaControl.skipToNext) ?? false;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //nút pre
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 36),
                          onPressed: hasPrevious ? audioHandler.skipToPrevious : null, // Gọi AudioHandler
                        ),

                        //nút play
                        if (playing)
                          IconButton(
                            icon: const Icon(Icons.pause_circle_filled, size: 64),
                            onPressed: audioHandler.pause, // Gọi AudioHandler
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill, size: 64),
                            onPressed: audioHandler.play, // Gọi AudioHandler
                          ),

                        // Nút Skip Next
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 36),
                          onPressed: hasNext ? audioHandler.skipToNext : null, // Gọi AudioHandler
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  PositionData(this.position, this.bufferedPosition, this.duration);
}
