import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/models.dart';

final eggCollectionProvider = StateNotifierProvider<EggCollectionNotifier, AsyncValue<List<EggCollection>>>((ref) {
  return EggCollectionNotifier(ref);
});

final todayEggCollectionProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getEggCollectionSummary();
});

final weeklyEggProductionProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getWeeklyEggProduction();
});

class EggCollectionNotifier extends StateNotifier<AsyncValue<List<EggCollection>>> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Ref _ref;

  EggCollectionNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadCollections();
  }

  Future<void> loadCollections() async {
    try {
      state = const AsyncValue.loading();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month - 1, now.day);
      final collections = await _db.getEggCollectionsByDateRange(start, now);
      state = AsyncValue.data(collections);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCollection(EggCollection collection) async {
    try {
      await _db.insertEggCollection(collection);
      await loadCollections();
      _ref.invalidate(todayEggCollectionProvider);
      _ref.invalidate(weeklyEggProductionProvider);
      _ref.invalidate(remainingStockProvider);
      _ref.invalidate(inventorySummaryProvider);
      // Invalidate monthly report for current month
      final now = DateTime.now();
      _ref.invalidate(monthlyEggReportProvider((year: now.year, month: now.month)));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateCollection(EggCollection collection) async {
    try {
      await _db.updateEggCollection(collection);
      await loadCollections();
      _ref.invalidate(todayEggCollectionProvider);
      _ref.invalidate(weeklyEggProductionProvider);
      _ref.invalidate(remainingStockProvider);
      _ref.invalidate(inventorySummaryProvider);
      // Invalidate monthly report for current month
      final now = DateTime.now();
      _ref.invalidate(monthlyEggReportProvider((year: now.year, month: now.month)));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteCollection(int id) async {
    try {
      await _db.deleteEggCollection(id);
      await loadCollections();
      _ref.invalidate(todayEggCollectionProvider);
      _ref.invalidate(weeklyEggProductionProvider);
      _ref.invalidate(remainingStockProvider);
      _ref.invalidate(inventorySummaryProvider);
      // Invalidate monthly report for current month
      final now = DateTime.now();
      _ref.invalidate(monthlyEggReportProvider((year: now.year, month: now.month)));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadByDateRange(DateTime start, DateTime end) async {
    try {
      state = const AsyncValue.loading();
      final collections = await _db.getEggCollectionsByDateRange(start, end);
      state = AsyncValue.data(collections);
      _ref.invalidate(todayEggCollectionProvider);
      _ref.invalidate(weeklyEggProductionProvider);
      _ref.invalidate(remainingStockProvider);
      _ref.invalidate(inventorySummaryProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Inventory Management Providers

/// Remaining egg stock (total collected - total delivered)
final remainingStockProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getRemainingEggStock();
});

/// Complete inventory summary
final inventorySummaryProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getInventorySummary();
});

/// Pending order egg count
final pendingOrderEggCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getPendingOrderEggCount();
});

// Monthly Report Provider

/// Monthly egg report with laid, sold, remaining stock, revenue
final monthlyEggReportProvider =
    FutureProvider.family<Map<String, dynamic>, ({int year, int month})>(
  (ref, params) async {
    final db = DatabaseHelper.instance;
    return await db.getMonthlyEggReport(params.year, params.month);
  },
);
