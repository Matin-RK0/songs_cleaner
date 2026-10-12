import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/playlists/application/providers/playlist_providers.dart';
import 'package:songs_cleaner/features/playlists/application/providers/playlists_controller.dart';
import 'package:songs_cleaner/features/playlists/domain/entities/playlist.dart';
import 'package:songs_cleaner/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:songs_cleaner/features/playlists/presentation/widgets/playlist_song_sliver.dart';

/// Guards the `SliverReorderableList.onReorderItem` index convention against the
/// `PlaylistsController.reorder` math. A real drag gesture is simulated so the
/// framework's actual indices flow through the same path the UI uses; a wrong
/// off-by-one assumption would surface here as a misplaced song.
void main() {
  const playlistId = 'p1';

  Song song(int id) => Song(
    id: id,
    title: 'Song $id',
    artist: 'Artist $id',
    album: 'Album $id',
    albumId: id,
    artistId: id,
    duration: Duration(seconds: id * 30),
    path: '/music/$id.mp3',
    sizeBytes: 1024,
    dateAddedSeconds: id,
  );

  late ProviderContainer container;

  Future<void> pumpHarness(WidgetTester tester) async {
    final repository = _FakePlaylistRepository(<Playlist>[
      Playlist(
        id: playlistId,
        name: 'Mix',
        songIds: const <int>[1, 2, 3],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ]);
    container = ProviderContainer(
      overrides: [
        playlistRepositoryProvider.overrideWithValue(repository),
        allSongsProvider.overrideWithValue(<Song>[song(1), song(2), song(3)]),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: _ReorderHarness(playlistId: playlistId)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<int> displayedOrder(WidgetTester tester) {
    final positions = <int, double>{
      for (final id in const [1, 2, 3])
        id: tester.getTopLeft(find.byKey(ValueKey(id))).dy,
    };
    final ids = positions.keys.toList()
      ..sort((a, b) => positions[a]!.compareTo(positions[b]!));
    return ids;
  }

  Future<void> dragHandle(
    WidgetTester tester,
    int handleIndex,
    double dy,
  ) async {
    final handle = find.byIcon(Icons.drag_handle_rounded).at(handleIndex);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(Offset(0, dy / 3));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(Offset(0, dy / 3));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(Offset(0, dy / 3));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('dragging the first song to the end stores the new order', (
    tester,
  ) async {
    await pumpHarness(tester);
    expect(displayedOrder(tester), <int>[1, 2, 3]);

    final tileHeight = tester.getSize(find.byKey(const ValueKey(1))).height;
    await dragHandle(tester, 0, tileHeight * 2.5);

    expect(displayedOrder(tester), <int>[2, 3, 1]);
    expect(container.read(playlistsProvider).single.songIds, <int>[2, 3, 1]);
  });

  testWidgets('dragging the last song to the top stores the new order', (
    tester,
  ) async {
    await pumpHarness(tester);
    expect(displayedOrder(tester), <int>[1, 2, 3]);

    final tileHeight = tester.getSize(find.byKey(const ValueKey(1))).height;
    await dragHandle(tester, 2, -tileHeight * 2.5);

    expect(displayedOrder(tester), <int>[3, 1, 2]);
    expect(container.read(playlistsProvider).single.songIds, <int>[3, 1, 2]);
  });
}

/// Mirrors the production wiring in `PlaylistDetailScreen`: the sliver renders
/// the songs from the provider and pushes drags back into the controller.
class _ReorderHarness extends ConsumerWidget {
  const _ReorderHarness({required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(playlistSongsProvider(playlistId));
    return CustomScrollView(
      slivers: [
        PlaylistSongSliver(
          songs: songs,
          currentSongId: null,
          onSongTap: (_, _) {},
          onReorder: (oldIndex, newIndex) => ref
              .read(playlistsProvider.notifier)
              .reorder(playlistId, oldIndex, newIndex),
        ),
      ],
    );
  }
}

class _FakePlaylistRepository implements PlaylistRepository {
  _FakePlaylistRepository(this._playlists);

  List<Playlist> _playlists;

  @override
  List<Playlist> loadPlaylists() => List.unmodifiable(_playlists);

  @override
  Future<void> savePlaylists(List<Playlist> playlists) async {
    _playlists = List.of(playlists);
  }
}
