/// Log Model - 操作日志模型
/// Corresponds to Section 5.4 of the Development Plan
class LogModel {
  final int id;
  final int tableId;
  final String itemId;
  final double delta; // Positive for addition, negative for removal
  final DateTime timestamp;

  LogModel({
    required this.id,
    required this.tableId,
    required this.itemId,
    required this.delta,
    required this.timestamp,
  });

  /// Convert from Map (for SQLite)
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['id'] as int,
      tableId: map['table_id'] as int,
      itemId: map['item_id'] as String,
      delta: (map['delta'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  /// Convert to Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_id': tableId,
      'item_id': itemId,
      'delta': delta,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  LogModel copyWith({
    int? id,
    int? tableId,
    String? itemId,
    double? delta,
    DateTime? timestamp,
  }) {
    return LogModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      itemId: itemId ?? this.itemId,
      delta: delta ?? this.delta,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Check if this is an addition operation
  bool get isAddition => delta > 0;

  /// Check if this is a removal operation
  bool get isRemoval => delta < 0;

  /// Get formatted delta string (e.g., "+1.5", "-1")
  String get formattedDelta {
    final sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toString()}';
  }

  /// Get formatted timestamp for display
  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

/// Table Item (Table_Items junction/record)
/// Corresponds to Section 5.3 of the Development Plan
class TableItemModel {
  final int tableId;
  final String itemId;
  final double quantity;
  final DateTime updatedAt;

  TableItemModel({
    required this.tableId,
    required this.itemId,
    required this.quantity,
    required this.updatedAt,
  });

  /// Convert from Map (for SQLite)
  factory TableItemModel.fromMap(Map<String, dynamic> map) {
    return TableItemModel(
      tableId: map['table_id'] as int,
      itemId: map['item_id'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'table_id': tableId,
      'item_id': itemId,
      'quantity': quantity,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  TableItemModel copyWith({
    int? tableId,
    String? itemId,
    double? quantity,
    DateTime? updatedAt,
  }) {
    return TableItemModel(
      tableId: tableId ?? this.tableId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
