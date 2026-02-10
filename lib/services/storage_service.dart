import '../models/table_model.dart';
import '../models/item_model.dart';
import '../models/log_model.dart';

/// Storage interface abstraction
/// Allows switching between SQLite and in-memory storage based on platform
abstract class StorageService {
  // Tables operations
  Future<List<TableModel>> getAllTables();
  Future<TableModel?> getTable(int tableId);
  Future<void> createTable(int tableId);
  Future<void> updateTableStatus(int tableId, String status);
  Future<void> clearTable(int tableId);

  // Items operations
  Future<List<ItemModel>> getAllItems();
  Future<ItemModel?> getItem(String itemId);
  Future<void> addItem(ItemModel item);
  Future<void> updateItem(ItemModel item);
  Future<void> deleteItem(String itemId);

  // Table items operations
  Future<List<TableItemModel>> getTableItems(int tableId);
  Future<TableItemModel?> getTableItem(int tableId, String itemId);
  Future<void> updateTableItemQuantity(int tableId, String itemId, double delta);
  Future<double> getTableTotal(int tableId);

  // Logs operations
  Future<List<LogModel>> getTableLogs(int tableId, {int limit = 50});
  Future<List<LogModel>> getAllLogs({int limit = 100});
  Future<void> undoLastOperation(int tableId);
}
