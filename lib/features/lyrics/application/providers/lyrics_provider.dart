import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/domain/entities/song.dart';
import '../../infrastructure/lyrics_file_data_source.dart';
import '../../domain/entities/lyric_line.dart';

final lyricsFileDataSourceProvider = Provider<LyricsFileDataSource>(
  (ref) => LyricsFileDataSource(),
);

final lyricsProvider = FutureProvider.autoDispose.family<List<LyricLine>, Song>(
  (ref, song) => ref.watch(lyricsFileDataSourceProvider).loadForPath(song.path),
);
