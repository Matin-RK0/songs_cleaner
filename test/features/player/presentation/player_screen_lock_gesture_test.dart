import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/library/application/providers/library_stats_controller.dart';
import 'package:songs_cleaner/features/library/domain/entities/song.dart';
import 'package:songs_cleaner/features/library/domain/value_objects/library_stats.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/artwork_image.dart';
import 'package:songs_cleaner/features/lockscreen/presentation/screens/lock_screen_player_screen.dart';
import 'package:songs_cleaner/features/player/application/models/player_state.dart';
import 'package:songs_cleaner/features/player/application/providers/player_controller.dart';
import 'package:songs_cleaner/features/player/application/providers/player_preferences_controller.dart';
import 'package:songs_cleaner/features/player/presentation/screens/player_screen.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/delete_current_button.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_actions.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_icon.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/player_track_info.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/seek_bar.dart';

const _song = Song(
  id: 1,
  title: 'Kalidor',
  artist: 'Armin Barmaye',
  album: '',
  albumId: 0,
  artistId: 0,
  duration: Duration(minutes: 3),
  path: '/1.mp3',
  sizeBytes: 0,
  dateAddedSeconds: 0,
);

class _Player extends PlayerController {
  _Player(this.initialPlaying);
  final bool initialPlaying;
  int toggleCalls = 0;

  @override
  PlayerState build() =>
      PlayerState(songs: const [_song], index: 0, playing: initialPlaying);

  @override
  Future<void> playPause() async {
    toggleCalls++;
    state = state.copyWith(playing: !state.playing);
  }

  @override
  Future<void> seek(Duration position) async {}
}

class _Stats extends LibraryStatsController {
  @override
  LibraryStats build() => LibraryStats.empty;

  @override
  Future<void> toggleFavorite(int songId) async {}
}

class _ShowDelete extends HideQuickDeleteController {
  @override
  bool build() => false;
}

void main() {
  const channel = MethodChannel('com.example.songs_cleaner/lock_screen');
  final calls = <String>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return call.method == 'lockScreen' ? 'locked' : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<_Player> open(
    WidgetTester tester, {
    required bool locked,
    bool playing = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final player = _Player(playing);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerProvider.overrideWith(() => player),
          libraryStatsProvider.overrideWith(_Stats.new),
          hideQuickDeleteProvider.overrideWith(_ShowDelete.new),
          songArtworkProvider.overrideWith((ref, request) async => null),
        ],
        child: MaterialApp(
          locale: const Locale('fa'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: locked ? const LockScreenPlayerScreen() : const PlayerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return player;
  }

  Future<void> doubleTap(WidgetTester tester, Offset point) async {
    await tester.tapAt(point);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(point);
    await tester.pumpAndSettle();
  }

  Finder glyph(PlayerGlyph glyph) => find.byWidgetPredicate(
    (widget) => widget is PlayerIcon && widget.glyph == glyph,
  );

  for (final locked in [false, true]) {
    for (final playing in [false, true]) {
      testWidgets(
        'cover, metadata and empty gap lock only on double tap; locked=$locked playing=$playing',
        (tester) async {
          await open(tester, locked: locked, playing: playing);
          final titleBottom = tester
              .getBottomRight(find.byType(PlayerTrackInfo))
              .dy;
          final actionsTop = tester.getTopLeft(find.byType(PlayerActions)).dy;
          final points = [
            tester.getCenter(find.byType(ArtworkImage)),
            tester.getCenter(find.text(_song.title)),
            tester.getCenter(find.text(_song.artist)),
            Offset(206, (titleBottom + actionsTop) / 2),
            const Offset(8, 880),
          ];
          for (final point in points) {
            final before = calls.length;
            await tester.tapAt(point);
            await tester.pump(const Duration(milliseconds: 400));
            expect(calls.length, before);
            await doubleTap(tester, point);
            expect(calls.length, before + 1);
            expect(calls.last, 'lockScreen');
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'transport, disabled skip, seek, favorite and delete never lock; locked=$locked',
      (tester) async {
        final player = await open(tester, locked: locked);
        for (final target in [
          glyph(PlayerGlyph.play),
          glyph(PlayerGlyph.previous),
          glyph(PlayerGlyph.next),
          glyph(PlayerGlyph.favoriteOutline),
          find.byType(SeekBar),
          find.byType(DeleteCurrentButton),
        ]) {
          await doubleTap(tester, tester.getCenter(target));
        }
        expect(player.toggleCalls, 2);
        expect(calls, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
