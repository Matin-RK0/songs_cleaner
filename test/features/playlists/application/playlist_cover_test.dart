import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/playlists/application/providers/playlist_providers.dart';
import 'package:songs_cleaner/features/playlists/application/providers/playlists_controller.dart';
import 'package:songs_cleaner/features/playlists/infrastructure/playlist_cover_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cover selection persists; cancel keeps it; reset and playlist deletion clean it up', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cover = _CoverStore();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        playlistCoverStoreProvider.overrideWithValue(cover),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(playlistsProvider.notifier);
    final playlist = await controller.create('Mix');
    final repository = container.read(playlistRepositoryProvider);
    cover.selected = '/app/playlist-covers/one.jpg';
    await controller.pickCover(playlist.id);
    expect(repository.loadPlaylists().single.coverPath, cover.selected);
    cover.selected = null;
    await controller.pickCover(playlist.id);
    expect(repository.loadPlaylists().single.coverPath, endsWith('one.jpg'));
    expect(cover.removed, isEmpty);

    await controller.resetCover(playlist.id);
    expect(repository.loadPlaylists().single.coverPath, isNull);
    expect(cover.removed, [endsWith('one.jpg')]);
    cover.selected = '/app/playlist-covers/two.jpg';
    await controller.pickCover(playlist.id);
    await controller.remove(playlist.id);
    expect(repository.loadPlaylists(), isEmpty);
    expect(cover.removed.last, cover.selected);
  });
}

class _CoverStore extends PlaylistCoverStore {
  String? selected;
  final removed = <String>[];

  @override
  Future<String?> pick() async => selected;

  @override
  Future<void> remove(String? path) async {
    if (path != null) removed.add(path);
  }
}
