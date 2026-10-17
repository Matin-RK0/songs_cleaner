import 'duplicate_group.dart';

class LibraryInsights {
  const LibraryInsights({
    required this.totalSongs,
    required this.totalBytes,
    required this.totalDuration,
    required this.missingMetadataCount,
    required this.shortTrackCount,
    required this.largeFileCount,
    required this.losslessCount,
    required this.formatCounts,
    required this.formatBytes,
    required this.duplicateGroups,
  });

  final int totalSongs;
  final int totalBytes;
  final Duration totalDuration;
  final int missingMetadataCount;
  final int shortTrackCount;
  final int largeFileCount;
  final int losslessCount;
  final Map<String, int> formatCounts;
  final Map<String, int> formatBytes;
  final List<DuplicateGroup> duplicateGroups;

  int get duplicateFileCount =>
      duplicateGroups.fold(0, (total, group) => total + group.songs.length - 1);

  int get recoverableBytes =>
      duplicateGroups.fold(0, (total, group) => total + group.recoverableBytes);
}
