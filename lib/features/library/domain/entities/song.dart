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
    this.genre = '',
    this.genreId = -1,
    this.composer = '',
    this.trackNumber = 0,
    this.dateModifiedSeconds = 0,
    this.fileExtension = '',
    this.folderPath = '',
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
  final String genre;
  final int genreId;
  final String composer;
  final int trackNumber;
  final int dateModifiedSeconds;
  final String fileExtension;
  final String folderPath;

  bool get hasFile => path.isNotEmpty;

  String get folderName {
    if (folderPath.isEmpty) return '';
    final parts = folderPath.split(RegExp(r'[/\\]+'));
    return parts.isEmpty ? folderPath : parts.last;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Song && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song($id, $title)';
}
