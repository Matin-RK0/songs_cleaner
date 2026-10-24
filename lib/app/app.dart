import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/generated/app_localizations.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/primary_color_controller.dart';
import '../core/theme/theme_mode_controller.dart';
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
  bool _lockScreenOpen = false;
  final NowPlayingWidgetService _widgetService =
      const NowPlayingWidgetService();

  @override
  void initState() {
    super.initState();
    _widgetService.listenToActions(_handlePendingWidgetActionValue);
    final service = ref.read(lockScreenServiceProvider);
    _eventsSub = service.events.listen(_onLockScreenEvent);

    // Seed the native playback rule; the listener in build() keeps it current.
    final player = ref.read(playerProvider);
    service.setPlaybackActive(player.hasCurrent && player.playing);

    // Announce that Dart can receive show/hide events, then honor a show that
    // the lock screen requested while the app was still booting.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pending = await service.register();
      final pendingPlay = await service.consumePendingPlay();
      if (!mounted) return;
      if (pending) _openLockScreen();
      if (pendingPlay) {
        unawaited(_startPendingPlayback());
      }
      unawaited(_handlePendingWidgetAction());
    });
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
        _openLockScreen();
      case LockScreenEvent.hidePlayer:
        _closeLockScreen();
      case LockScreenEvent.playRequested:
        unawaited(_startPendingPlayback());
    }
  }

  Future<void> _startPendingPlayback() async {
    final service = ref.read(lockScreenServiceProvider);
    await service.setPlaybackActive(true);
    await ref.read(musicPlayerHandlerProvider).play();
    await service.setPlaybackActive(true);
  }

  void _openLockScreen() {
    if (_lockScreenOpen) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      // Cold audio-service startup can deliver the native request before the
      // MaterialApp has attached its Navigator.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openLockScreen();
      });
      return;
    }
    _lockScreenOpen = true;
    navigator.pushNamed(RouteNames.lockScreen).whenComplete(() {
      _lockScreenOpen = false;
    });
  }

  void _closeLockScreen() {
    if (!_lockScreenOpen) return;
    _navigatorKey.currentState?.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Records plays for the "most played" smart playlist; keep it alive.
    ref.watch(playbackStatsRecorderProvider);

    // Drives the native side: the lock screen only reacts while a song plays.
    ref.listen(
      playerProvider.select((state) => state.hasCurrent && state.playing),
      (_, active) =>
          ref.read(lockScreenServiceProvider).setPlaybackActive(active),
    );

    final primaryColor = ref.watch(appPrimaryColorProvider);

    return MaterialApp(
      title: 'Songs Cleaner',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.light(primary: primaryColor),
      darkTheme: AppTheme.dark(primary: primaryColor),
      themeMode: ref.watch(appThemeModeProvider),
      locale: ref.watch(appLocaleProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: RouteNames.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
