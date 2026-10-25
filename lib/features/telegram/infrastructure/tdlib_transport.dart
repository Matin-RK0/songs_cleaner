import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:handy_tdlib_next/client.dart';

import '../domain/telegram_models.dart';

/// All native polling and JSON parsing live outside Flutter's UI isolate.
class TdlibTransport {
  TdlibTransport({
    this.requestTimeout = const Duration(seconds: 45),
    this.readTimeout = const Duration(seconds: 15),
    void Function(SendPort)? worker,
  }) : _worker = worker ?? _tdWorker;

  final Duration requestTimeout;
  final Duration readTimeout;
  final void Function(SendPort) _worker;
  final _updates = StreamController<Map<String, dynamic>>.broadcast();
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _readScopes = <int, String>{};
  final _receive = ReceivePort();
  final _nativeClosed = Completer<void>();
  SendPort? _send;
  int _sequence = 0;
  bool _closed = false;
  Stream<Map<String, dynamic>> get updates => _updates.stream;

  Future<void> start() async {
    final ready = Completer<void>();
    _receive.listen((event) {
      if (event is SendPort) {
        _send = event;
        ready.complete();
      } else if (event is Map<String, dynamic>) {
        if (event['@type'] == 'workerError') {
          _send = null;
          _failPending();
          if (!ready.isCompleted) {
            ready.completeError(
              const TelegramException(TelegramFailure.generic),
            );
          }
          return;
        }
        if (event['@type'] == 'updateAuthorizationState' &&
            (event['authorization_state'] as Map?)?['@type'] ==
                'authorizationStateClosed' &&
            !_nativeClosed.isCompleted) {
          _nativeClosed.complete();
          _send = null;
          _failPending();
        }
        final completer = _pending.remove(event['@extra']);
        if (completer != null) {
          if (event['@type'] == 'error') {
            completer.completeError(TelegramException(_mapError(event)));
          } else {
            completer.complete(event);
          }
        } else if (event['@extra'] == null && !_updates.isClosed) {
          _updates.add(event);
        }
      }
    });
    await Isolate.spawn(_worker, _receive.sendPort);
    await ready.future.timeout(const Duration(seconds: 20));
  }

  Future<Map<String, dynamic>> call(
    String type, [
    Map<String, dynamic> fields = const {},
  ]) => _call(type, fields, requestTimeout);

  /// Superseding a browse operation never cancels auth, downloads or other chats.
  void cancelReads(String scope) {
    for (final id in _readScopes.keys.toList()) {
      if (_readScopes[id] != scope) continue;
      _pending
          .remove(id)
          ?.completeError(const TelegramException(TelegramFailure.network));
      _readScopes.remove(id);
    }
  }

  Future<Map<String, dynamic>> read(
    String scope,
    String type, [
    Map<String, dynamic> fields = const {},
  ]) => _call(type, fields, readTimeout, scope);

  void _failPending() {
    for (final pending in _pending.values) {
      pending.completeError(const TelegramException(TelegramFailure.network));
    }
    _pending.clear();
    _readScopes.clear();
  }

  Future<Map<String, dynamic>> _call(
    String type,
    Map<String, dynamic> fields,
    Duration timeout, [
    String? scope,
  ]) async {
    if (_closed || _send == null) {
      throw const TelegramException(TelegramFailure.network);
    }
    final id = ++_sequence;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    if (scope != null) _readScopes[id] = scope;
    _send!.send({'@type': type, ...fields, '@extra': id});
    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      throw const TelegramException(TelegramFailure.network);
    } finally {
      _pending.remove(id);
      _readScopes.remove(id);
    }
  }

  static TelegramFailure _mapError(Map<String, dynamic> error) {
    final text = error['message'] as String? ?? '';
    if (error['code'] == 429 || text.contains('FLOOD')) {
      return TelegramFailure.flood;
    }
    if (text.contains('PHONE_NUMBER')) return TelegramFailure.phone;
    if (text.contains('PHONE_CODE')) return TelegramFailure.code;
    if (text.contains('PASSWORD')) return TelegramFailure.password;
    if (error['code'] == 500) return TelegramFailure.network;
    return TelegramFailure.generic;
  }

  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;
    _failPending();
    // TDLib must finish closing its database before the receive isolate exits.
    if (_send != null && !_nativeClosed.isCompleted) {
      _send!.send({'@type': 'close'});
      try {
        await _nativeClosed.future.timeout(const Duration(seconds: 5));
      } catch (_) {
        /* The worker continues polling until native storage closes. */
      }
    }
    _receive.close();
    await _updates.close();
  }
}

Future<void> _tdWorker(SendPort output) async {
  try {
    await TdPlugin.initialize();
    final td = TdPlugin.instance;
    td.tdExecute(
      jsonEncode({'@type': 'setLogVerbosityLevel', 'new_verbosity_level': 0}),
    );
    final client = td.tdCreateClientId();
    final input = ReceivePort();
    Timer? timer;
    var closing = false;
    input.listen((request) {
      if (request == null) {
        closing = true;
        return;
      }
      td.tdSend(client, jsonEncode(request));
    });
    output.send(input.sendPort);
    timer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      for (var i = 0; i < 100; i++) {
        final raw = td.tdReceive(0);
        if (raw == null) break;
        final event = jsonDecode(raw) as Map<String, dynamic>;
        if (event['@client_id'] != client) continue;
        // TDLib maintains unrelated cached updates internally; keep presence,
        // typing and unrelated message events away from Flutter's UI isolate.
        if (event['@extra'] == null &&
            event['@type'] != 'updateAuthorizationState' &&
            event['@type'] != 'updateFile') {
          continue;
        }
        output.send(event);
        if (event['@type'] == 'updateAuthorizationState' &&
            (event['authorization_state'] as Map?)?['@type'] ==
                'authorizationStateClosed') {
          timer?.cancel();
          input.close();
          Isolate.exit();
        }
      }
      if (closing) {
        // Keep polling until authorizationStateClosed flushes native storage.
        td.tdSend(client, jsonEncode({'@type': 'close'}));
        closing = false;
      }
    });
  } catch (_) {
    output.send(<String, dynamic>{'@type': 'workerError'});
  }
}
