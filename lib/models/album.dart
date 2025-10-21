import 'interface/has_title_and_image.dart';

class Album implements HasTitleAndImage {
  final String id;
  final String title;
  final String coverUrl;
  final String? artistId;
  final String? userId;
  final DateTime createdAt;

  Album({
    required this.id,
    required this.title,
    this.artistId,
    this.userId,
    required this.coverUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  String get displayTitle => title;

  @override
  String get displayImageUrl => coverUrl;

  /// Tạo object từ Supabase row
  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'] ?? '',
      title: map['title'] ?? 'No title',
      coverUrl: map['cover_url'] ?? '',
      artistId: map['artist_id'],
      userId: map['user_id'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert về Map để insert/update vào Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'cover_url': coverUrl,
      'artist_id': artistId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
