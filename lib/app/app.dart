import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/generated/app_localizations.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import '../features/lockscreen/application/providers/lock_screen_controller.dart';
import '../features/lockscreen/infrastructure/lock_screen_service.dart';
import '../features/player/application/providers/player_controller.dart';
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

  @override
  void initState() {
    super.initState();
    final service = ref.read(lockScreenServiceProvider);
    _eventsSub = service.events.listen(_onLockScreenEvent);

    // Seed the native playback rule; the listener in build() keeps it current.
    final player = ref.read(playerProvider);
    service.setPlaybackActive(player.hasCurrent && player.playing);

    // Announce that Dart can receive show/hide events, then honor a show that
    // the lock screen requested while the app was still booting.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pending = await service.register();
      if (!mounted || !pending) return;
      _openLockScreen();
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _onLockScreenEvent(LockScreenEvent event) {
    switch (event) {
      case LockScreenEvent.showPlayer:
        _openLockScreen();
      case LockScreenEvent.hidePlayer:
        _closeLockScreen();
    }
  }

  void _openLockScreen() {
    if (_lockScreenOpen) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
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
    // Drives the native side: the lock screen only reacts while a song plays.
    ref.listen(
      playerProvider.select((state) => state.hasCurrent && state.playing),
      (_, active) =>
          ref.read(lockScreenServiceProvider).setPlaybackActive(active),
    );

    return MaterialApp(
      title: 'Songs Cleaner',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(appThemeModeProvider),
      locale: const Locale('en'),
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
