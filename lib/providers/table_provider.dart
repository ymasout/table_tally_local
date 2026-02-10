import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/table_model.dart';
import '../models/item_model.dart';
import '../models/log_model.dart';
import '../services/database_helper.dart';
import '../services/memory_storage.dart';
import '../services/storage_service.dart';

/// Table Provider - 状态管理
/// Implements core logic for adding items, calculating totals, and Voice Memo placeholder
class TableProvider with ChangeNotifier {
  // Use appropriate storage based on platform
  late final StorageService _db;

  // State
  List<TableModel> _tables = [];
  List<ItemModel> _items = [];
  Map<int, List<TableItemModel>> _tableItems = {};
  Map<int, double> _tableTotals = {};
  Map<int, List<LogModel>> _tableLogs = {};
  Map<int, bool> _hasPendingVoiceMemo = {};

  // Settings
  int _tableCount = 12; // Default table count
  static const String _tableCountKey = 'table_count';

  // Loading state
  bool _isLoading = false;
  String? _errorMessage;

  // Constructor - use appropriate storage based on platform
  TableProvider() {
    if (kIsWeb) {
      _db = MemoryStorage.instance;
    } else {
      _db = DatabaseHelper.instance;
    }
    _loadSettings();
  }

  // Getters
  List<TableModel> get tables => _tables;
  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get tableCount => _tableCount;

  /// Get items for a specific table
  List<TableItemModel> getTableItems(int tableId) {
    return _tableItems[tableId] ?? [];
  }

  /// Get total for a specific table
  double getTableTotal(int tableId) {
    return _tableTotals[tableId] ?? 0.0;
  }

  /// Get logs for a specific table
  List<LogModel> getTableLogs(int tableId) {
    return _tableLogs[tableId] ?? [];
  }

  /// Check if table has pending voice memo
  bool hasPendingVoiceMemo(int tableId) {
    return _hasPendingVoiceMemo[tableId] ?? false;
  }

  /// Initialize - load all tables and items
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadTables();
      await _loadItems();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all tables
  Future<void> _loadTables() async {
    _tables = await _db.getAllTables();

    // Load data for each table
    for (final table in _tables) {
      await loadTableData(table.tableId);
    }

    notifyListeners();
  }

  /// Load all items
  Future<void> _loadItems() async {
    _items = await _db.getAllItems();
    notifyListeners();
  }

  /// Load data for a specific table (items, total, logs)
  Future<void> loadTableData(int tableId) async {
    final items = await _db.getTableItems(tableId);
    final total = await _db.getTableTotal(tableId);
    final logs = await _db.getTableLogs(tableId);

    _tableItems[tableId] = items;
    _tableTotals[tableId] = total;
    _tableLogs[tableId] = logs;

    notifyListeners();
  }

  /// Create a new table
  Future<void> createTable(int tableId) async {
    _setLoading(true);
    try {
      await _db.createTable(tableId);
      await _loadTables();
      _clearError();
    } catch (e) {
      _setError('Failed to create table: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear a table (checkout and reset)
  Future<void> clearTable(int tableId) async {
    _setLoading(true);
    try {
      await _db.clearTable(tableId);
      await _loadTables();
      _clearError();
    } catch (e) {
      _setError('Failed to clear table: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add item to table (increment)
  Future<void> addItemToTable(int tableId, String itemId) async {
    _setLoading(true);
    try {
      final item = await _db.getItem(itemId);
      if (item == null) {
        _setError('Item not found: $itemId');
        return;
      }

      await _db.updateTableItemQuantity(tableId, itemId, item.step);
      await loadTableData(tableId);
      _clearError();
    } catch (e) {
      _setError('Failed to add item: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Remove item from table (decrement)
  Future<void> removeItemFromTable(int tableId, String itemId) async {
    _setLoading(true);
    try {
      final item = await _db.getItem(itemId);
      if (item == null) {
        _setError('Item not found: $itemId');
        return;
      }

      await _db.updateTableItemQuantity(tableId, itemId, -item.step);
      await loadTableData(tableId);
      _clearError();
    } catch (e) {
      _setError('Failed to remove item: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add custom quantity to table (for weighing items)
  Future<void> addCustomQuantity(
    int tableId,
    String itemId,
    double quantity,
  ) async {
    _setLoading(true);
    try {
      await _db.updateTableItemQuantity(tableId, itemId, quantity);
      await loadTableData(tableId);
      _clearError();
    } catch (e) {
      _setError('Failed to add quantity: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Undo last operation for a table
  Future<void> undoLastOperation(int tableId) async {
    _setLoading(true);
    try {
      await _db.undoLastOperation(tableId);
      await loadTableData(tableId);
      _clearError();
    } catch (e) {
      _setError('Failed to undo: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Voice Memo Placeholder Logic ====================
  // Section 3.2.1 of Development Plan: Voice Memo feature for busy scenarios
  // This is a placeholder implementation to be completed with audio recording

  /// Start voice memo recording (placeholder)
  /// In full implementation, this will:
  /// - Show recording UI (screen turns red)
  /// - Vibrate device
  /// - Record audio file
  Future<void> startVoiceMemo(int tableId) async {
    // TODO: Implement audio recording
    // 1. Trigger vibration feedback
    // 2. Show "Recording..." UI
    // 3. Start audio recorder
    debugPrint('Voice Memo: Recording started for table $tableId');
    notifyListeners();
  }

  /// Stop voice memo recording and save (placeholder)
  /// In full implementation, this will:
  /// - Stop recording
  /// - Save audio file locally
  /// - Mark table as having pending voice memo
  Future<void> stopVoiceMemo(int tableId) async {
    // TODO: Implement audio saving
    // 1. Stop audio recorder
    // 2. Save file to local storage
    // 3. Set pending flag for this table
    _hasPendingVoiceMemo[tableId] = true;
    debugPrint('Voice Memo: Recording stopped and saved for table $tableId');
    notifyListeners();
  }

  /// Play voice memo for a table (placeholder)
  /// In full implementation, this will:
  /// - Play the recorded audio file
  Future<void> playVoiceMemo(int tableId) async {
    // TODO: Implement audio playback
    debugPrint('Voice Memo: Playing recording for table $tableId');
    notifyListeners();
  }

  /// Mark voice memo as processed (after operator listens and processes manually)
  Future<void> markVoiceMemoProcessed(int tableId) async {
    // TODO: Implement audio file deletion/archival
    _hasPendingVoiceMemo[tableId] = false;
    debugPrint('Voice Memo: Marked as processed for table $tableId');
    notifyListeners();
  }

  /// Delete voice memo for a table (placeholder)
  Future<void> deleteVoiceMemo(int tableId) async {
    // TODO: Implement audio file deletion
    _hasPendingVoiceMemo[tableId] = false;
    debugPrint('Voice Memo: Deleted recording for table $tableId');
    notifyListeners();
  }

  // ==================== Get items by category ====================

  /// Get counting items (simple +/- buttons)
  List<ItemModel> get countingItems =>
      _items.where((item) => item.isCountingItem).toList();

  /// Get weighing items (numeric keypad)
  List<ItemModel> get weighingItems =>
      _items.where((item) => item.isWeighingItem).toList();

  // ==================== Item Management ====================

  /// Add a new item
  Future<void> addNewItem(ItemModel item) async {
    _setLoading(true);
    try {
      await _db.addItem(item);
      await _loadItems();
      _clearError();
    } catch (e) {
      _setError('Failed to add item: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing item
  Future<void> updateExistingItem(ItemModel item) async {
    _setLoading(true);
    try {
      await _db.updateItem(item);
      await _loadItems();
      _clearError();
    } catch (e) {
      _setError('Failed to update item: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an item
  Future<void> deleteExistingItem(String itemId) async {
    _setLoading(true);
    try {
      await _db.deleteItem(itemId);
      await _loadItems();
      _clearError();
    } catch (e) {
      _setError('Failed to delete item: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Private Helpers ====================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ==================== Settings Management ====================

  /// Load settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _tableCount = prefs.getInt(_tableCountKey) ?? 12;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  /// Update table count and regenerate tables
  Future<void> updateTableCount(int newCount) async {
    if (newCount < 1 || newCount > 100) {
      _setError('桌台数量必须在 1-100 之间');
      return;
    }

    _setLoading(true);
    try {
      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_tableCountKey, newCount);
      _tableCount = newCount;

      // Get current table IDs
      final existingTableIds = _tables.map((t) => t.tableId).toSet();

      // Create missing tables
      for (int i = 1; i <= newCount; i++) {
        if (!existingTableIds.contains(i)) {
          await _db.createTable(i);
        }
      }

      // Reload tables
      await _loadTables();
      _clearError();

      debugPrint('Table count updated to $newCount');
    } catch (e) {
      _setError('Failed to update table count: $e');
    } finally {
      _setLoading(false);
    }
  }
}
