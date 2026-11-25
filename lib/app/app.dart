import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/generated/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/appearance_controller.dart';
import '../core/widgets/appearance_backdrop.dart';
import '../core/theme/primary_color_controller.dart';
import '../core/theme/theme_mode_controller.dart';
import '../core/theme/system_palette_controller.dart';
import '../features/lockscreen/application/providers/lock_screen_controller.dart';
import '../features/lockscreen/infrastructure/lock_screen_service.dart';
import '../features/player/application/providers/player_controller.dart';
import '../features/player/application/providers/playback_stats_recorder.dart';
import '../features/player/infrastructure/now_playing_widget_service.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';

class SongsCleanerApp extends ConsumerStatefulWidget {
  const SongsCleanerApp({super.key});

  @override
  ConsumerState<SongsCleanerApp> createState() => _SongsCleanerAppState();
}

class _SongsCleanerAppState extends ConsumerState<SongsCleanerApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<LockScreenEvent>? _eventsSub;
  Route<dynamic>? _lockScreenRoute;
  bool _lockScreenRequested = false;
  bool _startingPendingPlayback = false;
  int _lockScreenEventGeneration = 0;
  final NowPlayingWidgetService _widgetService =
      const NowPlayingWidgetService();

  @override
  void initState() {
    super.initState();
    _widgetService.listenToActions(_handlePendingWidgetActionValue);
    final service = ref.read(lockScreenServiceProvider);
    _eventsSub = service.events.listen(_onLockScreenEvent);

    // Seed the native playback rule; the listener in build() keeps it current.
    unawaited(
      service.setPlaybackActive(ref.read(playerProvider).hasActivePlayback),
    );
    // A cold media command can boot the engine without an attached Activity.
    unawaited(_registerLockScreen(service));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_handlePendingWidgetAction());
    });
  }

  Future<void> _registerLockScreen(LockScreenService service) async {
    final generation = _lockScreenEventGeneration;
    final pending = await service.register();
    final pendingPlay = await service.consumePendingPlay();
    if (!mounted) return;
    if (pending && generation == _lockScreenEventGeneration) _openLockScreen();
    if (pendingPlay) unawaited(_startPendingPlayback());
  }

  Future<void> _handlePendingWidgetAction() async {
    final action = await _widgetService.consumeAction();
    await _handlePendingWidgetActionValue(action);
  }

  Future<void> _handlePendingWidgetActionValue(String? action) async {
    if (!mounted || action == null) return;
    final handler = ref.read(musicPlayerHandlerProvider);
    switch (action) {
      case 'com.example.songs_cleaner.widget.PREVIOUS':
        await handler.previous();
      case 'com.example.songs_cleaner.widget.PLAY_PAUSE':
        await handler.playPause();
      case 'com.example.songs_cleaner.widget.NEXT':
        await handler.next();
      case 'com.example.songs_cleaner.OPEN_TELEGRAM_DOWNLOADS':
        final navigator = _navigatorKey.currentState;
        if (navigator == null) return;
        var alreadyOpen = false;
        navigator.popUntil((route) {
          alreadyOpen = route.settings.name == RouteNames.telegramDownloads;
          return true;
        });
        if (!alreadyOpen) {
          unawaited(navigator.pushNamed(RouteNames.telegramDownloads));
        }
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _widgetService.disposeActionListener();
    super.dispose();
  }

  void _onLockScreenEvent(LockScreenEvent event) {
    switch (event) {
      case LockScreenEvent.showPlayer:
        _lockScreenEventGeneration++;
        _openLockScreen();
      case LockScreenEvent.hidePlayer:
        _lockScreenEventGeneration++;
        _closeLockScreen();
      case LockScreenEvent.playRequested:
        unawaited(_startPendingPlayback());
    }
  }

  Future<void> _startPendingPlayback() async {
    if (_startingPendingPlayback) return;
    _startingPendingPlayback = true;
    final service = ref.read(lockScreenServiceProvider);
    try {
      await ref.read(musicPlayerHandlerProvider).play();
    } on Exception {
      // An unavailable library/source must leave the system lock screen alone.
    } finally {
      _startingPendingPlayback = false;
      await service.finishPlayRequest();
    }
  }

  void _openLockScreen() {
    if (!ref.read(playerProvider).hasActivePlayback) return;
    _lockScreenRequested = true;
    if (_lockScreenRoute != null) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      // Cold audio-service startup can deliver the native request before the
      // MaterialApp has attached its Navigator.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _lockScreenRequested) _openLockScreen();
      });
      return;
    }
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: RouteNames.lockScreen),
    );
    _lockScreenRoute = route;
    unawaited(
      navigator.push(route).whenComplete(() {
        if (identical(_lockScreenRoute, route)) _lockScreenRoute = null;
      }),
    );
  }

  void _closeLockScreen() {
    _lockScreenRequested = false;
    final route = _lockScreenRoute;
    _lockScreenRoute = null;
    // A sheet or another route may be above the player when playback stops.
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    // Records plays for the "most played" smart playlist; keep it alive.
    ref.watch(playbackStatsRecorderProvider);

    // Drives the native side: the lock screen only reacts while a song plays.
    ref.listen(
      playerProvider.select((state) => state.hasActivePlayback),
      (_, active) =>
          ref.read(lockScreenServiceProvider).setPlaybackActive(active),
    );

    final primaryColor = ref.watch(appPrimaryColorProvider);
    final appearance = ref.watch(appearanceProvider);
    final useSystemPrimary = ref.watch(appPrimarySystemPaletteProvider);
    final palette = (useSystemPrimary || appearance.systemTheme)
        ? ref.watch(systemPaletteProvider).value
        : null;
    final fullTheme = appearance.systemTheme && palette != null;
    final photo = fullTheme ? null : appearance.photoPath;

    return MaterialApp(
      title: 'Songs Cleaner',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.light(
        primary: useSystemPrimary
            ? palette?.light.primary ?? primaryColor
            : primaryColor,
        onPrimary: useSystemPrimary ? palette?.light.onPrimary : null,
        systemScheme: fullTheme ? palette.light : null,
        appearance: appearance,
      ),
      darkTheme: AppTheme.dark(
        primary: useSystemPrimary
            ? palette?.dark.primary ?? primaryColor
            : primaryColor,
        onPrimary: useSystemPrimary ? palette?.dark.onPrimary : null,
        systemScheme: fullTheme ? palette.dark : null,
        appearance: appearance,
      ),
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            AppearanceBackdrop(
              path: photo,
              dimming: appearance.photoDimming,
              framing: appearance.photoFraming,
            ),
          ?child,
        ],
      ),
      themeMode: ref.watch(appThemeModeProvider),
      locale: ref.watch(appLocaleProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      initialRoute: RouteNames.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
