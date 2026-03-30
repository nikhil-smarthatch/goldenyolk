import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

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
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
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
        date TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price_per_unit REAL NOT NULL,
        buyer TEXT,
        payment_status TEXT NOT NULL DEFAULT 'paid',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chicken_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        flock_id INTEGER,
        date TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price_per_bird REAL NOT NULL,
        buyer TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (flock_id) REFERENCES flocks (id) ON DELETE SET NULL
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
      CREATE INDEX idx_egg_sales_date ON egg_sales(date)
    ''');
    await db.execute('''
      CREATE INDEX idx_chicken_sales_date ON chicken_sales(date)
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

  Future<Map<String, dynamic>> getEggCollectionSummary(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await db.rawQuery('''
      SELECT 
        SUM(collected) as total_collected,
        SUM(broken) as total_broken,
        SUM(collected - broken) as total_good
      FROM egg_collection 
      WHERE date >= ? AND date < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    
    return {
      'collected': result.first['total_collected'] as int? ?? 0,
      'broken': result.first['total_broken'] as int? ?? 0,
      'good': result.first['total_good'] as int? ?? 0,
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
    final maps = await db.query('egg_sales', orderBy: 'date DESC');
    return maps.map((map) => EggSale.fromMap(map)).toList();
  }

  Future<List<EggSale>> getEggSalesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'egg_sales',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
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
        SUM(CASE WHEN payment_status = 'paid' THEN quantity * price_per_unit ELSE 0 END) as total_revenue,
        SUM(CASE WHEN payment_status = 'credit' THEN quantity * price_per_unit ELSE 0 END) as credit_amount
      FROM egg_sales 
      WHERE date >= ? AND date < ?
    ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
    
    return {
      'quantity': result.first['total_quantity'] as int? ?? 0,
      'revenue': result.first['total_revenue'] as double? ?? 0.0,
      'credit': result.first['credit_amount'] as double? ?? 0.0,
    };
  }

  // Monthly Reports
  Future<Map<String, dynamic>> getMonthlyEggCollectionReport(int year, int month) async {
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
      'total_good_eggs': ((result.first['total_collected'] as int? ?? 0) - (result.first['total_broken'] as int? ?? 0)),
      'active_flocks': result.first['active_flocks'] as int? ?? 0,
      'collection_days': result.first['collection_days'] as int? ?? 0,
      'avg_daily_collection': result.first['avg_daily_collection'] as double? ?? 0.0,
      'daily_breakdown': dailyResult,
    };
  }

  Future<Map<String, dynamic>> getMonthlySalesReport(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);
    
    final result = await db.rawQuery('''
      SELECT 
        SUM(quantity) as total_quantity,
        SUM(CASE WHEN payment_status = 'paid' THEN quantity * price_per_unit ELSE 0 END) as paid_revenue,
        SUM(CASE WHEN payment_status = 'credit' THEN quantity * price_per_unit ELSE 0 END) as credit_amount,
        COUNT(*) as total_sales,
        COUNT(CASE WHEN payment_status = 'paid' THEN 1 END) as paid_sales,
        COUNT(CASE WHEN payment_status = 'credit' THEN 1 END) as credit_sales,
        AVG(price_per_unit) as avg_price_per_egg
      FROM egg_sales 
      WHERE date >= ? AND date < ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    // Get sales by buyer
    final buyerResult = await db.rawQuery('''
      SELECT 
        buyer,
        SUM(quantity) as quantity,
        SUM(CASE WHEN payment_status = 'paid' THEN quantity * price_per_unit ELSE 0 END) as revenue,
        COUNT(*) as sales_count
      FROM egg_sales 
      WHERE date >= ? AND date < ? AND buyer IS NOT NULL
      GROUP BY buyer
      ORDER BY revenue DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    // Get daily breakdown
    final dailyResult = await db.rawQuery('''
      SELECT 
        date,
        SUM(quantity) as daily_quantity,
        SUM(CASE WHEN payment_status = 'paid' THEN quantity * price_per_unit ELSE 0 END) as daily_revenue
      FROM egg_sales 
      WHERE date >= ? AND date < ?
      GROUP BY date
      ORDER BY date
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    return {
      'total_quantity': result.first['total_quantity'] as int? ?? 0,
      'paid_revenue': result.first['paid_revenue'] as double? ?? 0.0,
      'credit_amount': result.first['credit_amount'] as double? ?? 0.0,
      'total_revenue': ((result.first['paid_revenue'] as double? ?? 0.0) + (result.first['credit_amount'] as double? ?? 0.0)),
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

  // Chicken sales operations
  Future<int> insertChickenSale(ChickenSale sale) async {
    final db = await database;
    return await db.insert('chicken_sales', sale.toMap());
  }

  Future<List<ChickenSale>> getAllChickenSales() async {
    final db = await database;
    final maps = await db.query('chicken_sales', orderBy: 'date DESC');
    return maps.map((map) => ChickenSale.fromMap(map)).toList();
  }

  Future<int> updateChickenSale(ChickenSale sale) async {
    final db = await database;
    return await db.update(
      'chicken_sales',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> deleteChickenSale(int id) async {
    final db = await database;
    return await db.delete('chicken_sales', where: 'id = ?', whereArgs: [id]);
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

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<Map<String, double>> getExpensesByCategory(DateTime start, DateTime end) async {
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

  Future<List<Map<String, dynamic>>> getMonthlyEggProduction(int year, int month) async {
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

  Future<Map<String, dynamic>> getProfitLossSummary(DateTime start, DateTime end) async {
    final db = await database;
    
    final eggSales = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity * price_per_unit), 0) as total 
      FROM egg_sales 
      WHERE date >= ? AND date <= ?
    ''', [start.toIso8601String(), end.toIso8601String()]);
    
    final chickenSales = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity * price_per_bird), 0) as total 
      FROM chicken_sales 
      WHERE date >= ? AND date <= ?
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
    
    final revenue = (eggSales.first['total'] as num).toDouble() + 
                    (chickenSales.first['total'] as num).toDouble();
    final expenses = (feedCosts.first['total'] as num).toDouble() + 
                     (otherExpenses.first['total'] as num).toDouble();
    
    return {
      'egg_sales': (eggSales.first['total'] as num).toDouble(),
      'chicken_sales': (chickenSales.first['total'] as num).toDouble(),
      'total_revenue': revenue,
      'feed_costs': (feedCosts.first['total'] as num).toDouble(),
      'other_expenses': (otherExpenses.first['total'] as num).toDouble(),
      'total_expenses': expenses,
      'profit_loss': revenue - expenses,
    };
  }

  // Backup and restore
  Future<Map<String, List<Map<String, dynamic>>>> exportAllData() async {
    final db = await database;
    
    return {
      'flocks': await db.query('flocks'),
      'mortality_log': await db.query('mortality_log'),
      'egg_collection': await db.query('egg_collection'),
      'egg_sales': await db.query('egg_sales'),
      'chicken_sales': await db.query('chicken_sales'),
      'feed_purchases': await db.query('feed_purchases'),
      'feed_usage': await db.query('feed_usage'),
      'expenses': await db.query('expenses'),
    };
  }

  Future<void> importAllData(Map<String, List<Map<String, dynamic>>> data) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('expenses');
      await txn.delete('feed_usage');
      await txn.delete('feed_purchases');
      await txn.delete('chicken_sales');
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
      for (final row in data['chicken_sales'] ?? []) {
        await txn.insert('chicken_sales', row);
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
    });
  }
}
