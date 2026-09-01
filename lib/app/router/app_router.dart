import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../features/library/presentation/screens/group_songs_screen.dart';
import '../../features/library/presentation/screens/home_shell.dart';
import '../../features/library/presentation/screens/search_screen.dart';
import '../../features/player/presentation/screens/player_screen.dart';
import 'route_names.dart';

abstract final class AppRouter {
  /// Opens the player as a singleton above the home screen.
  ///
  /// Keeping [RouteNames.home] as the stop point removes stale player routes
  /// that may have been pushed by an earlier track/session.
  ///
  /// If the player is already the topmost route (e.g. a tap reached the mini
  /// player still layered beneath the transparent player route), this does
  /// nothing instead of pushing a second player on top, which would replay
  /// the slide-up transition.
  static Future<T?> openPlayer<T>(BuildContext context) {
    final navigator = Navigator.of(context);
    final topRoute = ModalRoute.of(navigator.context);
    if (topRoute?.settings.name == RouteNames.player) {
      return Future<T?>.value();
    }
    return navigator.pushNamedAndRemoveUntil<T>(
      RouteNames.player,
      ModalRoute.withName(RouteNames.home),
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return _fadeRoute(settings, const HomeShell());
      case RouteNames.player:
        return PlayerRoute(settings: settings);
      case RouteNames.search:
        return _slideRoute(settings, const SearchScreen());
      case RouteNames.groupSongs:
        final args = settings.arguments;
        if (args is GroupSongsArgs) {
          return _fadeRoute(
            settings,
            GroupSongsScreen(args: args),
          );
        }
        return _fadeRoute(settings, const HomeShell());
      default:
        return _fadeRoute(settings, const HomeShell());
    }
  }

  static PageRouteBuilder<T> _fadeRoute<T>(RouteSettings settings, Widget child) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppMotion.normal,
      reverseTransitionDuration: AppMotion.fast,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppMotion.standard),
        child: child,
      ),
    );
  }

  static PageRouteBuilder<T> _slideRoute<T>(RouteSettings settings, Widget child) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: AppMotion.normal,
      reverseTransitionDuration: AppMotion.fast,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: AppMotion.standard)),
        child: child,
      ),
    );
  }
}

/// Slide-up transition for the full player screen.
class PlayerRoute extends PageRouteBuilder<void> {
  PlayerRoute({super.settings})
      : super(
          transitionDuration: AppMotion.normal,
          reverseTransitionDuration: AppMotion.normal,
          opaque: false,
          // A tap outside the player must not dismiss it: the transparent
          // player route leaves home (with the mini player / song tiles)
          // layered underneath, and a stray tap there would pop the player
          // and immediately re-push it.
          barrierDismissible: false,
          barrierColor: Colors.black54,
          pageBuilder: (_, _, _) => const PlayerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: AppMotion.standard,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
        );
}
