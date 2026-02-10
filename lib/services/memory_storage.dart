import '../models/table_model.dart';
import '../models/item_model.dart';
import '../models/log_model.dart';
import 'storage_service.dart';

/// Memory Storage - 内存存储服务（用于 Web 平台）
/// 在 Web 平台上替代 SQLite，数据存储在内存中
class MemoryStorage implements StorageService {
  static final MemoryStorage instance = MemoryStorage._internal();

  MemoryStorage._internal();

  // In-memory data stores
  final Map<int, TableModel> _tables = {};
  final Map<String, ItemModel> _items = {};
  final Map<String, TableItemModel> _tableItems = {}; // key: "tableId_itemId"
  final List<LogModel> _logs = [];
  int _logIdCounter = 1;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Insert default items
    await _insertDefaultItems();
    _initialized = true;
  }

  Future<void> _insertDefaultItems() async {
    final defaultItems = [
      ItemModel(itemId: 'item_cola', name: '可乐', unit: '瓶', price: 5.0, step: 1.0, category: 'counting'),
      ItemModel(itemId: 'item_water', name: '矿泉水', unit: '瓶', price: 3.0, step: 1.0, category: 'counting'),
      ItemModel(itemId: 'item_rice', name: '米饭', unit: '碗', price: 2.0, step: 1.0, category: 'counting'),
      ItemModel(itemId: 'item_fish', name: '招牌酸菜鱼', unit: 'kg', price: 68.0, step: 0.5, category: 'weighing'),
      ItemModel(itemId: 'item_vegetable', name: '娃娃菜', unit: '斤', price: 12.0, step: 0.5, category: 'weighing'),
    ];

    for (final item in defaultItems) {
      _items[item.itemId] = item;
    }
  }

  // ==================== Tables Operations ====================

  Future<List<TableModel>> getAllTables() async {
    return _tables.values.toList()..sort((a, b) => a.tableId.compareTo(b.tableId));
  }

  Future<TableModel?> getTable(int tableId) async {
    return _tables[tableId];
  }

  Future<void> createTable(int tableId) async {
    final now = DateTime.now();
    _tables[tableId] = TableModel(
      tableId: tableId,
      status: 'idle',
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateTableStatus(int tableId, String status) async {
    final table = _tables[tableId];
    if (table != null) {
      _tables[tableId] = table.copyWith(status: status, updatedAt: DateTime.now());
    }
  }

  Future<void> clearTable(int tableId) async {
    // Update table status
    final table = _tables[tableId];
    if (table != null) {
      _tables[tableId] = table.copyWith(status: 'idle', updatedAt: DateTime.now());
    }

    // Clear all items for this table
    _tableItems.removeWhere((key, _) => key.startsWith('${tableId}_'));
  }

  // ==================== Items Operations ====================

  Future<List<ItemModel>> getAllItems() async {
    return _items.values.toList();
  }

  Future<ItemModel?> getItem(String itemId) async {
    return _items[itemId];
  }

  Future<void> addItem(ItemModel item) async {
    _items[item.itemId] = item;
  }

  Future<void> updateItem(ItemModel item) async {
    _items[item.itemId] = item;
  }

  Future<void> deleteItem(String itemId) async {
    _items.remove(itemId);
  }

  // ==================== Table Items Operations ====================

  Future<List<TableItemModel>> getTableItems(int tableId) async {
    return _tableItems.entries
        .where((e) => e.key.startsWith('${tableId}_'))
        .map((e) => e.value)
        .toList();
  }

  Future<TableItemModel?> getTableItem(int tableId, String itemId) async {
    return _tableItems['${tableId}_$itemId'];
  }

  Future<void> updateTableItemQuantity(int tableId, String itemId, double delta) async {
    final key = '${tableId}_$itemId';
    final now = DateTime.now();

    final existing = _tableItems[key];
    if (existing == null) {
      // Create new record
      _tableItems[key] = TableItemModel(
        tableId: tableId,
        itemId: itemId,
        quantity: delta,
        updatedAt: now,
      );
    } else {
      // Update existing quantity
      _tableItems[key] = existing.copyWith(
        quantity: existing.quantity + delta,
        updatedAt: now,
      );
    }

    // Log the operation
    _logs.add(LogModel(
      id: _logIdCounter++,
      tableId: tableId,
      itemId: itemId,
      delta: delta,
      timestamp: now,
    ));

    // Update table status
    final table = _tables[tableId];
    if (table != null) {
      _tables[tableId] = table.copyWith(status: 'in_use', updatedAt: now);
    }
  }

  Future<double> getTableTotal(int tableId) async {
    double total = 0.0;
    for (final entry in _tableItems.entries) {
      if (entry.key.startsWith('${tableId}_')) {
        final item = _items[entry.value.itemId];
        if (item != null) {
          total += entry.value.quantity * item.price;
        }
      }
    }
    return total;
  }

  // ==================== Operations Log ====================

  Future<List<LogModel>> getTableLogs(int tableId, {int limit = 50}) async {
    return _logs
        .where((log) => log.tableId == tableId)
        .toList()
        .reversed
        .take(limit)
        .toList();
  }

  Future<List<LogModel>> getAllLogs({int limit = 100}) async {
    return _logs.reversed.take(limit).toList();
  }

  Future<void> undoLastOperation(int tableId) async {
    // Find last log for this table
    final tableLogs = _logs.where((log) => log.tableId == tableId).toList();
    if (tableLogs.isEmpty) return;

    final lastLog = tableLogs.last;
    final reverseDelta = -lastLog.delta;
    final now = DateTime.now();

    // Update table item quantity
    final key = '${tableId}_${lastLog.itemId}';
    final existing = _tableItems[key];

    if (existing != null) {
      final newQty = existing.quantity + reverseDelta;
      if (newQty <= 0) {
        _tableItems.remove(key);
      } else {
        _tableItems[key] = existing.copyWith(quantity: newQty, updatedAt: now);
      }
    }

    // Remove the log entry
    _logs.remove(lastLog);

    // Update table timestamp
    final table = _tables[tableId];
    if (table != null) {
      _tables[tableId] = table.copyWith(updatedAt: now);
    }
  }

  // ==================== Utility ====================

  Future<void> close() async {
    // Nothing to close for in-memory storage
  }

  Future<void> clearAllData() async {
    _tableItems.clear();
    _logs.clear();
    _tables.clear();
    _logIdCounter = 1;
  }
}
