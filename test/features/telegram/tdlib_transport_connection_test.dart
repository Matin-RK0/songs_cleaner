import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/tdlib_transport.dart';

void _worker(SendPort output) {
  final input = ReceivePort();
  final waiting = <Map<String, dynamic>>[];
  output.send(input.sendPort);
  input.listen((value) {
    final request = value as Map<String, dynamic>;
    switch (request['@type']) {
      case 'close':
        output.send(<String, dynamic>{
          '@type': 'updateAuthorizationState',
          'authorization_state': {'@type': 'authorizationStateClosed'},
        });
        input.close();
      case 'hold':
        waiting.add(request);
      case 'release':
        for (final old in waiting) {
          output.send(<String, dynamic>{
            '@type': 'ok',
            '@extra': old['@extra'],
          });
        }
        waiting.clear();
        output.send(<String, dynamic>{
          '@type': 'ok',
          '@extra': request['@extra'],
        });
      case 'fail':
        output.send(<String, dynamic>{'@type': 'workerError'});
        input.close();
      default:
        output.send(<String, dynamic>{
          '@type': 'ok',
          '@extra': request['@extra'],
        });
    }
  });
}

final _networkFailure = isA<TelegramException>().having(
  (error) => error.failure,
  'failure',
  TelegramFailure.network,
);

void main() {
  test(
    'superseding browse cancels only its scope; late replies are discarded',
    () async {
      final transport = TdlibTransport(worker: _worker);
      await transport.start();
      addTearDown(transport.dispose);
      final updates = <Map<String, dynamic>>[];
      final subscription = transport.updates.listen(updates.add);
      addTearDown(subscription.cancel);
      final stale = transport.read('chats', 'hold');
      final staleFailure = expectLater(stale, throwsA(_networkFailure));
      final other = transport.read('audio:1', 'hold');
      final auth = transport.call('hold');
      transport.cancelReads('chats');
      await staleFailure;
      expect((await transport.read('chats', 'echo'))['@type'], 'ok');
      await transport.call('release');
      expect((await other)['@type'], 'ok');
      expect((await auth)['@type'], 'ok');
      expect(updates, isEmpty);
    },
  );

  test(
    'read timeout releases pending request and permits immediate retry',
    () async {
      final transport = TdlibTransport(
        worker: _worker,
        readTimeout: const Duration(milliseconds: 10),
      );
      await transport.start();
      addTearDown(transport.dispose);
      await expectLater(
        transport.read('chats', 'hold'),
        throwsA(_networkFailure),
      );
      expect((await transport.read('chats', 'echo'))['@type'], 'ok');
      await transport.call('release');
    },
  );

  test('worker failure fails pending requests promptly', () async {
    final transport = TdlibTransport(worker: _worker);
    await transport.start();
    addTearDown(transport.dispose);
    final pending = expectLater(
      transport.read('chats', 'hold'),
      throwsA(_networkFailure),
    );
    final failure = expectLater(
      transport.call('fail'),
      throwsA(_networkFailure),
    );
    await Future.wait([pending, failure]);
    await expectLater(transport.call('echo'), throwsA(_networkFailure));
  });
}
