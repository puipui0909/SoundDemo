import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart' as rxdart;

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer(); // <-- Sử dụng JustAudioPlayer

  final _playlist = ConcatenatingAudioSource(children: []);

  AudioPlayerHandler() {
    // 1. Khởi tạo Playlist rỗng cho Just Audio
    _player.setAudioSource(_playlist);

    // 2. Lắng nghe thay đổi trạng thái của Just Audio Player
    _listenForPlayerStateChanges();
    _listenForSequenceStateChanges(); // Nghe thay đổi bài hát hiện tại
    _listenForDurationChanges(); // Nghe thay đổi duration

    _player.setAudioSource(_playlist).then((_) {
      // Sau khi set source xong, bắt đầu lắng nghe vị trí
      _listenForPositionChanges();
    });
  }

  // Phương thức thiết lập và bắt đầu phát Playlist
  Future<void> initAndPlayPlaylist({
    required List<MediaItem> mediaItems,
    required int initialIndex,
  }) async {
    await _player.stop();

    final audioSources = mediaItems
        .map((item) => AudioSource.uri(Uri.parse(item.id), tag: item))
        .toList();

    // 1. Cập nhật Queue cho AudioService (để hiển thị Notification)
    queue.add(mediaItems);

    // 2. Cập nhật Playlist cho Just Audio
    await _playlist.clear();
    await _playlist.addAll(audioSources);

    // 3. Bắt đầu phát từ index được chỉ định
    await _player.setAudioSource(
      _playlist,
      initialIndex: initialIndex,
      initialPosition: Duration.zero,
    );

    await _player.play();
  }

  // 2. Định nghĩa các hàm xử lý lệnh (Overrides)
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    // Bắt buộc phải dừng handler để gỡ bỏ notification
    await super.stop();
  }

  // Xử lý nút Skip Next
  @override
  Future<void> skipToNext() => _player.seekToNext();

  // Xử lý nút Skip Previous
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  // Xử lý việc di chuyển đến một Index cụ thể trong Queue
  @override
  Future<void> skipToQueueIndex(int index) =>
      _player.seek(Duration.zero, index: index);

  // Xử lý Seek (di chuyển thanh trượt)
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // Lắng nghe trạng thái phát (Play/Pause/Buffering/Completed)
  void _listenForPlayerStateChanges() {
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = _getAudioServiceProcessingState(
          playerState.processingState);

      _updatePlaybackState(
        processingState: processingState,
        isPlaying: isPlaying,
      );
    });
  }

  // Lắng nghe thay đổi bài hát hiện tại
  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((sequenceState) {
      final currentItem = sequenceState?.currentSource?.tag as MediaItem?;
      if (currentItem != null) {
        mediaItem.add(currentItem); // Cập nhật MediaItem hiện tại
      }
      // Cần gọi lại _updatePlaybackState để cập nhật vị trí trong queue
      _updatePlaybackState();
    });
  }

  // Lắng nghe duration để cập nhật mediaItem.duration
  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem != null && duration != null) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });
  }

  // Hàm helper để chuẩn hóa việc cập nhật playbackState
  void _updatePlaybackState({
    AudioProcessingState? processingState,
    bool? isPlaying,
  }) {
    // Xác định các controls (Next/Previous)
    final controls = <MediaControl>[
      if (_player.hasPrevious) MediaControl.skipToPrevious,
      if (isPlaying ?? _player.playing) MediaControl.pause else
        MediaControl.play,
      if (_player.hasNext) MediaControl.skipToNext,
      MediaControl.stop,
    ];

    // Xác định các SystemActions
    final systemActions = {
      MediaAction.seek,
      if (_player.hasPrevious) MediaAction.skipToPrevious,
      if (_player.hasNext) MediaAction.skipToNext,
    };
    playbackState.add(playbackState.value.copyWith(
      controls: controls,
      systemActions: systemActions,
      androidCompactActionIndices: const [0, 1, 2],
      // Prev, Play/Pause, Next
      processingState: processingState ??
          _getAudioServiceProcessingState(_player.processingState),
      playing: isPlaying ?? _player.playing,
      // updatePosition: _player.position,
      // bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex, // Rất quan trọng cho playlist
    ));
  }

  void _listenForPositionChanges() {
    rxdart.Rx.combineLatest2<Duration, Duration, void>(
      _player.positionStream.whereType<Duration>(), // Lắng nghe vị trí
      _player.bufferedPositionStream.whereType<Duration>(), // Lắng nghe đệm
          (position, bufferedPosition) {
        // Cập nhật PlaybackState liên tục (đảm bảo Slider chạy mượt)
        playbackState.add(playbackState.value.copyWith(
          updatePosition: position,
          bufferedPosition: bufferedPosition,
        ));
        return null; // Trả về void (không cần giá trị)
      },
    ).listen((_) {});
  }
}

// Hàm chuyển đổi trạng thái của JustAudio sang AudioService
AudioProcessingState _getAudioServiceProcessingState(ProcessingState state) {
  switch (state) {
    case ProcessingState.idle:
      return AudioProcessingState.idle;
    case ProcessingState.loading:
      return AudioProcessingState.loading;
    case ProcessingState.buffering:
      return AudioProcessingState.buffering;
    case ProcessingState.ready:
      return AudioProcessingState.ready;
    case ProcessingState.completed:
      return AudioProcessingState.completed;
    default:
      return AudioProcessingState.idle;
  }
}