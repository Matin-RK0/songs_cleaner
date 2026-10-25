import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/app/router/route_names.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/core/theme/app_spacing.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_download_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_download.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_download_activity.dart';
import 'package:songs_cleaner/features/telegram/presentation/screens/telegram_downloads_screen.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_download_sheet.dart';
import 'telegram_fakes.dart';

class _Downloads extends TelegramDownloadController {
  _Downloads(this.jobs);
  final Map<int, TelegramDownload> jobs;

  @override
  Map<int, TelegramDownload> build() => {...super.build(), ...jobs};
}

class _Activity extends TelegramDownloadActivity {
  @override
  Future<void> update(int active, int queued, {String? languageCode}) async {}
}

Map<int, TelegramDownload> _jobs(List<TelegramDownloadPhase> phases) => {
  for (var i = 0; i < phases.length; i++)
    testAudio(messageId: i + 1).fileId: TelegramDownload(
      audio: testAudio(messageId: i + 1),
      phase: phases[i],
      failure: phases[i] == TelegramDownloadPhase.failed
          ? TelegramFailure.generic
          : null,
    ),
};

ProviderContainer _container(Map<int, TelegramDownload> jobs) {
  final repository = FakeTelegramRepository();
  final container = ProviderContainer(
    overrides: [
      telegramRepositoryProvider.overrideWithValue(repository),
      telegramDownloadActivityProvider.overrideWithValue(_Activity()),
      telegramDownloadsProvider.overrideWith(() => _Downloads(jobs)),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await repository.dispose();
  });
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'clear removes only completed and canceled, retaining failed retries',
    () async {
      final jobs = _jobs(TelegramDownloadPhase.values);
      final container = _container(jobs);
      final manager = container.read(telegramDownloadsProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      manager.clearFinished();
      final remaining = container.read(telegramDownloadsProvider);
      expect(
        remaining.values.map((job) => job.phase),
        unorderedEquals([
          TelegramDownloadPhase.queued,
          TelegramDownloadPhase.receiving,
          TelegramDownloadPhase.saving,
          TelegramDownloadPhase.paused,
          TelegramDownloadPhase.failed,
        ]),
      );
      expect(
        remaining.values
            .singleWhere((job) => job.phase == TelegramDownloadPhase.failed)
            .failure,
        TelegramFailure.generic,
      );
      expect(container.read(telegramDownloadBulkActionsProvider), (
        pause: true,
        resume: true,
        clear: false,
      ));
      await Future<void>.delayed(Duration.zero);
      final saved = await container
          .read(telegramRepositoryProvider)
          .savedTransfers();
      expect(
        saved.map((audio) => audio.fileId),
        unorderedEquals(remaining.keys),
      );
    },
  );

  test('paused and saving jobs do not enable pause or clear', () {
    final container = _container(
      _jobs([TelegramDownloadPhase.paused, TelegramDownloadPhase.saving]),
    );
    expect(container.read(telegramDownloadBulkActionsProvider), (
      pause: false,
      resume: true,
      clear: false,
    ));
  });

  Future<void> pumpDownloads(
    WidgetTester tester, {
    required Size size,
    double scale = 1,
    bool fill = false,
    Locale locale = const Locale('en'),
    List<TelegramDownloadPhase> phases = const [TelegramDownloadPhase.queued],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = _container(_jobs(phases));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          routes: {
            RouteNames.telegramAuth: (_) =>
                const Scaffold(body: Text('auth destination')),
          },
          home: fill
              ? const TelegramDownloadsScreen()
              : const Scaffold(body: TelegramDownloadsView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('short landscape with large text scrolls header to queue', (
    tester,
  ) async {
    await pumpDownloads(tester, size: const Size(640, 320), scale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byIcon(Icons.close_rounded),
      100,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_rounded).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full screen has one title and constrains wide queue', (
    tester,
  ) async {
    await pumpDownloads(
      tester,
      size: const Size(1200, 800),
      fill: true,
      phases: [TelegramDownloadPhase.completed],
    );
    final context = tester.element(find.byType(TelegramDownloadsScreen));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.telegramDownloads), findsOneWidget);
    expect(
      tester.getSize(find.byType(CustomScrollView)).width,
      AppSpacing.contentMaxWidth,
    );
    expect(find.byTooltip(l10n.telegramCompleted), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, l10n.telegramPauseAll),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, l10n.telegramResumeAll),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending disconnected queue reconnects using auth route', (
    tester,
  ) async {
    await pumpDownloads(tester, size: const Size(600, 800));
    final context = tester.element(find.byType(TelegramDownloadsView));
    final l10n = AppLocalizations.of(context);
    expect(
      find.text(l10n.telegramDownloadsWaitingForConnection),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.telegramReconnect));
    await tester.pumpAndSettle();
    expect(find.text('auth destination'), findsOneWidget);
  });

  testWidgets('RTL large text rows retain a single queued cancel', (
    tester,
  ) async {
    await pumpDownloads(
      tester,
      size: const Size(400, 700),
      scale: 2,
      locale: const Locale('fa'),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
