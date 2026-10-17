import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_repository.dart';
import '../../domain/entities/play_history_entry.dart';
import '../../domain/repositories/play_history_repository.dart';
import '../../domain/services/play_history_policy.dart';
import '../../infrastructure/repositories/play_history_repository_impl.dart';

final playHistoryRepositoryProvider = Provider<PlayHistoryRepository>(
  (ref) => PlayHistoryRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

final playHistoryProvider =
    NotifierProvider<PlayHistoryController, List<PlayHistoryEntry>>(
      PlayHistoryController.new,
    );

class PlayHistoryController extends Notifier<List<PlayHistoryEntry>> {
  Future<void> _pendingWrite = Future<void>.value();

  @override
  List<PlayHistoryEntry> build() =>
      ref.watch(playHistoryRepositoryProvider).load();

  Future<void> record(int songId, {DateTime? playedAt}) async {
    state = PlayHistoryPolicy.record(
      state,
      PlayHistoryEntry(songId: songId, playedAt: playedAt ?? DateTime.now()),
    );
    final snapshot = state;
    _pendingWrite = _pendingWrite.then(
      (_) => ref.read(playHistoryRepositoryProvider).save(snapshot),
    );
    await _pendingWrite;
  }

  Future<void> clear() async {
    state = const [];
    _pendingWrite = _pendingWrite.then(
      (_) => ref.read(playHistoryRepositoryProvider).clear(),
    );
    await _pendingWrite;
  }
}
