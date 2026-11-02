import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';

Song _song(int id) => Song(
  id: id,
  title: 'Track $id',
  artist: '',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: const Duration(seconds: 60),
  path: '/$id.mp3',
  sizeBytes: 0,
  dateAddedSeconds: 0,
);

class _Player extends PlayerController {
  List<Song> queued = [];
  int selectedIndex = -1;

  @override
  PlayerState build() => PlayerState.initial;

  @override
  Future<void> playFromList(List<Song> songs, {required int startIndex}) async {
    queued = songs;
    selectedIndex = startIndex;
  }
}

void main() {
  test('search plays the selected track inside the complete library', () async {
    final player = _Player();
    final container = ProviderContainer(
      overrides: [
        playerProvider.overrideWith(() => player),
        allSongsProvider.overrideWithValue([_song(1), _song(2), _song(3)]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(playerProvider.notifier).playFromLibrary(_song(2));
    expect(player.queued.map((song) => song.id), [1, 2, 3]);
    expect(player.selectedIndex, 1);
  });

  test(
    'history playback snapshots all distinct entries at selection time',
    () async {
      final player = _Player();
      final container = ProviderContainer(
        overrides: [playerProvider.overrideWith(() => player)],
      );
      addTearDown(container.dispose);
      final history = [_song(3), _song(1), _song(3), _song(2)];
      await container
          .read(playerProvider.notifier)
          .playFromContext(history, selected: _song(1));
      history.clear();
      expect(player.queued.map((song) => song.id), [3, 1, 2]);
      expect(player.selectedIndex, 1);
    },
  );
}
