import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncQueueService {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  bool _isSyncing = false;

  SyncQueueService(this._db, this._supabase);

  bool get isSyncing => _isSyncing;

  Future<void> processPendingQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final items = await _db.getPendingSyncs();
      for (final item in items) {
        if (item.retryCount > 5) continue;

        try {
          final payload =
              jsonDecode(item.payload) as Map<String, dynamic>;
          await _processItem(item.syncTableName, item.operation, payload);
          await _db.deletePendingSync(item.id);
        } catch (_) {
          await _db.incrementRetryCount(item.id);
          // Exponential backoff
          final delay = Duration(seconds: pow(2, item.retryCount).toInt());
          await Future.delayed(delay);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processItem(
    String tableName,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    switch (operation) {
      case 'insert' || 'update':
        await _supabase.from(tableName).upsert(payload);
      case 'delete':
        final id = payload['id'] as String;
        await _supabase.from(tableName).delete().eq('id', id);
    }
  }

  Future<void> addToSyncQueue({
    required String id,
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _db.insertPendingSync(PendingSyncsCompanion(
      id: Value(id),
      syncTableName: Value(tableName),
      recordId: Value(recordId),
      operation: Value(operation),
      payload: Value(jsonEncode(payload)),
      createdAt: Value(DateTime.now().toIso8601String()),
    ));
  }
}
