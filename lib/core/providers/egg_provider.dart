import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/models.dart';

final eggCollectionProvider = StateNotifierProvider<EggCollectionNotifier, AsyncValue<List<EggCollection>>>((ref) {
  return EggCollectionNotifier(ref);
});

final todayEggCollectionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getEggCollectionSummary(DateTime.now());
});

final weeklyEggProductionProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
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
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
