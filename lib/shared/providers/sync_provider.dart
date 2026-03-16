import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'drift_db_provider.dart';
import 'connectivity_provider.dart';

enum SyncStatus { allSynced, syncing, offline }

class SyncStatusState {
  final SyncStatus status;
  final int pendingCount;

  const SyncStatusState({
    this.status = SyncStatus.allSynced,
    this.pendingCount = 0,
  });
}

final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(driftDbProvider);
  return db.watchPendingSyncCount();
});

final syncStatusProvider = Provider<SyncStatusState>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  final pendingCount = ref.watch(pendingSyncCountProvider);

  final isOnline = connectivity.valueOrNull ?? false;
  final count = pendingCount.valueOrNull ?? 0;

  if (!isOnline) {
    return SyncStatusState(status: SyncStatus.offline, pendingCount: count);
  }
  if (count > 0) {
    return SyncStatusState(status: SyncStatus.syncing, pendingCount: count);
  }
  return const SyncStatusState(status: SyncStatus.allSynced);
});
