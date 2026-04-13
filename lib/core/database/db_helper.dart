import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _databaseVersion = 4; // Incremented for partial payment support

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('poultrypro.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate egg_sales table to new order-delivery schema
      await db.execute('''
        ALTER TABLE egg_sales 
        ADD COLUMN order_date TEXT
      ''');
      await db.execute('''
        ALTER TABLE egg_sales 
        ADD COLUMN delivery_date TEXT
      ''');
      await db.execute('''
        ALTER TABLE egg_sales 
        ADD COLUMN status TEXT DEFAULT 'ordered'
      ''');
      // Migrate existing data: set sale_date as order_date, mark as delivered
      await db.execute('''
        UPDATE egg_sales 
        SET order_date = sale_date,
            delivery_date = sale_date,
            status = 'delivered'
        WHERE order_date IS NULL
      ''');
    }

    if (oldVersion < 3) {
      // Add Bluetooth sync columns to all tables
      final tables = [
        'flocks',
        'mortality_log', 
        'egg_collection',
        'egg_sales',
        'feed_purchases',
        'feed_usage',
        'expenses',
        'customer_pricing'
      ];
      
      for (final table in tables) {
        // Add device_id column
        await db.execute('''
          ALTER TABLE $table 
          ADD COLUMN device_id TEXT
        ''');
        
        // Add updated_at column (unix ms)
        await db.execute('''
          ALTER TABLE $table 
          ADD COLUMN updated_at INTEGER
        ''');
        
        // Add sync_version column
        await db.execute('''
          ALTER TABLE $table 
          ADD COLUMN sync_version INTEGER DEFAULT 0
        ''');
        
        // Add is_deleted column (soft delete)
        await db.execute('''
          ALTER TABLE $table 
          ADD COLUMN is_deleted INTEGER DEFAULT 0
        ''');
      }
      
      // Add field_versions column to egg_sales only (for field-level merge)
      await db.execute('''
        ALTER TABLE egg_sales 
        ADD COLUMN field_versions TEXT
      ''');
      
      // Create sync_log table
      await db.execute('''
        CREATE TABLE sync_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          peer_device_id TEXT NOT NULL,
          last_synced_at INTEGER NOT NULL,
          sync_direction TEXT,
          rows_sent INTEGER DEFAULT 0,
          rows_received INTEGER DEFAULT 0
        )
      ''');
      
      // Initialize updated_at for existing rows with created_at timestamp
      for (final table in tables) {
        await db.execute('''
          UPDATE $table 
          SET updated_at = CAST((julianday(created_at) - 2440587.5) * 86400000 AS INTEGER),
              device_id = 'legacy_device'
          WHERE updated_at IS NULL
        ''');
      }
    }

    if (oldVersion < 4) {
      // Add payment columns to egg_sales table
      await db.execute('''
        ALTER TABLE egg_sales 
        ADD COLUMN amount_paid REAL DEFAULT 0.0
      ''');
      await db.execute('''
        ALTER TABLE egg_sales 
        ADD COLUMN payment_status TEXT DEFAULT 'unpaid'
      ''');
      
      // Create payment_history table
      await db.execute('''
        CREATE TABLE payment_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          amount_paid REAL NOT NULL,
          payment_date TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES egg_sales (id) ON DELETE CASCADE
        )
      ''');
      
      // Create index on sale_id for faster lookups
      await db.execute('''
        CREATE INDEX idx_payment_history_sale_id ON payment_history(sale_id)
      ''');
      
      // Update existing delivered orders to be marked as paid (legacy behavior)
      await db.execute('''
        UPDATE egg_sales 
        SET amount_paid = quantity * price_per_unit,
            payment_status = 'paid'
        WHERE status = 'delivered' AND amount_paid = 0.0
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE flocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        breed TEXT NOT NULL,
        initial_count INTEGER NOT NULL,
        date_acquired TEXT NOT NULL,
        purpose TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE mortality_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        flock_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        count INTEGER NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (flock_id) REFERENCES flocks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE egg_collection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        flock_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        collected INTEGER NOT NULL,
        broken INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (flock_id) REFERENCES flocks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE egg_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_date TEXT NOT NULL,
        delivery_date TEXT,
        quantity INTEGER NOT NULL,
        price_per_unit REAL NOT NULL,
        buyer TEXT,
        status TEXT NOT NULL DEFAULT 'ordered',
        notes TEXT,
        created_at TEXT NOT NULL,
        amount_paid REAL DEFAULT 0.0,
        payment_status TEXT DEFAULT 'unpaid'
      )
    ''');

    await db.execute('''
      CREATE TABLE feed_purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        feed_type TEXT NOT NULL,
        quantity_kg REAL NOT NULL,
        price_per_unit REAL NOT NULL,
        supplier TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE feed_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        flock_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        quantity_kg REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (flock_id) REFERENCES flocks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_mortality_flock_id ON mortality_log(flock_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_mortality_date ON mortality_log(date)
    ''');
    await db.execute('''
      CREATE INDEX idx_egg_collection_flock_id ON egg_collection(flock_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_egg_collection_date ON egg_collection(date)
    ''');
    await db.execute('''
      CREATE INDEX idx_egg_sales_order_date ON egg_sales(order_date)
    ''');
    await db.execute('''
      CREATE INDEX idx_feed_purchases_date ON feed_purchases(date)
    ''');
    await db.execute('''
      CREATE INDEX idx_feed_usage_flock_id ON feed_usage(flock_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_expenses_date ON expenses(date)
    ''');

    await db.execute('''
      CREATE TABLE customer_pricing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        buyer_name TEXT NOT NULL UNIQUE,
        price_per_unit REAL NOT NULL,
        last_used_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_customer_pricing_buyer ON customer_pricing(buyer_name)
    ''');

    // Payment history table for tracking partial payments
    await db.execute('''
      CREATE TABLE payment_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        amount_paid REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES egg_sales (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_payment_history_sale_id ON payment_history(sale_id)
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Flock operations
  Future<int> insertFlock(Flock flock) async {
    final db = await database;
    return await db.insert('flocks', flock.toMap());
  }

  Future<List<Flock>> getAllFlocks() async {
    final db = await database;
    final maps = await db.query('flocks', orderBy: 'date_acquired DESC');
    return maps.map((map) => Flock.fromMap(map)).toList();
  }

  Future<Flock?> getFlock(int id) async {
    final db = await database;
    final maps = await db.query('flocks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Flock.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateFlock(Flock flock) async {
    final db = await database;
    return await db.update(
      'flocks',
      flock.toMap(),
      where: 'id = ?',
      whereArgs: [flock.id],
    );
  }

  Future<int> deleteFlock(int id) async {
    final db = await database;
    return await db.delete('flocks', where: 'id = ?', whereArgs: [id]);
  }

  // Mortality operations
  Future<int> insertMortality(MortalityLog mortality) async {
    final db = await database;
    return await db.insert('mortality_log', mortality.toMap());
  }

  Future<List<MortalityLog>> getMortalityByFlock(int flockId) async {
    final db = await database;
    final maps = await db.query(
      'mortality_log',
      where: 'flock_id = ?',
      whereArgs: [flockId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => MortalityLog.fromMap(map)).toList();
  }

  Future<int> getTotalMortalityByFlock(int flockId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(count) as total FROM mortality_log WHERE flock_id = ?',
      [flockId],
    );
    return result.first['total'] as int? ?? 0;
  }

  Future<int> updateMortality(MortalityLog mortality) async {
    final db = await database;
    return await db.update(
      'mortality_log',
      mortality.toMap(),
      where: 'id = ?',
      whereArgs: [mortality.id],
    );
  }

  Future<int> deleteMortality(int id) async {
    final db = await database;
    return await db.delete('mortality_log', where: 'id = ?', whereArgs: [id]);
  }

  // Egg collection operations
  Future<int> insertEggCollection(EggCollection collection) async {
    final db = await database;
    return await db.insert('egg_collection', collection.toMap());
  }

  Future<List<EggCollection>> getEggCollectionsByFlock(int flockId) async {
    final db = await database;
    final maps = await db.query(
      'egg_collection',
      where: 'flock_id = ?',
      whereArgs: [flockId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => EggCollection.fromMap(map)).toList();
  }

  Future<List<EggCollection>> getEggCollectionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'egg_collection',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => EggCollection.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getEggCollectionSummary() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(collected), 0) as total_collected,
        COALESCE(SUM(broken), 0) as total_broken,
        COALESCE(SUM(collected - broken), 0) as good_eggs,
        COUNT(*) as total_records
      FROM egg_collection
      WHERE date >= ? AND date < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    return {
      'good': (result.first['good_eggs'] as num?)?.toInt() ?? 0,
      'broken': (result.first['total_broken'] as num?)?.toInt() ?? 0,
      'total_quantity': (result.first['total_collected'] as num?)?.toInt() ?? 0,
      'total_records': result.first['total_records'] as int? ?? 0,
    };
  }

  Future<int> updateEggCollection(EggCollection collection) async {
    final db = await database;
    return await db.update(
      'egg_collection',
      collection.toMap(),
      where: 'id = ?',
      whereArgs: [collection.id],
    );
  }

  Future<int> deleteEggCollection(int id) async {
    final db = await database;
    return await db.delete('egg_collection', where: 'id = ?', whereArgs: [id]);
  }

  // Egg sales operations
  Future<int> insertEggSale(EggSale sale) async {
    final db = await database;
    return await db.insert('egg_sales', sale.toMap());
  }

  Future<List<EggSale>> getAllEggSales() async {
    final db = await database;
    final maps = await db.query('egg_sales', orderBy: 'order_date DESC');
    return maps.map((map) => EggSale.fromMap(map)).toList();
  }

  Future<List<EggSale>> getEggSalesByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'egg_sales',
      where: 'order_date >= ? AND order_date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'order_date DESC',
    );
    return maps.map((map) => EggSale.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getEggSalesSummary(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT 
        SUM(quantity) as total_quantity,
        SUM(CASE WHEN status = 'delivered' THEN quantity * price_per_unit ELSE 0 END) as total_revenue
      FROM egg_sales 
      WHERE delivery_date >= ? AND delivery_date < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

    return {
      'quantity': result.first['total_quantity'] as int? ?? 0,
      'revenue': result.first['total_revenue'] as double? ?? 0.0,
    };
  }

  // Monthly Reports
  Future<Map<String, dynamic>> getMonthlyEggCollectionReport(
      int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT 
        SUM(collected) as total_collected,
        SUM(broken) as total_broken,
        COUNT(DISTINCT flock_id) as active_flocks,
        COUNT(*) as collection_days,
        AVG(collected) as avg_daily_collection
      FROM egg_collection 
      WHERE date >= ? AND date < ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Get daily breakdown
    final dailyResult = await db.rawQuery('''
      SELECT 
        date,
        SUM(collected) as daily_collected,
        SUM(broken) as daily_broken
      FROM egg_collection 
      WHERE date >= ? AND date < ?
      GROUP BY date
      ORDER BY date
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return {
      'total_collected': result.first['total_collected'] as int? ?? 0,
      'total_broken': result.first['total_broken'] as int? ?? 0,
      'total_good_eggs': ((result.first['total_collected'] as int? ?? 0) -
          (result.first['total_broken'] as int? ?? 0)),
      'active_flocks': result.first['active_flocks'] as int? ?? 0,
      'collection_days': result.first['collection_days'] as int? ?? 0,
      'avg_daily_collection':
          result.first['avg_daily_collection'] as double? ?? 0.0,
      'daily_breakdown': dailyResult,
    };
  }

  Future<Map<String, dynamic>> getMonthlyDeliveredOrdersReport(
      int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT 
        SUM(quantity) as delivered_quantity,
        SUM(quantity * price_per_unit) as delivered_revenue,
        COUNT(*) as delivered_orders,
        AVG(price_per_unit) as avg_price_per_egg
      FROM egg_sales 
      WHERE status = 'delivered' 
        AND delivery_date >= ? AND delivery_date < ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final buyerResult = await db.rawQuery('''
      SELECT 
        buyer,
        SUM(quantity) as quantity,
        SUM(quantity * price_per_unit) as revenue
      FROM egg_sales 
      WHERE status = 'delivered' 
        AND delivery_date >= ? AND delivery_date < ?
        AND buyer IS NOT NULL
      GROUP BY buyer
      ORDER BY quantity DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return {
      'delivered_quantity': result.first['delivered_quantity'] as int? ?? 0,
      'delivered_revenue': result.first['delivered_revenue'] as double? ?? 0.0,
      'delivered_orders': result.first['delivered_orders'] as int? ?? 0,
      'avg_price_per_egg': result.first['avg_price_per_egg'] as double? ?? 0.0,
      'buyer_breakdown': buyerResult,
    };
  }

  Future<Map<String, dynamic>> getMonthlySalesReport(
      int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    // Uses new schema: order_date, delivery_date, status ('ordered'|'delivered'|'cancelled')
    // "paid" = delivered orders, "credit" = still-ordered (pending) orders
    final result = await db.rawQuery('''
      SELECT 
        SUM(quantity) as total_quantity,
        SUM(CASE WHEN status = 'delivered' THEN quantity * price_per_unit ELSE 0 END) as paid_revenue,
        SUM(CASE WHEN status = 'ordered' THEN quantity * price_per_unit ELSE 0 END) as credit_amount,
        COUNT(*) as total_sales,
        COUNT(CASE WHEN status = 'delivered' THEN 1 END) as paid_sales,
        COUNT(CASE WHEN status = 'ordered' THEN 1 END) as credit_sales,
        AVG(price_per_unit) as avg_price_per_egg
      FROM egg_sales 
      WHERE order_date >= ? AND order_date < ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Get sales by buyer
    final buyerResult = await db.rawQuery('''
   SELECT 
  buyer,
  SUM(quantity) AS quantity,
  SUM(quantity * price_per_unit) AS revenue,
  COUNT(*) AS sales_count
FROM egg_sales 
WHERE 
  order_date >= ? 
  AND order_date < ? 
  AND buyer IS NOT NULL
  AND status = 'delivered'
GROUP BY buyer
ORDER BY revenue DESC;
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Get daily breakdown
    final dailyResult = await db.rawQuery('''
      SELECT 
        order_date as date,
        SUM(quantity) as daily_quantity,
        SUM(CASE WHEN status = 'delivered' THEN quantity * price_per_unit ELSE 0 END) as daily_revenue
      FROM egg_sales 
      WHERE order_date >= ? AND order_date < ?
      GROUP BY order_date
      ORDER BY order_date
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return {
      'total_quantity': result.first['total_quantity'] as int? ?? 0,
      'paid_revenue': result.first['paid_revenue'] as double? ?? 0.0,
      'credit_amount': result.first['credit_amount'] as double? ?? 0.0,
      'total_revenue': ((result.first['paid_revenue'] as double? ?? 0.0) +
          (result.first['credit_amount'] as double? ?? 0.0)),
      'total_sales': result.first['total_sales'] as int? ?? 0,
      'paid_sales': result.first['paid_sales'] as int? ?? 0,
      'credit_sales': result.first['credit_sales'] as int? ?? 0,
      'avg_price_per_egg': result.first['avg_price_per_egg'] as double? ?? 0.0,
      'buyer_breakdown': buyerResult,
      'daily_breakdown': dailyResult,
    };
  }

  Future<int> updateEggSale(EggSale sale) async {
    final db = await database;
    return await db.update(
      'egg_sales',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> deleteEggSale(int id) async {
    final db = await database;
    return await db.delete('egg_sales', where: 'id = ?', whereArgs: [id]);
  }

  // Payment history operations
  Future<int> insertPayment(PaymentHistory payment) async {
    final db = await database;
    return await db.insert('payment_history', payment.toMap());
  }

  Future<List<PaymentHistory>> getPaymentsBySale(int saleId) async {
    final db = await database;
    final maps = await db.query(
      'payment_history',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((map) => PaymentHistory.fromMap(map)).toList();
  }

  Future<double> getTotalPaidForSale(int saleId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_paid), 0) as total FROM payment_history WHERE sale_id = ?',
      [saleId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete('payment_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        es.id,
        es.buyer,
        es.quantity,
        es.price_per_unit,
        es.amount_paid,
        (es.quantity * es.price_per_unit - es.amount_paid) as balance_due,
        es.delivery_date
      FROM egg_sales es
      WHERE es.status = 'delivered' 
        AND es.payment_status != 'paid'
      ORDER BY es.delivery_date DESC
    ''');
  }

  Future<double> getOutstandingPaymentsAmount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity * price_per_unit - amount_paid), 0) as total_outstanding
      FROM egg_sales
      WHERE status = 'delivered' AND payment_status != 'paid'
    ''');
    return (result.first['total_outstanding'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>> getSalePaymentSummary(int saleId) async {
    final db = await database;
    final saleResult = await db.query(
      'egg_sales',
      where: 'id = ?',
      whereArgs: [saleId],
    );
    if (saleResult.isEmpty) {
      return {'total_amount': 0.0, 'amount_paid': 0.0, 'balance_due': 0.0};
    }

    final sale = saleResult.first;
    final totalAmount = (sale['quantity'] as int) * (sale['price_per_unit'] as double);
    final amountPaid = (sale['amount_paid'] as double?) ?? 0.0;

    return {
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'balance_due': totalAmount - amountPaid,
      'payment_status': sale['payment_status'] ?? 'unpaid',
    };
  }

  Future<List<Map<String, dynamic>>> getOverduePayments({int daysOverdue = 7}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOverdue));
    return await db.rawQuery('''
      SELECT 
        es.id,
        es.buyer,
        es.quantity,
        es.price_per_unit,
        es.amount_paid,
        (es.quantity * es.price_per_unit - es.amount_paid) as balance_due,
        es.delivery_date
      FROM egg_sales es
      WHERE es.status = 'delivered' 
        AND es.payment_status != 'paid'
        AND es.delivery_date < ?
      ORDER BY es.delivery_date ASC
    ''', [cutoffDate.toIso8601String()]);
  }

  /// Get pending/undelivered orders for pre-order tracking
  Future<List<EggSale>> getPendingOrders() async {
    final db = await database;
    final maps = await db.query(
      'egg_sales',
      where: 'status = ?',
      whereArgs: ['ordered'],
      orderBy: 'order_date ASC',
    );
    return maps.map((map) => EggSale.fromMap(map)).toList();
  }

  /// Get pending orders count for quick dashboard stats
  Future<int> getPendingOrdersCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM egg_sales WHERE status = 'ordered'
    ''');
    return result.first['count'] as int? ?? 0;
  }

  /// Get total good eggs collected (all time or up to a date)
  Future<int> getTotalEggsCollected({DateTime? upToDate}) async {
    final db = await database;
    final date = upToDate ?? DateTime.now();
    final endOfDay = date.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(collected - broken), 0) as total_good
      FROM egg_collection
      WHERE date < ?
    ''', [endOfDay.toIso8601String()]);

    return (result.first['total_good'] as num?)?.toInt() ?? 0;
  }

  /// Get total eggs delivered (sold) up to a date
  Future<int> getTotalEggsDelivered({DateTime? upToDate}) async {
    final db = await database;
    final date = upToDate ?? DateTime.now();
    final endOfDay = date.add(const Duration(days: 1));

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity), 0) as total_delivered
      FROM egg_sales
      WHERE status = 'delivered' AND delivery_date < ?
    ''', [endOfDay.toIso8601String()]);

    return (result.first['total_delivered'] as num?)?.toInt() ?? 0;
  }

  /// Get remaining egg stock (collected - delivered)
  Future<int> getRemainingEggStock() async {
    final totalCollected = await getTotalEggsCollected();
    final totalDelivered = await getTotalEggsDelivered();
    return totalCollected - totalDelivered;
  }

  /// Get pending order count (eggs in ordered status)
  Future<int> getPendingOrderEggCount() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity), 0) as total_pending
      FROM egg_sales
      WHERE status = 'ordered'
    ''');

    return (result.first['total_pending'] as num?)?.toInt() ?? 0;
  }

  /// Get complete inventory summary
  Future<Map<String, int>> getInventorySummary() async {
    final totalCollected = await getTotalEggsCollected();
    final totalDelivered = await getTotalEggsDelivered();
    final pending = await getPendingOrderEggCount();

    return {
      'total_collected': totalCollected,
      'total_delivered': totalDelivered,
      'remaining_stock': totalCollected - totalDelivered,
      'pending_orders': pending,
      'available_for_sale': totalCollected - totalDelivered - pending,
    };
  }

  // Monthly Reports for Egg Management
  /// Get comprehensive monthly egg report
  Future<Map<String, dynamic>> getMonthlyEggReport(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    // Eggs collected this month
    final collectedResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(collected), 0) as total_laid,
        COALESCE(SUM(broken), 0) as total_broken,
        COALESCE(SUM(collected - broken), 0) as total_good
      FROM egg_collection
      WHERE date >= ? AND date < ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Eggs sold/delivered this month
    final soldResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(quantity), 0) as total_sold,
        COALESCE(SUM(quantity * price_per_unit), 0) as total_revenue,
        COUNT(*) as order_count
      FROM egg_sales
      WHERE status = 'delivered' 
        AND delivery_date >= ? AND delivery_date < ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    // Cumulative stock (all time up to end of this month)
    final cumulativeResult = await db.rawQuery('''
      SELECT 
        COALESCE((SELECT SUM(collected - broken) FROM egg_collection WHERE date < ?), 0) -
        COALESCE((SELECT SUM(quantity) FROM egg_sales WHERE status = 'delivered' AND delivery_date < ?), 0)
        as remaining_stock
    ''', [endDate.toIso8601String(), endDate.toIso8601String()]);

    // Pending orders at month end
    final pendingResult = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity), 0) as pending_eggs
      FROM egg_sales
      WHERE status = 'ordered' AND order_date < ?
    ''', [endDate.toIso8601String()]);

    // Daily breakdown for the month
    final dailyResult = await db.rawQuery('''
      SELECT 
        date(date) as day,
        SUM(collected) as laid,
        SUM(broken) as broken,
        SUM(collected - broken) as good
      FROM egg_collection
      WHERE date >= ? AND date < ?
      GROUP BY day
      ORDER BY day
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return {
      'year': year,
      'month': month,
      'eggs_laid': (collectedResult.first['total_good'] as num?)?.toInt() ?? 0,
      'eggs_broken':
          (collectedResult.first['total_broken'] as num?)?.toInt() ?? 0,
      'eggs_sold': (soldResult.first['total_sold'] as num?)?.toInt() ?? 0,
      'revenue': (soldResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0,
      'order_count': (soldResult.first['order_count'] as num?)?.toInt() ?? 0,
      'remaining_stock':
          (cumulativeResult.first['remaining_stock'] as num?)?.toInt() ?? 0,
      'pending_orders':
          (pendingResult.first['pending_eggs'] as num?)?.toInt() ?? 0,
      'daily_breakdown': dailyResult,
    };
  }

  // Customer pricing operations
  Future<double?> getCustomerPrice(String buyerName) async {
    final db = await database;
    final result = await db.query(
      'customer_pricing',
      columns: ['price_per_unit'],
      where: 'buyer_name = ?',
      whereArgs: [buyerName.toLowerCase().trim()],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['price_per_unit'] as double;
    }
    return null;
  }

  Future<void> saveCustomerPrice(String buyerName, double pricePerUnit) async {
    final db = await database;
    final normalizedName = buyerName.toLowerCase().trim();
    final now = DateTime.now();

    await db.insert(
      'customer_pricing',
      {
        'buyer_name': normalizedName,
        'price_per_unit': pricePerUnit,
        'last_used_date': now.toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllCustomerPrices() async {
    final db = await database;
    return await db.query(
      'customer_pricing',
      orderBy: 'last_used_date DESC',
    );
  }

  // Feed purchase operations
  Future<int> insertFeedPurchase(FeedPurchase purchase) async {
    final db = await database;
    return await db.insert('feed_purchases', purchase.toMap());
  }

  Future<List<FeedPurchase>> getAllFeedPurchases() async {
    final db = await database;
    final maps = await db.query('feed_purchases', orderBy: 'date DESC');
    return maps.map((map) => FeedPurchase.fromMap(map)).toList();
  }

  Future<double> getTotalFeedPurchased() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity_kg) as total FROM feed_purchases',
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<int> updateFeedPurchase(FeedPurchase purchase) async {
    final db = await database;
    return await db.update(
      'feed_purchases',
      purchase.toMap(),
      where: 'id = ?',
      whereArgs: [purchase.id],
    );
  }

  Future<int> deleteFeedPurchase(int id) async {
    final db = await database;
    return await db.delete('feed_purchases', where: 'id = ?', whereArgs: [id]);
  }

  // Feed usage operations
  Future<int> insertFeedUsage(FeedUsage usage) async {
    final db = await database;
    return await db.insert('feed_usage', usage.toMap());
  }

  Future<List<FeedUsage>> getFeedUsageByFlock(int flockId) async {
    final db = await database;
    final maps = await db.query(
      'feed_usage',
      where: 'flock_id = ?',
      whereArgs: [flockId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => FeedUsage.fromMap(map)).toList();
  }

  Future<double> getTotalFeedUsed() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity_kg) as total FROM feed_usage',
    );
    return result.first['total'] as double? ?? 0.0;
  }

  Future<int> updateFeedUsage(FeedUsage usage) async {
    final db = await database;
    return await db.update(
      'feed_usage',
      usage.toMap(),
      where: 'id = ?',
      whereArgs: [usage.id],
    );
  }

  Future<int> deleteFeedUsage(int id) async {
    final db = await database;
    return await db.delete('feed_usage', where: 'id = ?', whereArgs: [id]);
  }

  // Expense operations
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<Map<String, double>> getExpensesByCategory(
      DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total 
      FROM expenses 
      WHERE date >= ? AND date <= ?
      GROUP BY category
    ''', [start.toIso8601String(), end.toIso8601String()]);

    return Map.fromEntries(
      result.map((row) => MapEntry(
            row['category'] as String,
            row['total'] as double,
          )),
    );
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Analytics queries
  Future<List<Map<String, dynamic>>> getWeeklyEggProduction() async {
    final db = await database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final result = await db.rawQuery('''
      SELECT 
        date(date) as day,
        SUM(collected - broken) as good_eggs
      FROM egg_collection 
      WHERE date >= ?
      GROUP BY day
      ORDER BY day
    ''', [weekAgo.toIso8601String()]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getMonthlyEggProduction(
      int year, int month) async {
    final db = await database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final result = await db.rawQuery('''
      SELECT 
        date(date) as day,
        SUM(collected) as collected,
        SUM(broken) as broken,
        SUM(collected - broken) as good_eggs
      FROM egg_collection 
      WHERE date >= ? AND date < ?
      GROUP BY day
      ORDER BY day
    ''', [start.toIso8601String(), end.toIso8601String()]);

    return result;
  }

  Future<Map<String, dynamic>> getProfitLossSummary(
      DateTime start, DateTime end) async {
    final db = await database;

    // Uses new schema: status = 'delivered' means revenue realized
    // status = 'ordered' means pending (credit equivalent)
    final eggSales = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN status = 'delivered' THEN quantity * price_per_unit ELSE 0 END), 0) as paid_total,
             COALESCE(SUM(CASE WHEN status = 'ordered' THEN quantity * price_per_unit ELSE 0 END), 0) as credit_total
      FROM egg_sales 
      WHERE order_date >= ? AND order_date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final feedCosts = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity_kg * price_per_unit), 0) as total 
      FROM feed_purchases 
      WHERE date >= ? AND date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final otherExpenses = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total 
      FROM expenses 
      WHERE date >= ? AND date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final paidRevenue = (eggSales.first['paid_total'] as num).toDouble();
    final creditAmount = (eggSales.first['credit_total'] as num).toDouble();
    final totalRevenue = paidRevenue + creditAmount;
    final expenses = (feedCosts.first['total'] as num).toDouble() +
        (otherExpenses.first['total'] as num).toDouble();

    return {
      'egg_sales': (eggSales.first['paid_total'] as num).toDouble(),
      'egg_sales_paid': (eggSales.first['paid_total'] as num).toDouble(),
      'egg_sales_credit': creditAmount,
      'egg_sales_total': totalRevenue,
      'total_revenue': paidRevenue,
      'total_revenue_with_credit': totalRevenue,
      'feed_costs': (feedCosts.first['total'] as num).toDouble(),
      'other_expenses': (otherExpenses.first['total'] as num).toDouble(),
      'total_expenses': expenses,
      'profit_loss': paidRevenue - expenses,
    };
  }

  Future<Map<String, dynamic>> getMortalityAnalysis() async {
    final db = await database;

    // Total mortality by flock
    final flockMortality = await db.rawQuery('''
      SELECT 
        f.id as flock_id,
        f.breed,
        f.initial_count,
        COALESCE(SUM(m.count), 0) as total_deaths,
        f.date_acquired
      FROM flocks f
      LEFT JOIN mortality_log m ON f.id = m.flock_id
      GROUP BY f.id
      ORDER BY f.date_acquired DESC
    ''');

    // Mortality by date (for trend analysis)
    final dailyMortality = await db.rawQuery('''
      SELECT 
        date,
        SUM(count) as deaths
      FROM mortality_log
      GROUP BY date
      ORDER BY date DESC
      LIMIT 30
    ''');

    // Overall statistics
    final stats = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(f.initial_count), 0) as total_initial,
        COALESCE(SUM(m.total_deaths), 0) as total_deaths,
        COUNT(DISTINCT f.id) as total_flocks
      FROM flocks f
      LEFT JOIN (
        SELECT flock_id, SUM(count) as total_deaths
        FROM mortality_log
        GROUP BY flock_id
      ) m ON f.id = m.flock_id
    ''');

    final totalInitial = (stats.first['total_initial'] as num?)?.toInt() ?? 0;
    final totalDeaths = (stats.first['total_deaths'] as num?)?.toInt() ?? 0;
    final mortalityRate =
        totalInitial > 0 ? (totalDeaths / totalInitial) * 100 : 0.0;

    return {
      'flock_mortality': flockMortality,
      'daily_mortality': dailyMortality,
      'total_initial': totalInitial,
      'total_deaths': totalDeaths,
      'mortality_rate': mortalityRate,
      'total_flocks': (stats.first['total_flocks'] as num?)?.toInt() ?? 0,
    };
  }

  Future<Map<String, dynamic>> getSalesSummary() async {
    final db = await database;

    try {
      // Overall sales statistics
      final overallStats = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(quantity), 0) as total_eggs_sold,
          COALESCE(SUM(CASE WHEN status = 'delivered' THEN quantity * price_per_unit ELSE 0 END), 0) as total_revenue,
          COUNT(*) as total_orders,
          COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered_orders,
          COUNT(CASE WHEN status = 'ordered' THEN 1 END) as pending_orders,
          COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_orders
        FROM egg_sales
      ''');

      // Top buyers
      final topBuyers = await db.rawQuery('''
        SELECT 
          buyer,
          COUNT(*) as order_count,
          SUM(quantity) as total_quantity,
          SUM(CASE WHEN status = 'delivered' THEN quantity * price_per_unit ELSE 0 END) as total_revenue
        FROM egg_sales
        WHERE buyer IS NOT NULL AND buyer != ''
        GROUP BY buyer
        ORDER BY total_revenue DESC
        LIMIT 5
      ''');

      return {
        'total_eggs_sold':
            (overallStats.first['total_eggs_sold'] as num?)?.toInt() ?? 0,
        'total_revenue':
            (overallStats.first['total_revenue'] as num?)?.toDouble() ?? 0.0,
        'total_orders':
            (overallStats.first['total_orders'] as num?)?.toInt() ?? 0,
        'delivered_orders':
            (overallStats.first['delivered_orders'] as num?)?.toInt() ?? 0,
        'pending_orders':
            (overallStats.first['pending_orders'] as num?)?.toInt() ?? 0,
        'cancelled_orders':
            (overallStats.first['cancelled_orders'] as num?)?.toInt() ?? 0,
        'top_buyers': topBuyers,
      };
    } catch (e) {
      throw Exception('Failed to load sales summary: $e');
    }
  }

  // Backup and restore
  Future<Map<String, List<Map<String, dynamic>>>> exportAllData() async {
    final db = await database;

    return {
      'flocks': await db.query('flocks'),
      'mortality_log': await db.query('mortality_log'),
      'egg_collection': await db.query('egg_collection'),
      'egg_sales': await db.query('egg_sales'),
      'feed_purchases': await db.query('feed_purchases'),
      'feed_usage': await db.query('feed_usage'),
      'expenses': await db.query('expenses'),
      'customer_pricing': await db.query('customer_pricing'),
      'sync_log': await db.query('sync_log'),
      'payment_history': await db.query('payment_history'),
    };
  }

  Future<void> importAllData(
      Map<String, List<Map<String, dynamic>>> data) async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('payment_history');
      await txn.delete('sync_log');
      await txn.delete('customer_pricing');
      await txn.delete('expenses');
      await txn.delete('feed_usage');
      await txn.delete('feed_purchases');
      await txn.delete('egg_sales');
      await txn.delete('egg_collection');
      await txn.delete('mortality_log');
      await txn.delete('flocks');

      // Import new data
      for (final row in data['flocks'] ?? []) {
        await txn.insert('flocks', row);
      }
      for (final row in data['mortality_log'] ?? []) {
        await txn.insert('mortality_log', row);
      }
      for (final row in data['egg_collection'] ?? []) {
        await txn.insert('egg_collection', row);
      }
      for (final row in data['egg_sales'] ?? []) {
        await txn.insert('egg_sales', row);
      }
      for (final row in data['feed_purchases'] ?? []) {
        await txn.insert('feed_purchases', row);
      }
      for (final row in data['feed_usage'] ?? []) {
        await txn.insert('feed_usage', row);
      }
      for (final row in data['expenses'] ?? []) {
        await txn.insert('expenses', row);
      }
      for (final row in data['customer_pricing'] ?? []) {
        await txn.insert('customer_pricing', row);
      }
      for (final row in data['sync_log'] ?? []) {
        await txn.insert('sync_log', row);
      }
      for (final row in data['payment_history'] ?? []) {
        await txn.insert('payment_history', row);
      }
    });
  }
}
