import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/models.dart';

class DatabaseSeeder {
  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeeded = prefs.getBool('database_seeded') ?? false;

    if (hasSeeded) return;

    await _seedData();
    await prefs.setBool('database_seeded', true);
  }

  static Future<void> _seedData() async {
    final db = DatabaseHelper.instance;
    final now = DateTime.now();

    // Seed Flocks
    final flock1 = Flock(
      name: 'Batch A - Layers',
      breed: 'Rhode Island Red',
      initialCount: 100,
      dateAcquired: now.subtract(const Duration(days: 90)),
      purpose: 'layer',
      notes: 'Primary laying flock, excellent egg production',
    );
    final flock1Id = await db.insertFlock(flock1);

    final flock2 = Flock(
      name: 'Batch B - Layers',
      breed: 'Leghorn',
      initialCount: 75,
      dateAcquired: now.subtract(const Duration(days: 60)),
      purpose: 'layer',
      notes: 'White egg layers',
    );
    final flock2Id = await db.insertFlock(flock2);

    final flock3 = Flock(
      name: 'Broiler Batch 1',
      breed: 'Cornish Cross',
      initialCount: 50,
      dateAcquired: now.subtract(const Duration(days: 30)),
      purpose: 'broiler',
      notes: 'Meat birds for market',
    );
    await db.insertFlock(flock3);

    // Seed Mortality (minimal for demo)
    await db.insertMortality(MortalityLog(
      flockId: flock1Id,
      date: now.subtract(const Duration(days: 30)),
      count: 2,
      reason: 'Unknown',
      notes: 'Found in morning',
    ));

    await db.insertMortality(MortalityLog(
      flockId: flock2Id,
      date: now.subtract(const Duration(days: 15)),
      count: 1,
      reason: 'Predator',
      notes: 'Suspected fox attack',
    ));

    // Seed Egg Collections (last 7 days)
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      // Flock 1 collections (more productive)
      await db.insertEggCollection(EggCollection(
        flockId: flock1Id,
        date: date,
        collected: 45 + (i % 5), // Varies between 45-50
        broken: i == 3 ? 3 : 1, // One day with more broken eggs
        notes: i == 3 ? 'Rough handling during collection' : null,
      ));

      // Flock 2 collections
      await db.insertEggCollection(EggCollection(
        flockId: flock2Id,
        date: date,
        collected: 35 + (i % 4),
        broken: 0,
      ));
    }

    // Seed Egg Sales
    for (int i = 6; i >= 0; i -= 2) {
      final date = now.subtract(Duration(days: i));
      
      await db.insertEggSale(EggSale(
        date: date,
        quantity: 60,
        pricePerUnit: 8.0,
        buyer: i % 4 == 0 ? 'Local Market' : 'Mr. Sharma',
        paymentStatus: i % 6 == 0 ? 'credit' : 'paid',
        notes: i % 6 == 0 ? 'Payment due next week' : null,
      ));
    }

    // Seed Chicken Sales
    await db.insertChickenSale(ChickenSale(
      flockId: flock3.id,
      date: now.subtract(const Duration(days: 5)),
      quantity: 10,
      pricePerBird: 350.0,
      buyer: 'Restaurant ABC',
      notes: 'Weekly delivery',
    ));

    // Seed Feed Purchases
    await db.insertFeedPurchase(FeedPurchase(
      date: now.subtract(const Duration(days: 45)),
      feedType: 'layer',
      quantityKg: 500,
      pricePerUnit: 35.0,
      supplier: 'Agro Feed Store',
      notes: 'Monthly supply',
    ));

    await db.insertFeedPurchase(FeedPurchase(
      date: now.subtract(const Duration(days: 15)),
      feedType: 'starter',
      quantityKg: 200,
      pricePerUnit: 40.0,
      supplier: 'Agro Feed Store',
    ));

    await db.insertFeedPurchase(FeedPurchase(
      date: now.subtract(const Duration(days: 5)),
      feedType: 'grower',
      quantityKg: 150,
      pricePerUnit: 38.0,
      supplier: 'Agro Feed Store',
    ));

    // Seed Feed Usage (last 7 days)
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      
      await db.insertFeedUsage(FeedUsage(
        flockId: flock1Id,
        date: date,
        quantityKg: 12.5,
      ));

      await db.insertFeedUsage(FeedUsage(
        flockId: flock2Id,
        date: date,
        quantityKg: 10.0,
      ));
    }

    // Seed Expenses
    final expenses = [
      Expense(
        date: now.subtract(const Duration(days: 40)),
        category: 'Medicine',
        description: 'Vaccination - Newcastle Disease',
        amount: 2500.0,
        notes: 'Batch vaccination for all flocks',
      ),
      Expense(
        date: now.subtract(const Duration(days: 20)),
        category: 'Equipment',
        description: 'New feeders (10 units)',
        amount: 3500.0,
      ),
      Expense(
        date: now.subtract(const Duration(days: 10)),
        category: 'Labor',
        description: 'Monthly salary - Helper',
        amount: 8000.0,
      ),
      Expense(
        date: now.subtract(const Duration(days: 5)),
        category: 'Electricity',
        description: 'Monthly electricity bill',
        amount: 1200.0,
      ),
      Expense(
        date: now.subtract(const Duration(days: 2)),
        category: 'Vaccine',
        description: 'IBD vaccine',
        amount: 800.0,
      ),
    ];

    for (final expense in expenses) {
      await db.insertExpense(expense);
    }
  }
}
