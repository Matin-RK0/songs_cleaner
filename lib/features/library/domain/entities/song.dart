class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.artistId,
    required this.duration,
    required this.path,
    required this.sizeBytes,
    required this.dateAddedSeconds,
  });

  final int id;
  final String title;
  final String artist;
  final String album;
  final int albumId;
  final int artistId;
  final Duration duration;
  final String path;
  final int sizeBytes;
  final int dateAddedSeconds;

  bool get hasFile => path.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Song && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song($id, $title)';
}
