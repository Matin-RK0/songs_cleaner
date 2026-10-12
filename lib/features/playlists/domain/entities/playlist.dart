/// A user-created playlist: an ordered list of song ids with a name.
/// Metadata is persisted; songs are resolved against the live library so
/// removed/renamed files never leave stale entries in the UI.
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<int> songIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get songCount => songIds.length;

  bool get isEmpty => songIds.isEmpty;

  bool contains(int songId) => songIds.contains(songId);

  Playlist copyWith({
    String? name,
    List<int>? songIds,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'songIds': songIds,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  static Playlist? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final name = value['name'];
    final rawIds = value['songIds'];
    final createdAt = value['createdAt'];
    final updatedAt = value['updatedAt'];
    if (id is! String || name is! String || rawIds is! List) return null;

    final ids = rawIds
        .whereType<num>()
        .map((id) => id.toInt())
        .toList(growable: false);
    final created = createdAt is num
        ? DateTime.fromMillisecondsSinceEpoch(createdAt.toInt())
        : DateTime.now();
    final updated = updatedAt is num
        ? DateTime.fromMillisecondsSinceEpoch(updatedAt.toInt())
        : created;

    return Playlist(
      id: id,
      name: name,
      songIds: List.unmodifiable(ids),
      createdAt: created,
      updatedAt: updated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Playlist && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Playlist($id, $name, ${songIds.length})';
}
