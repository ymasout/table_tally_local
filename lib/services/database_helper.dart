import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/table_model.dart';
import '../models/item_model.dart';
import '../models/log_model.dart';
import 'storage_service.dart';

/// Database Helper - SQLite 数据库管理
/// Implements schema from Section 5 of the Development Plan
class DatabaseHelper implements StorageService {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize SQLite database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'table_tally.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables (Section 5 schema)
  Future<void> _onCreate(Database db, int version) async {
    // 5.1 Tables (桌台)
    await db.execute('''
      CREATE TABLE tables (
        table_id INTEGER PRIMARY KEY,
        status TEXT NOT NULL CHECK(status IN ('idle', 'in_use')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 5.2 Items (商品)
    await db.execute('''
      CREATE TABLE items (
        item_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        step REAL NOT NULL,
        category TEXT NOT NULL CHECK(category IN ('weighing', 'counting'))
      )
    ''');

    // 5.3 Table_Items (桌台明细)
    await db.execute('''
      CREATE TABLE table_items (
        table_id INTEGER NOT NULL,
        item_id TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (table_id, item_id),
        FOREIGN KEY (table_id) REFERENCES tables(table_id),
        FOREIGN KEY (item_id) REFERENCES items(item_id)
      )
    ''');

    // 5.4 Ops_Log (操作日志)
    await db.execute('''
      CREATE TABLE ops_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_id INTEGER NOT NULL,
        item_id TEXT NOT NULL,
        delta REAL NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (table_id) REFERENCES tables(table_id),
        FOREIGN KEY (item_id) REFERENCES items(item_id)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_tables_status ON tables(status)');
    await db.execute('CREATE INDEX idx_ops_log_table_id ON ops_log(table_id)');
    await db.execute('CREATE INDEX idx_ops_log_timestamp ON ops_log(timestamp)');

    // Insert default items (sample data)
    await _insertDefaultItems(db);
  }

  /// Insert default items for testing
  Future<void> _insertDefaultItems(Database db) async {
    final defaultItems = [
      // Counting items (计数类)
      {
        'item_id': 'item_cola',
        'name': '可乐',
        'unit': '瓶',
        'price': 5.0,
        'step': 1.0,
        'category': 'counting',
      },
      {
        'item_id': 'item_water',
        'name': '矿泉水',
        'unit': '瓶',
        'price': 3.0,
        'step': 1.0,
        'category': 'counting',
      },
      {
        'item_id': 'item_rice',
        'name': '米饭',
        'unit': '碗',
        'price': 2.0,
        'step': 1.0,
        'category': 'counting',
      },
      // Weighing items (称重类)
      {
        'item_id': 'item_fish',
        'name': '招牌酸菜鱼',
        'unit': 'kg',
        'price': 68.0,
        'step': 0.5,
        'category': 'weighing',
      },
      {
        'item_id': 'item_vegetable',
        'name': '娃娃菜',
        'unit': '斤',
        'price': 12.0,
        'step': 0.5,
        'category': 'weighing',
      },
    ];

    for (final item in defaultItems) {
      await db.insert('items', item);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database upgrades
  }

  // ==================== Tables Operations ====================

  /// Get all tables
  Future<List<TableModel>> getAllTables() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tables');
    return maps.map((map) => TableModel.fromMap(map)).toList();
  }

  /// Get a specific table by ID
  Future<TableModel?> getTable(int tableId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tables',
      where: 'table_id = ?',
      whereArgs: [tableId],
    );
    if (maps.isEmpty) return null;
    return TableModel.fromMap(maps.first);
  }

  /// Create a new table
  Future<void> createTable(int tableId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'tables',
      {
        'table_id': tableId,
        'status': 'idle',
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update table status
  Future<void> updateTableStatus(int tableId, String status) async {
    final db = await database;
    await db.update(
      'tables',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'table_id = ?',
      whereArgs: [tableId],
    );
  }

  /// Clear table (reset to idle)
  Future<void> clearTable(int tableId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update table status
      await txn.update(
        'tables',
        {
          'status': 'idle',
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'table_id = ?',
        whereArgs: [tableId],
      );
      // Clear all items for this table
      await txn.delete(
        'table_items',
        where: 'table_id = ?',
        whereArgs: [tableId],
      );
    });
  }

  // ==================== Items Operations ====================

  /// Get all items
  Future<List<ItemModel>> getAllItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('items');
    return maps.map((map) => ItemModel.fromMap(map)).toList();
  }

  /// Get a specific item by ID
  Future<ItemModel?> getItem(String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'items',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
    if (maps.isEmpty) return null;
    return ItemModel.fromMap(maps.first);
  }

  /// Add a new item
  Future<void> addItem(ItemModel item) async {
    final db = await database;
    await db.insert('items', item.toMap());
  }

  /// Update an item
  Future<void> updateItem(ItemModel item) async {
    final db = await database;
    await db.update(
      'items',
      item.toMap(),
      where: 'item_id = ?',
      whereArgs: [item.itemId],
    );
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    final db = await database;
    await db.delete(
      'items',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );
  }

  // ==================== Table Items Operations ====================

  /// Get all items for a specific table
  Future<List<TableItemModel>> getTableItems(int tableId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'table_items',
      where: 'table_id = ?',
      whereArgs: [tableId],
    );
    return maps.map((map) => TableItemModel.fromMap(map)).toList();
  }

  /// Get a specific table item
  Future<TableItemModel?> getTableItem(int tableId, String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'table_items',
      where: 'table_id = ? AND item_id = ?',
      whereArgs: [tableId, itemId],
    );
    if (maps.isEmpty) return null;
    return TableItemModel.fromMap(maps.first);
  }

  /// Update table item quantity (atomic operation with log)
  Future<void> updateTableItemQuantity(
    int tableId,
    String itemId,
    double delta,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();

      // Get current quantity or create new record
      final existing = await txn.query(
        'table_items',
        where: 'table_id = ? AND item_id = ?',
        whereArgs: [tableId, itemId],
      );

      if (existing.isEmpty) {
        // Create new record
        await txn.insert('table_items', {
          'table_id': tableId,
          'item_id': itemId,
          'quantity': delta,
          'updated_at': now,
        });
      } else {
        // Update existing quantity
        final currentQty = (existing.first['quantity'] as num).toDouble();
        await txn.update(
          'table_items',
          {
            'quantity': currentQty + delta,
            'updated_at': now,
          },
          where: 'table_id = ? AND item_id = ?',
          whereArgs: [tableId, itemId],
        );
      }

      // Log the operation
      await txn.insert('ops_log', {
        'table_id': tableId,
        'item_id': itemId,
        'delta': delta,
        'timestamp': now,
      });

      // Update table status and timestamp
      await txn.update(
        'tables',
        {
          'status': 'in_use',
          'updated_at': now,
        },
        where: 'table_id = ?',
        whereArgs: [tableId],
      );
    });
  }

  /// Get total amount for a table
  Future<double> getTableTotal(int tableId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(ti.quantity * i.price) as total
      FROM table_items ti
      INNER JOIN items i ON ti.item_id = i.item_id
      WHERE ti.table_id = ?
    ''', [tableId]);

    if (result.isEmpty || result.first['total'] == null) return 0.0;
    return (result.first['total'] as num).toDouble();
  }

  // ==================== Operations Log ====================

  /// Get recent logs for a table
  Future<List<LogModel>> getTableLogs(int tableId, {int limit = 50}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ops_log',
      where: 'table_id = ?',
      whereArgs: [tableId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => LogModel.fromMap(map)).toList();
  }

  /// Get all recent logs
  Future<List<LogModel>> getAllLogs({int limit = 100}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ops_log',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((map) => LogModel.fromMap(map)).toList();
  }

  /// Undo last operation for a table
  Future<void> undoLastOperation(int tableId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Get last log for this table
      final logs = await txn.query(
        'ops_log',
        where: 'table_id = ?',
        whereArgs: [tableId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (logs.isEmpty) return;

      final lastLog = LogModel.fromMap(logs.first);

      // Reverse the operation (negative delta)
      final now = DateTime.now().toIso8601String();
      final reverseDelta = -lastLog.delta;

      // Update table item quantity
      final existing = await txn.query(
        'table_items',
        where: 'table_id = ? AND item_id = ?',
        whereArgs: [tableId, lastLog.itemId],
      );

      if (existing.isNotEmpty) {
        final currentQty = (existing.first['quantity'] as num).toDouble();
        final newQty = currentQty + reverseDelta;

        if (newQty <= 0) {
          // Remove the record if quantity is 0 or less
          await txn.delete(
            'table_items',
            where: 'table_id = ? AND item_id = ?',
            whereArgs: [tableId, lastLog.itemId],
          );
        } else {
          await txn.update(
            'table_items',
            {
              'quantity': newQty,
              'updated_at': now,
            },
            where: 'table_id = ? AND item_id = ?',
            whereArgs: [tableId, lastLog.itemId],
          );
        }
      }

      // Delete the log entry
      await txn.delete(
        'ops_log',
        where: 'id = ?',
        whereArgs: [lastLog.id],
      );

      // Update table timestamp
      await txn.update(
        'tables',
        {'updated_at': now},
        where: 'table_id = ?',
        whereArgs: [tableId],
      );
    });
  }

  // ==================== Utility ====================

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('table_items');
    await db.delete('ops_log');
    await db.delete('tables');
  }
}
