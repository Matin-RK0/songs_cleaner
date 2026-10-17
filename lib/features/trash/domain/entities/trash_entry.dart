class TrashEntry {
  const TrashEntry({
    required this.id,
    required this.songId,
    required this.title,
    required this.artist,
    required this.originalPath,
    required this.trashPath,
    required this.deletedAt,
    required this.sizeBytes,
  });

  final String id;
  final int songId;
  final String title;
  final String artist;
  final String originalPath;
  final String trashPath;
  final DateTime deletedAt;
  final int sizeBytes;

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'songId': songId,
    'title': title,
    'artist': artist,
    'originalPath': originalPath,
    'trashPath': trashPath,
    'deletedAtMs': deletedAt.millisecondsSinceEpoch,
    'sizeBytes': sizeBytes,
  };

  static TrashEntry? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final songId = value['songId'];
    final title = value['title'];
    final artist = value['artist'];
    final originalPath = value['originalPath'];
    final trashPath = value['trashPath'];
    final deletedAtMs = value['deletedAtMs'];
    final sizeBytes = value['sizeBytes'];
    if (id is! String ||
        songId is! num ||
        title is! String ||
        artist is! String ||
        originalPath is! String ||
        trashPath is! String ||
        deletedAtMs is! num ||
        sizeBytes is! num) {
      return null;
    }
    return TrashEntry(
      id: id,
      songId: songId.toInt(),
      title: title,
      artist: artist,
      originalPath: originalPath,
      trashPath: trashPath,
      deletedAt: DateTime.fromMillisecondsSinceEpoch(deletedAtMs.toInt()),
      sizeBytes: sizeBytes.toInt(),
    );
  }
}
