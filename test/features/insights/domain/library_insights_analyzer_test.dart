import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/insights/domain/services/library_insights_analyzer.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';

void main() {
  Song song(
    int id, {
    String title = 'Track',
    String artist = 'Artist',
    String album = 'Album',
    String genre = 'Rock',
    String extension = 'mp3',
    int seconds = 180,
    int sizeBytes = 1000,
  }) => Song(
    id: id,
    title: title,
    artist: artist,
    album: album,
    albumId: 1,
    artistId: 1,
    duration: Duration(seconds: seconds),
    path: '/music/$id.$extension',
    sizeBytes: sizeBytes,
    dateAddedSeconds: 0,
    genre: genre,
    fileExtension: extension,
  );

  test('groups normalized metadata within the duration tolerance', () {
    final groups = LibraryInsightsAnalyzer.findDuplicates([
      song(1, title: '  My-Track ', artist: 'كيان', seconds: 180),
      song(2, title: 'my track', artist: 'کیان', seconds: 182),
      song(3, title: 'my track', artist: 'کیان', seconds: 184),
    ]);

    expect(groups, hasLength(1));
    expect(groups.single.songs.map((item) => item.id), [1, 2]);
  });

  test('does not group songs with different artists or distant durations', () {
    final groups = LibraryInsightsAnalyzer.findDuplicates([
      song(1, artist: 'First', seconds: 180),
      song(2, artist: 'Second', seconds: 180),
      song(3, artist: 'First', seconds: 190),
    ]);

    expect(groups, isEmpty);
  });

  test('does not guess duplicates when the artist is unknown', () {
    final groups = LibraryInsightsAnalyzer.findDuplicates([
      song(1, artist: ''),
      song(2, artist: ''),
    ]);

    expect(groups, isEmpty);
  });

  test('recommends a lossless copy before a larger lossy copy', () {
    final groups = LibraryInsightsAnalyzer.findDuplicates([
      song(1, extension: 'mp3', sizeBytes: 9000),
      song(2, extension: 'flac', sizeBytes: 5000),
    ]);

    expect(groups.single.recommendedSong.id, 2);
    expect(groups.single.recoverableBytes, 9000);
  });

  test('calculates storage, format and health metrics', () {
    final insights = LibraryInsightsAnalyzer.analyze([
      song(1, extension: 'flac', sizeBytes: 60 * 1024 * 1024),
      song(2, artist: '', album: '', genre: '', seconds: 30, sizeBytes: 100),
    ]);

    expect(insights.totalSongs, 2);
    expect(insights.missingMetadataCount, 1);
    expect(insights.shortTrackCount, 1);
    expect(insights.largeFileCount, 1);
    expect(insights.losslessCount, 1);
    expect(insights.formatCounts, {'flac': 1, 'mp3': 1});
  });
}
