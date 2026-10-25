import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/tdlib_transport.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_repository_impl.dart';

void _repositoryWorker(SendPort output) {
  final input = ReceivePort();
  output.send(input.sendPort);
  Map<String, dynamic>? held;
  String? holdNext;
  var calls = 0;
  input.listen((value) {
    final request = value as Map<String, dynamic>;
    final type = request['@type'];
    void reply(Map<String, dynamic> fields) =>
        output.send(<String, dynamic>{...fields, '@extra': request['@extra']});
    if (type == 'close') {
      output.send(<String, dynamic>{
        '@type': 'updateAuthorizationState',
        'authorization_state': {'@type': 'authorizationStateClosed'},
      });
      input.close();
      return;
    }
    if (type == 'holdNext') {
      holdNext = request['method'] as String;
      reply({'@type': 'ok'});
      return;
    }
    if (type == holdNext) {
      held = request;
      holdNext = null;
      return;
    }
    switch (type) {
      case 'release':
        if (held != null) {
          output.send(<String, dynamic>{
            '@type': 'chats',
            'chat_ids': [99],
            '@extra': held!['@extra'],
          });
          held = null;
        }
        reply({'@type': 'ok'});
      case 'getChats':
        final main = (request['chat_list'] as Map)['@type'] == 'chatListMain';
        reply({
          '@type': 'chats',
          'chat_ids': main ? [2] : [],
        });
      case 'getChat':
        calls++;
        reply({
          '@type': 'chat',
          'id': request['chat_id'],
          'title': 'Fresh',
          'type': {'@type': 'chatTypePrivate'},
        });
      case 'stats':
        reply({'@type': 'stats', 'calls': calls, 'held': held != null});
      default:
        reply({'@type': 'ok'});
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'pending offline list is superseded; late reply cannot overwrite repository cache or continue polling',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'telegram-recovery-',
      );
      final transport = TdlibTransport(worker: _repositoryWorker);
      await transport.start();
      final repository = TelegramRepositoryImpl(
        cacheDirectory: directory,
        transportFactory: () => transport,
      );
      addTearDown(() async {
        await repository.dispose();
        await directory.delete(recursive: true);
      });
      await transport.call('holdNext', {'method': 'getChats'});
      final stale = repository.chats();
      final failed = expectLater(stale, throwsA(isA<TelegramException>()));
      // Wait for the request to actually reach the worker before retrying.
      var held = false;
      for (var attempt = 0; attempt < 100 && !held; attempt++) {
        held = (await transport.call('stats'))['held'] == true;
        await Future<void>.delayed(Duration.zero);
      }
      expect(held, isTrue);
      final recovered = await repository.chats();
      await failed;
      expect(recovered.map((chat) => chat.id), [2]);
      await transport.call('release');
      expect((await repository.cachedChats()).map((chat) => chat.id), [2]);
      expect((await transport.call('stats'))['calls'], 1);
    },
  );
}
