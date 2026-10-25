import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/core/settings/home_tab_settings.dart';
import 'package:songs_cleaner/core/settings/home_tab_settings_controller.dart';
import 'package:songs_cleaner/core/theme/app_theme.dart';
import 'package:songs_cleaner/features/library/presentation/widgets/home_tabs_setting_tile.dart';

void main() {
  testWidgets('RTL sheet cancels drafts and saves the selected start tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('fa'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const Scaffold(body: HomeTabsSettingTile()),
        ),
      ),
    );
    await tester.tap(find.byType(HomeTabsSettingTile));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(RadioGroup<HomeTab>));
    final l10n = AppLocalizations.of(context);
    expect(Directionality.of(context), TextDirection.rtl);
    await tester.scrollUntilVisible(
      find.text(l10n.artistsTab),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.artistsTab));
    await tester.pump();
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(container.read(homeTabSettingsProvider).defaultTab, HomeTab.songs);

    await tester.tap(find.byType(HomeTabsSettingTile));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(l10n.artistsTab),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.artistsTab));
    await tester.pump();
    await tester.tap(find.text(l10n.saveAction));
    await tester.pumpAndSettle();
    expect(container.read(homeTabSettingsProvider).defaultTab, HomeTab.artists);
    expect(find.byType(RadioGroup<HomeTab>), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
