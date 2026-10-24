import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/app/router/app_router.dart';
import 'package:songs_cleaner/app/router/route_names.dart';

void main() {
  test('lock-screen route is opaque and has no transition delay', () {
    const settings = RouteSettings(name: RouteNames.lockScreen);
    final route = AppRouter.onGenerateRoute(settings) as PageRoute<void>;

    expect(route.settings, same(settings));
    expect(route.opaque, isTrue);
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
  });
}
