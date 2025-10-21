import 'interface/has_title_and_image.dart';

class Artist implements HasTitleAndImage {
  final String id;
  final String name;
  final String avatarUrl;
  final DateTime createdAt;

  Artist({
    required this.id,
    required this.name,
    required this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  String get displayTitle => name;

  @override
  String get displayImageUrl => avatarUrl;

  /// Tạo object từ Supabase row
  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] ?? '',
      name: map['name'] ?? 'No name',
      avatarUrl: map['avatar_url'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Convert về map để insert/update vào Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
  Artist copyWith({
    String? id,
    String? name,
    String? avatarUrl,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
