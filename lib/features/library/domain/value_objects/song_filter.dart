import '../entities/song.dart';

enum SongFilter { all, missingMetadata, shortTracks, longTracks, lossless }

extension SongFilterX on SongFilter {
  bool matches(Song song) => switch (this) {
    SongFilter.all => true,
    SongFilter.missingMetadata =>
      song.artist.isEmpty || song.album.isEmpty || song.genre.isEmpty,
    SongFilter.shortTracks => song.duration < const Duration(minutes: 1),
    SongFilter.longTracks => song.duration >= const Duration(minutes: 10),
    SongFilter.lossless => const {
      'flac',
      'wav',
      'ape',
      'alac',
      'aiff',
      'wv',
    }.contains(song.fileExtension),
  };
}
