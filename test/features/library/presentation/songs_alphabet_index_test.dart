import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/core/widgets/alphabet_index_rail.dart';
import 'package:songs_cleaner/features/library/application/providers/library_controller.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/song_sort.dart';
import 'package:songs_cleaner/features/library/presentation/screens/songs_tab.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';

void main() {
  testWidgets('Songs shows a working index in alphabetical modes only', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        libraryProvider.overrideWith(_Library.new),
        playerProvider.overrideWith(_Player.new),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fa'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: SongsTab(scrollController: scroll)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ک'));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    final controller = container.read(libraryProvider.notifier);
    for (final sort in [
      SongSort.dateAddedDesc,
      SongSort.trackAsc,
      SongSort.durationDesc,
    ]) {
      controller.setSort(sort);
      await tester.pumpAndSettle();
      expect(
        tester.widget<AlphabetIndexRail>(find.byType(AlphabetIndexRail)).index,
        isEmpty,
      );
    }
    controller.setSort(SongSort.artistAsc);
    await tester.pumpAndSettle();
    expect(find.text('P'), findsOneWidget);
    expect(find.text('ک'), findsNothing);
    controller.setSort(SongSort.albumAsc);
    await tester.pumpAndSettle();
    expect(find.text('Z'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Library extends LibraryController {
  @override
  Future<LibraryState> build() async {
    final songs = [for (var i = 0; i < 40; i++) _song(i)];
    return LibraryState(songs: songs, visibleSongs: songs).copyWith();
  }
}

class _Player extends PlayerController {
  @override
  PlayerState build() => PlayerState.initial;
}

Song _song(int i) => Song(
  id: i,
  title: i < 20 ? 'Alpha $i' : 'کتاب $i',
  artist: i < 20 ? 'Pear' : 'Banana',
  album: i < 20 ? 'Zebra' : 'Lime',
  albumId: 1,
  artistId: 1,
  duration: Duration(seconds: i + 50),
  path: '/music/$i.mp3',
  sizeBytes: 1,
  dateAddedSeconds: i,
);
