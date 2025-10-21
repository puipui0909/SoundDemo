class Song {
  final String id;
  final String title;
  final String artistId;
  final int likeCount;
  final String audioUrl;
  final String albumId;
  final DateTime createdAt;
  final String coverUrl;
  final String userId;
  final int duration;

  Song({
    required this.id,
    required this.title,
    required this.artistId,
    required this.likeCount,
    required this.audioUrl,
    required this.albumId,
    required this.createdAt,
    required this.coverUrl,
    required this.userId,
    required this.duration,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artistId: map['artist_id'] as String? ?? '',
      likeCount: (map['like_count'] ?? 0) as int,
      audioUrl: map['audio_url'] as String,
      albumId: map['album_id'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      coverUrl: map['cover_url'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      duration: (map['duration'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist_id': artistId,
      'like_count': likeCount,
      'audio_url': audioUrl,
      'album_id': albumId,
      'created_at': createdAt.toIso8601String(),
      'cover_url': coverUrl,
      'user_id': userId,
      'duration': duration,
    };
  }
  Song copyWith({
    String? id,
    String? title,
    String? artistId,
    String? albumId,
    String? audioUrl,
    String? coverUrl,
    int? duration,
    int? likeCount,
    String? userId,
    DateTime? createdAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      duration: duration ?? this.duration,
      likeCount: likeCount ?? this.likeCount,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
