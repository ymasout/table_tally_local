/// Table Model - 桌台模型
/// Corresponds to Section 5.1 of the Development Plan
class TableModel {
  final int tableId;
  final String status; // 'idle' or 'in_use'
  final DateTime createdAt;
  final DateTime updatedAt;

  TableModel({
    required this.tableId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from Map (for SQLite)
  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      tableId: map['table_id'] as int,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'table_id': tableId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  TableModel copyWith({
    int? tableId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableModel(
      tableId: tableId ?? this.tableId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if table is currently in use
  bool get isInUse => status == 'in_use';

  /// Check if table is idle
  bool get isIdle => status == 'idle';
}
