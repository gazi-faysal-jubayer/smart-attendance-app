class SyncItem {
  final String id;
  final String tableName;
  final String recordId;
  final String operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  const SyncItem({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });
}
