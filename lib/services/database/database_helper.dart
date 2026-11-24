import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/user.dart';
import '../../models/product.dart';
import '../../models/transaction.dart';
import '../../models/transaction_item.dart';
import '../../models/shift.dart';
import '../../models/report_summary.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_kasir.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_session (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          user_id INTEGER NOT NULL,
          shift_id INTEGER,
          logged_in INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.delete('transactions');
      await db.update('shifts', {'status': 'closed', 'end_time': DateTime.now().toIso8601String()}, where: 'status = ?', whereArgs: ['open']);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tables (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          number INTEGER NOT NULL UNIQUE,
          status TEXT NOT NULL DEFAULT 'available'
        )
      ''');
      final count = (await db.rawQuery('SELECT COUNT(*) as c FROM tables')).first['c'] as int;
      if (count == 0) {
        for (int i = 1; i <= 20; i++) {
          await db.insert('tables', {'number': i, 'status': 'available'});
        }
      }
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN table_number INTEGER');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      for (int i = 13; i <= 20; i++) {
        await db.insert('tables', {'number': i, 'status': 'available'});
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN payment_proof TEXT');
      } catch (_) {}
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'staff',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT,
        buy_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT 'Umum',
        image_path TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        starting_cash REAL NOT NULL DEFAULT 0,
        total_sales REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'open'
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        user_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        shift_id INTEGER,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        payment_method TEXT NOT NULL,
        paid_amount REAL NOT NULL,
        change_amount REAL NOT NULL,
        table_number INTEGER,
        payment_proof TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        buy_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        user_id INTEGER NOT NULL,
        shift_id INTEGER,
        logged_in INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE store_settings (
        id INTEGER PRIMARY KEY,
        store_name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        footer_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER NOT NULL UNIQUE,
        status TEXT NOT NULL DEFAULT 'available'
      )
    ''');

    for (int i = 1; i <= 20; i++) {
      await db.insert('tables', {'number': i, 'status': 'available'});
    }

    await db.insert('store_settings', {
      'id': 1,
      'store_name': 'Kasir Pintar',
      'address': 'Jl. Kasir No. 1',
      'phone': '08123456789',
      'footer_message': 'Terima kasih atas kunjungan Anda!',
    });
  }

  // --- USER & AUTH ---
  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<ShiftModel?> getShiftById(int id) async {
    final db = await database;
    final rows = await db.query('shifts', where: 'id = ? AND status = ?', whereArgs: [id, 'open'], limit: 1);
    return rows.isEmpty ? null : ShiftModel.fromMap(rows.first);
  }

  Future<void> saveSession({required int userId, int? shiftId}) async {
    final db = await database;
    await db.insert('app_session', {
      'id': 1,
      'user_id': userId,
      'shift_id': shiftId,
      'logged_in': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getSession() async {
    final db = await database;
    final rows = await db.query('app_session', where: 'id = 1 AND logged_in = 1', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('app_session', where: 'id = 1');
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final items = await txn.query('transaction_items', where: 'transaction_id = ?', whereArgs: [id]);
      for (final item in items) {
        await txn.rawUpdate('UPDATE products SET stock = stock + ? WHERE id = ?', [item['quantity'], item['product_id']]);
      }
      final transaction = await txn.query('transactions', columns: ['shift_id', 'total'], where: 'id = ?', whereArgs: [id], limit: 1);
      if (transaction.isNotEmpty && transaction.first['shift_id'] != null) {
        await txn.rawUpdate('UPDATE shifts SET total_sales = total_sales - ? WHERE id = ?', [transaction.first['total'], transaction.first['shift_id']]);
      }
      return txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<bool> hasOwner() async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['owner'],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  Future<int> createUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> authenticate(String username, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (res.isNotEmpty) return UserModel.fromMap(res.first);
    return null;
  }

  Future<UserModel?> authenticateShift(String identifier, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: '(username = ? OR name = ?) AND password = ?',
      whereArgs: [identifier, identifier, password],
      limit: 1,
    );
    if (res.isNotEmpty) return UserModel.fromMap(res.first);
    return null;
  }

  Future<List<UserModel>> getStaffList() async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['staff'],
      orderBy: 'name ASC',
    );
    return res.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- PRODUCT MANAGEMENT ---
  Future<int> insertProduct(ProductModel product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProductModel>> getProducts({
    String? search,
    String? category,
    bool activeOnly = true,
  }) async {
    final db = await database;
    String where = activeOnly ? 'is_active = 1' : '1=1';
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty && category != 'Semua') {
      where += ' AND category = ?';
      whereArgs.add(category);
    }

    if (search != null && search.trim().isNotEmpty) {
      where += ' AND (name LIKE ? OR barcode LIKE ?)';
      final pattern = '%${search.trim()}%';
      whereArgs.addAll([pattern, pattern]);
    }

    final res = await db.query(
      'products',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return res.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT DISTINCT category FROM products WHERE is_active = 1 AND category IS NOT NULL ORDER BY category ASC',
    );
    return res.map((r) => r['category'] as String).toList();
  }

  // --- SHIFTS ---
  Future<int> startShift(ShiftModel shift) async {
    final db = await database;
    return await db.insert('shifts', shift.toMap());
  }

  Future<ShiftModel?> getActiveShift() async {
    final db = await database;
    final res = await db.query(
      'shifts',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (res.isNotEmpty) return ShiftModel.fromMap(res.first);
    return null;
  }

  Future<int> closeShift(int shiftId) async {
    final db = await database;
    return await db.update(
      'shifts',
      {
        'end_time': DateTime.now().toIso8601String(),
        'status': 'closed',
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );
  }

  // --- TRANSACTIONS ---
  Future<TransactionModel> createTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.transaction((txnDb) async {
      final txnId = await txnDb.insert('transactions', txn.toMap());

      for (final item in txn.items) {
        await txnDb.insert(
          'transaction_items',
          item.copyWith(transactionId: txnId).toMap(),
        );

        await txnDb.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }

      if (txn.shiftId != null) {
        await txnDb.rawUpdate(
          'UPDATE shifts SET total_sales = total_sales + ? WHERE id = ?',
          [txn.total, txn.shiftId],
        );
      }

      if (txn.tableNumber != null) {
        await txnDb.update('tables', {'status': 'occupied'}, where: 'number = ?', whereArgs: [txn.tableNumber]);
      }

      return txn.copyWith(id: txnId);
    });
  }

  Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'created_at BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    }

    final res = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );

    List<TransactionModel> list = [];
    for (final row in res) {
      final id = row['id'] as int;
      final items = await getTransactionItems(id);
      list.add(TransactionModel.fromMap(row, items: items));
    }
    return list;
  }

  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    final db = await database;
    final res = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return res.map((m) => TransactionItemModel.fromMap(m)).toList();
  }

  // --- SALES REPORT ---
  Future<List<Map<String, dynamic>>> getSalesTrend(DateTime start, DateTime end) async {
    final db = await database;
    return db.rawQuery('''
      SELECT substr(t.created_at, 1, 10) AS day, SUM(t.total) AS revenue,
      (SELECT COALESCE(SUM((ti.sell_price - ti.buy_price) * ti.quantity), 0)
       FROM transaction_items ti INNER JOIN transactions tx ON tx.id = ti.transaction_id
       WHERE substr(tx.created_at, 1, 10) = substr(t.created_at, 1, 10)) AS profit
      FROM transactions t WHERE t.created_at BETWEEN ? AND ?
      GROUP BY day ORDER BY day ASC
    ''', [start.toIso8601String(), end.toIso8601String()]);
  }

  Future<SalesSummaryModel> getSalesSummary(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    final summaryRes = await db.rawQuery('''
      SELECT 
        COUNT(id) as total_tx,
        COALESCE(SUM(total), 0) as total_revenue,
        COALESCE(SUM(CASE WHEN LOWER(payment_method) LIKE '%tunai%' OR LOWER(payment_method) LIKE '%cash%' THEN total ELSE 0 END), 0) as cash_revenue,
        COALESCE(SUM(CASE WHEN LOWER(payment_method) LIKE '%qris%' OR LOWER(payment_method) LIKE '%non%' THEN total ELSE 0 END), 0) as qris_revenue
      FROM transactions
      WHERE created_at BETWEEN ? AND ?
    ''', [startStr, endStr]);

    final profitRes = await db.rawQuery('''
      SELECT 
        COALESCE(SUM((ti.sell_price - ti.buy_price) * ti.quantity), 0) as total_profit,
        COALESCE(SUM(ti.quantity), 0) as total_qty
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.created_at BETWEEN ? AND ?
    ''', [startStr, endStr]);

    final bestSellersRes = await db.rawQuery('''
      SELECT 
        ti.product_id,
        ti.product_name,
        SUM(ti.quantity) as total_qty,
        SUM(ti.subtotal) as total_revenue
      FROM transaction_items ti
      INNER JOIN transactions t ON ti.transaction_id = t.id
      WHERE t.created_at BETWEEN ? AND ?
      GROUP BY ti.product_id, ti.product_name
      ORDER BY total_qty DESC
      LIMIT 10
    ''', [startStr, endStr]);

    final totalRevenue = (summaryRes.first['total_revenue'] as num? ?? 0).toDouble();
    final cashRevenue = (summaryRes.first['cash_revenue'] as num? ?? 0).toDouble();
    final qrisRevenue = (summaryRes.first['qris_revenue'] as num? ?? 0).toDouble();
    final totalTransactions = (summaryRes.first['total_tx'] as num? ?? 0).toInt();
    final totalProfit = (profitRes.first['total_profit'] as num? ?? 0).toDouble();
    final totalItemsSold = (profitRes.first['total_qty'] as num? ?? 0).toInt();

    final bestSellers = bestSellersRes
        .map((r) => BestSellerModel.fromMap(r))
        .toList();

    return SalesSummaryModel(
      totalRevenue: totalRevenue,
      cashRevenue: cashRevenue,
      qrisRevenue: qrisRevenue,
      totalProfit: totalProfit,
      totalTransactions: totalTransactions,
      totalItemsSold: totalItemsSold,
      bestSellers: bestSellers,
    );
  }

  // --- STORE SETTINGS ---
  Future<Map<String, dynamic>> getStoreSettings() async {
    final db = await database;
    final res = await db.query('store_settings', where: 'id = 1');
    if (res.isNotEmpty) return res.first;
    return {
      'store_name': 'Kasir Pintar',
      'address': 'Jl. Kasir No. 1',
      'phone': '08123456789',
      'footer_message': 'Terima kasih atas kunjungan Anda!',
    };
  }

  Future<void> updateStoreSettings(Map<String, dynamic> data) async {
    final db = await database;
    await db.update('store_settings', data, where: 'id = 1');
  }

  // --- TABLES ---
  Future<List<Map<String, dynamic>>> getTables() async {
    final db = await database;
    return db.query('tables', orderBy: 'number ASC');
  }

  Future<void> setTableStatus(int number, String status) async {
    final db = await database;
    await db.update('tables', {'status': status}, where: 'number = ?', whereArgs: [number]);
  }

  Future<void> freeTable(int number) => setTableStatus(number, 'available');

  Future<void> occupyTable(int number) => setTableStatus(number, 'occupied');

  Future<void> updateUserPassword(int id, String password) async {
    final db = await database;
    await db.update(
      'users',
      {'password': password},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
