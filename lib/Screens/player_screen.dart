import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
import 'package:spotify_clone/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../widgets/like_button.dart';

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
  late AudioPlayer _player;
  late ConcatenatingAudioSource _playlist;
  final supabase = Supabase.instance.client;

  int get currentIndex => _player.currentIndex ?? 0;
  Song get currentSong => widget.playlist[currentIndex];
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlaylist();
    _loadUser();
  }

  Future<void>_loadUser() async{
    final currentuser = await AppUser.fetchCurrentUser();
    setState(() => _currentUser = currentuser   );
  }

  Future<void> _initPlaylist() async {
    _playlist = ConcatenatingAudioSource(
      children: widget.playlist
          .map((s) => AudioSource.uri(Uri.parse(s.audioUrl!)))
          .toList(),
    );

    await _player.setAudioSource(
      _playlist,
      initialIndex: widget.initialIndex,
      preload: true,
    );

    // 🔧 Đợi player load xong rồi mới play
    _player.processingStateStream.firstWhere(
          (state) => state == ProcessingState.ready,
    ).then((_) async {
      await Future.delayed(const Duration(milliseconds: 200));
      _player.play();
    });

    // Xử lý khi hết bài
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (currentIndex < widget.playlist.length - 1) {
          _player.seekToNext();
        } else {
          _player.seek(Duration.zero);
          _player.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      rxdart.Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
            (position, buffered, duration) =>
            PositionData(position, buffered, duration ?? Duration.zero),
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
      stream: _player.currentIndexStream,
      builder: (context, snapshot) {
        final song = currentSong;

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
                    final duration =
                        positionData?.duration.inMilliseconds.toDouble() ?? 1.0;
                    final position =
                        positionData?.position.inMilliseconds.toDouble() ?? 0.0;
                    final safeValue = position.clamp(0.0, duration);

                    return Column(
                      children: [
                        Slider(
                          activeColor: Colors.green,
                          inactiveColor: Colors.grey,
                          min: 0.0,
                          max: duration > 0 ? duration : 1.0,
                          value: safeValue,
                          onChanged: (value) {
                            _player
                                .seek(Duration(milliseconds: value.toInt()));
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      onPressed:
                      _player.hasPrevious ? _player.seekToPrevious : null,
                    ),
                    StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;
                        if (playing) {
                          return IconButton(
                            icon:
                            const Icon(Icons.pause_circle_filled, size: 64),
                            onPressed: () => _player.pause(),
                          );
                        } else {
                          return IconButton(
                            icon:
                            const Icon(Icons.play_circle_fill, size: 64),
                            onPressed: () => _player.play(),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      onPressed:
                      _player.hasNext ? _player.seekToNext : null,
                    ),
                  ],
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
