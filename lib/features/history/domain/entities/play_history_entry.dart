class PlayHistoryEntry {
  const PlayHistoryEntry({required this.songId, required this.playedAt});

  final int songId;
  final DateTime playedAt;

  Map<String, Object> toJson() => <String, Object>{
    'songId': songId,
    'playedAtMs': playedAt.millisecondsSinceEpoch,
  };

  static PlayHistoryEntry? fromJson(Object? value) {
    if (value is! Map) return null;
    final songId = value['songId'];
    final playedAtMs = value['playedAtMs'];
    if (songId is! num || playedAtMs is! num) return null;
    return PlayHistoryEntry(
      songId: songId.toInt(),
      playedAt: DateTime.fromMillisecondsSinceEpoch(playedAtMs.toInt()),
    );
  }
}
