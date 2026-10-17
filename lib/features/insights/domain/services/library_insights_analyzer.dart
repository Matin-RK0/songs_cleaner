import '../../../library/domain/entities/song.dart';
import '../../../library/domain/value_objects/song_filter.dart';
import '../entities/duplicate_group.dart';
import '../entities/library_insights.dart';

abstract final class LibraryInsightsAnalyzer {
  static const int largeFileThresholdBytes = 50 * 1024 * 1024;
  static const int durationToleranceSeconds = 2;

  static LibraryInsights analyze(List<Song> songs) {
    final formatCounts = <String, int>{};
    final formatBytes = <String, int>{};
    var totalBytes = 0;
    var totalDuration = Duration.zero;
    var missingMetadata = 0;
    var shortTracks = 0;
    var largeFiles = 0;
    var lossless = 0;

    for (final song in songs) {
      totalBytes += song.sizeBytes;
      totalDuration += song.duration;
      if (SongFilter.missingMetadata.matches(song)) missingMetadata++;
      if (SongFilter.shortTracks.matches(song)) shortTracks++;
      if (song.sizeBytes >= largeFileThresholdBytes) largeFiles++;
      if (SongFilter.lossless.matches(song)) lossless++;
      final format = song.fileExtension.isEmpty
          ? 'unknown'
          : song.fileExtension.toLowerCase();
      formatCounts[format] = (formatCounts[format] ?? 0) + 1;
      formatBytes[format] = (formatBytes[format] ?? 0) + song.sizeBytes;
    }

    return LibraryInsights(
      totalSongs: songs.length,
      totalBytes: totalBytes,
      totalDuration: totalDuration,
      missingMetadataCount: missingMetadata,
      shortTrackCount: shortTracks,
      largeFileCount: largeFiles,
      losslessCount: lossless,
      formatCounts: Map.unmodifiable(formatCounts),
      formatBytes: Map.unmodifiable(formatBytes),
      duplicateGroups: findDuplicates(songs),
    );
  }

  static List<DuplicateGroup> findDuplicates(List<Song> songs) {
    final candidates = <String, List<Song>>{};
    for (final song in songs) {
      if (song.duration <= Duration.zero) continue;
      final title = _normalize(song.title);
      final artist = _normalize(song.artist);
      if (title.isEmpty || artist.isEmpty) continue;
      candidates.putIfAbsent('$title|$artist', () => <Song>[]).add(song);
    }

    final groups = <DuplicateGroup>[];
    for (final entry in candidates.entries) {
      if (entry.value.length < 2) continue;
      final sorted = [...entry.value]
        ..sort((a, b) => a.duration.compareTo(b.duration));
      var cluster = <Song>[sorted.first];
      for (final song in sorted.skip(1)) {
        final difference = (song.duration - cluster.first.duration).inSeconds
            .abs();
        if (difference <= durationToleranceSeconds) {
          cluster.add(song);
        } else {
          _addCluster(groups, entry.key, cluster);
          cluster = <Song>[song];
        }
      }
      _addCluster(groups, entry.key, cluster);
    }
    groups.sort((a, b) => b.recoverableBytes.compareTo(a.recoverableBytes));
    return List.unmodifiable(groups);
  }

  static void _addCluster(
    List<DuplicateGroup> groups,
    String key,
    List<Song> cluster,
  ) {
    if (cluster.length < 2) return;
    final recommended = [...cluster]..sort(_compareQuality);
    groups.add(
      DuplicateGroup(
        id: '$key|${cluster.first.duration.inSeconds}',
        songs: List.unmodifiable(cluster),
        recommendedSong: recommended.first,
      ),
    );
  }

  static int _compareQuality(Song a, Song b) {
    final byFormat = _qualityRank(
      b.fileExtension,
    ).compareTo(_qualityRank(a.fileExtension));
    if (byFormat != 0) return byFormat;
    final bySize = b.sizeBytes.compareTo(a.sizeBytes);
    if (bySize != 0) return bySize;
    return b.dateModifiedSeconds.compareTo(a.dateModifiedSeconds);
  }

  static int _qualityRank(String extension) =>
      switch (extension.toLowerCase()) {
        'flac' || 'alac' || 'wav' || 'aiff' || 'ape' || 'wv' => 3,
        'm4a' || 'aac' || 'opus' || 'ogg' => 2,
        'mp3' || 'wma' => 1,
        _ => 0,
      };

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
