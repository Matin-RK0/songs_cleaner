import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'telegram_controller.dart';

final telegramPreferencesProvider =
    NotifierProvider<TelegramPreferencesController, Map<String, dynamic>>(
      TelegramPreferencesController.new,
    );

class TelegramPreferencesController extends Notifier<Map<String, dynamic>> {
  Future<void> _saving = Future.value();
  bool _closing = false;
  final _ready = Completer<void>();
  Future<void> get ready => _ready.future;
  @override
  Map<String, dynamic> build() {
    Future.microtask(() async {
      try {
        final saved = await ref
            .read(telegramRepositoryProvider)
            .loadPreferences();
        if (ref.mounted) state = {...saved, ...state};
      } catch (_) {
      } finally {
        if (!_ready.isCompleted) _ready.complete();
      }
    });
    return const {};
  }

  void _commit(Map<String, dynamic> next) {
    if (_closing) return;
    state = next;
    final repository = ref.read(telegramRepositoryProvider);
    _saving = _saving.catchError((Object _) {}).then<void>((_) async {
      if (!ref.mounted) return;
      await repository.savePreferences(next);
    });
    unawaited(_saving.catchError((Object _) {}));
  }

  bool pin(int id) {
    if (_closing) return false;
    final pins = (state['pins'] as List? ?? []).whereType<int>().toSet();
    if (!pins.remove(id)) {
      if (pins.length >= 12) return false;
      pins.add(id);
    }
    _commit({...state, 'pins': pins.toList()});
    return true;
  }

  void remember(int id) {
    final recent = (state['recent'] as List? ?? []).whereType<int>();
    _commit({
      ...state,
      'recent': [id, ...recent.where((e) => e != id)].take(8).toList(),
    });
  }

  Map<String, dynamic> chat(int id) =>
      Map<String, dynamic>.from(state['chat:$id'] as Map? ?? {});
  void updateChat(int id, Map<String, dynamic> update) {
    final next = {
      ...state,
      'chat:$id': {...chat(id), ...update},
    };
    final keys = next.keys.where((key) => key.startsWith('chat:')).toList();
    for (final key in keys.take((keys.length - 100).clamp(0, keys.length))) {
      next.remove(key);
    }
    _commit(next);
  }

  Future<void> prepareLogout() async {
    _closing = true;
    await _saving.catchError((Object _) {});
  }

  void unlock() {
    _closing = false;
  }

  void clear() => _commit({});
  void parallel(int count) =>
      _commit({...state, 'parallel': count.clamp(1, 3)});
}
