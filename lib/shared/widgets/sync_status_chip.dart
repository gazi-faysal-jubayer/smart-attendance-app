import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/sync_provider.dart';

class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);

    final (color, icon, label) = switch (syncState.status) {
      SyncStatus.allSynced => (
          AppColors.success,
          Icons.cloud_done,
          'All synced'
        ),
      SyncStatus.syncing => (
          Colors.amber,
          Icons.sync,
          '${syncState.pendingCount} unsynced'
        ),
      SyncStatus.offline => (
          AppColors.error,
          Icons.cloud_off,
          'Offline'
        ),
    };

    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onPressed: () {
        // TODO: Trigger manual sync
      },
    );
  }
}
