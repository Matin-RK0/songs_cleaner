import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_message_link.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/tdlib_transport.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_music_publisher.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_repository_impl.dart';

import 'telegram_fakes.dart';

class _LinkTransport extends TdlibTransport {
  String link = 'https://t.me/music_channel/42?single&thread=7';
  bool fail = false;
  int reads = 0;
  final canceled = <String>[];
  Completer<Map<String, dynamic>>? pending;

  @override
  Future<Map<String, dynamic>> read(
    String scope,
    String type, [
    Map<String, dynamic> fields = const {},
  ]) async {
    reads++;
    if (pending != null) return pending!.future;
    if (fail) throw const TelegramException(TelegramFailure.generic);
    return {'@type': 'messageLink', 'link': link};
  }

  @override
  void cancelReads(String scope) => canceled.add(scope);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channelId = -1001234567890;
  const messageId = 42 << 20;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final opened = <Map<dynamic, dynamic>>[];

  setUp(() {
    opened.clear();
    messenger.setMockMethodCallHandler(TelegramMusicPublisher.channel, (
      call,
    ) async {
      if (call.method == 'openTelegramLink') {
        opened.add(call.arguments as Map);
        return true;
      }
      return null;
    });
  });
  tearDown(
    () => messenger.setMockMethodCallHandler(
      TelegramMusicPublisher.channel,
      null,
    ),
  );

  test('private chats and basic groups use original server message IDs', () {
    final private = TelegramMessageLink.fromAudio(
      testAudio(chatId: 123, messageId: messageId),
    )!;
    expect(private.appUri.host, 'openmessage');
    expect(private.appUri.queryParameters, {
      'user_id': '123',
      'message_id': '42',
    });
    expect(private.webUri, isNull);
    final group = TelegramMessageLink.fromAudio(
      testAudio(chatId: -123, messageId: messageId),
    )!;
    expect(group.appUri.queryParameters, {
      'chat_id': '123',
      'message_id': '42',
    });
  });

  test(
    'supergroups remove the TDLib offset and have app/web message links',
    () {
      final target = TelegramMessageLink.fromAudio(
        testAudio(chatId: channelId, messageId: messageId),
      )!;
      expect(target.appUri.host, 'privatepost');
      expect(target.appUri.queryParameters['channel'], '1234567890');
      expect(target.appUri.queryParameters['post'], '42');
      expect(target.webUri!.path, '/c/1234567890/42');
    },
  );

  test('pending/local/scheduled IDs and secret chats are not guessed', () {
    for (final id in [
      0,
      -messageId,
      messageId + 1,
      messageId + 2,
      messageId + 4,
      (0x80000000 << 20),
    ]) {
      expect(TelegramMessageLink.fromAudio(testAudio(messageId: id)), isNull);
    }
    expect(
      TelegramMessageLink.fromAudio(testAudio(chatId: 0, messageId: messageId)),
      isNull,
    );
    expect(
      TelegramMessageLink.fromAudio(
        testAudio(chatId: -2000000000001, messageId: messageId),
      ),
      isNull,
    );
  });

  test(
    'public, private and forum links preserve exact thread and media targets',
    () {
      final public = TelegramMessageLink.fromHttps(
        'https://t.me/music_channel/42?single&comment=8&t=12',
      )!;
      expect(public.appUri.host, 'resolve');
      expect(public.appUri.queryParameters, {
        'domain': 'music_channel',
        'post': '42',
        'single': '',
        'comment': '8',
        't': '12',
      });
      final forum = TelegramMessageLink.fromHttps(
        'https://t.me/c/1234567890/7/42?single',
      )!;
      expect(forum.appUri.host, 'privatepost');
      expect(forum.appUri.queryParameters['thread'], '7');
      expect(forum.appUri.queryParameters['post'], '42');
      expect(forum.webUri.toString(), 'https://t.me/c/1234567890/7/42?single');
      expect(
        TelegramMessageLink.fromHttps(
          'https://telegram.me/music_channel/42',
        )!.appUri.host,
        'resolve',
      );
    },
  );

  test('unrelated or malformed URLs are not sent to external apps', () {
    for (final link in [
      'https://example.com/music/42',
      'https://t.me.evil.com/music/42',
      'https://user@t.me/music/42',
      'http://t.me/music/42',
      'https://t.me/music',
      'https://t.me/c/nope/42',
      'https://t.me/music/0',
    ]) {
      expect(TelegramMessageLink.fromHttps(link), isNull, reason: link);
    }
  });

  test(
    'private messages open immediately without requesting an unsupported shared link',
    () async {
      final transport = _LinkTransport()..fail = true;
      final repository = TelegramRepositoryImpl(
        transportFactory: () => transport,
      );
      addTearDown(repository.dispose);
      expect(
        await repository.openMessage(testAudio(messageId: messageId)),
        isTrue,
      );
      expect(transport.reads, 0);
      expect(
        Uri.parse(
          opened.single['link'] as String,
        ).queryParameters['message_id'],
        '42',
      );
    },
  );

  test(
    'canonical links launch the native app with an HTTPS fallback',
    () async {
      final transport = _LinkTransport();
      final repository = TelegramRepositoryImpl(
        transportFactory: () => transport,
      );
      addTearDown(repository.dispose);
      expect(
        await repository.openMessage(
          testAudio(chatId: channelId, messageId: messageId),
        ),
        isTrue,
      );
      final target = Uri.parse(opened.single['link'] as String);
      expect(target.scheme, 'tg');
      expect(target.host, 'resolve');
      expect(target.queryParameters['post'], '42');
      expect(target.queryParameters['thread'], '7');
      expect(opened.single['fallbackLink'], transport.link);
    },
  );

  test('offline cached channels still open at the correct message', () async {
    final repository = TelegramRepositoryImpl();
    addTearDown(repository.dispose);
    expect(
      await repository.openMessage(
        testAudio(chatId: channelId, messageId: messageId),
      ),
      isTrue,
    );
    expect(Uri.parse(opened.single['link'] as String).host, 'privatepost');
  });

  test('TDLib errors fall back to cached IDs', () async {
    final transport = _LinkTransport()..fail = true;
    final repository = TelegramRepositoryImpl(
      transportFactory: () => transport,
    );
    addTearDown(repository.dispose);
    expect(
      await repository.openMessage(
        testAudio(chatId: channelId, messageId: messageId),
      ),
      isTrue,
    );
    expect(
      Uri.parse(opened.single['link'] as String).queryParameters['post'],
      '42',
    );
  });

  testWidgets(
    'a stalled link request falls back promptly and late replies do not reopen Telegram',
    (tester) async {
      final transport = _LinkTransport()
        ..pending = Completer<Map<String, dynamic>>();
      final repository = TelegramRepositoryImpl(
        transportFactory: () => transport,
      );
      addTearDown(repository.dispose);
      final opening = repository.openMessage(
        testAudio(chatId: channelId, messageId: messageId),
      );
      await tester.pump(const Duration(seconds: 4));
      expect(await opening, isTrue);
      expect(transport.canceled, isNotEmpty);
      transport.pending!.complete({
        '@type': 'messageLink',
        'link': transport.link,
      });
      await tester.pump();
      expect(opened, hasLength(1));
    },
  );

  test(
    'duplicate taps share the same launch and subsequent taps can retry',
    () async {
      final gate = Completer<bool>();
      messenger.setMockMethodCallHandler(TelegramMusicPublisher.channel, (
        call,
      ) async {
        opened.add(call.arguments as Map);
        return gate.future;
      });
      final repository = TelegramRepositoryImpl();
      addTearDown(repository.dispose);
      final audio = testAudio(messageId: messageId);
      final first = repository.openMessage(audio);
      final duplicate = repository.openMessage(audio);
      await Future<void>.delayed(Duration.zero);
      expect(opened, hasLength(1));
      gate.complete(true);
      expect(await first, isTrue);
      expect(await duplicate, isTrue);
      expect(await repository.openMessage(audio), isTrue);
      expect(opened, hasLength(2));
    },
  );

  test(
    'missing platform handlers report failure instead of throwing',
    () async {
      messenger.setMockMethodCallHandler(
        TelegramMusicPublisher.channel,
        (_) async => throw PlatformException(code: 'NO_HANDLER'),
      );
      expect(
        await TelegramMusicPublisher().openTelegramLink(
          'tg://openmessage?user_id=123&message_id=42',
        ),
        isFalse,
      );
    },
  );
}
