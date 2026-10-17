class TagDraft {
  const TagDraft({
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.composer,
    required this.trackNumber,
    required this.lyrics,
  });

  final String title;
  final String artist;
  final String album;
  final String genre;
  final String composer;
  final int trackNumber;
  final String lyrics;

  Map<String, Object> toJson() => <String, Object>{
    'title': title.trim(),
    'artist': artist.trim(),
    'album': album.trim(),
    'genre': genre.trim(),
    'composer': composer.trim(),
    'trackNumber': trackNumber,
  };
}
