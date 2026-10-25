import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/player/presentation/widgets/queue_sheet.dart';
import 'package:songs_cleaner/features/telegram/presentation/widgets/telegram_download_sheet.dart';

import '../../features/telegram/telegram_experience_test.dart' show host;
import '../../features/telegram/telegram_fakes.dart';

void main() {
  for (final sheet in [
    (
      name: 'queue',
      open: showQueueSheet,
      content: find.byType(QueueSheetContent),
    ),
    (
      name: 'downloads',
      open: showTelegramDownloads,
      content: find.byType(TelegramDownloadsView),
    ),
  ]) {
    testWidgets(
      '${sheet.name} content stays above the system navigation area',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(
          top: 24,
          bottom: 34,
          left: 16,
          right: 16,
        );
        addTearDown(tester.view.reset);
        final repository = FakeTelegramRepository();
        await tester.pumpWidget(
          host(
            repository,
            Builder(
              builder: (context) => TextButton(
                onPressed: () => sheet.open(context),
                child: const Text('Open'),
              ),
            ),
            language: 'fa',
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final bounds = tester.getRect(sheet.content);
        expect(bounds.bottom, lessThanOrEqualTo(800 - 34));
        expect(bounds.left, greaterThanOrEqualTo(16));
        expect(bounds.right, lessThanOrEqualTo(400 - 16));
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await repository.dispose();
      },
    );
  }
}
