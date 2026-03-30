import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/models.dart';

final feedPurchasesProvider = StateNotifierProvider<FeedPurchasesNotifier, AsyncValue<List<FeedPurchase>>>((ref) {
  return FeedPurchasesNotifier();
});

final feedUsageProvider = StateNotifierProvider.family<FeedUsageNotifier, AsyncValue<List<FeedUsage>>, int>((ref, flockId) {
  return FeedUsageNotifier(flockId);
});

final currentStockProvider = FutureProvider<double>((ref) async {
  final db = DatabaseHelper.instance;
  final purchased = await db.getTotalFeedPurchased();
  final used = await db.getTotalFeedUsed();
  return purchased - used;
});

class FeedPurchasesNotifier extends StateNotifier<AsyncValue<List<FeedPurchase>>> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  FeedPurchasesNotifier() : super(const AsyncValue.loading()) {
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    try {
      state = const AsyncValue.loading();
      final purchases = await _db.getAllFeedPurchases();
      state = AsyncValue.data(purchases);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPurchase(FeedPurchase purchase) async {
    try {
      await _db.insertFeedPurchase(purchase);
      await loadPurchases();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePurchase(FeedPurchase purchase) async {
    try {
      await _db.updateFeedPurchase(purchase);
      await loadPurchases();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePurchase(int id) async {
    try {
      await _db.deleteFeedPurchase(id);
      await loadPurchases();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class FeedUsageNotifier extends StateNotifier<AsyncValue<List<FeedUsage>>> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final int flockId;

  FeedUsageNotifier(this.flockId) : super(const AsyncValue.loading()) {
    loadUsage();
  }

  Future<void> loadUsage() async {
    try {
      state = const AsyncValue.loading();
      final usage = await _db.getFeedUsageByFlock(flockId);
      state = AsyncValue.data(usage);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addUsage(FeedUsage usage) async {
    try {
      await _db.insertFeedUsage(usage);
      await loadUsage();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateUsage(FeedUsage usage) async {
    try {
      await _db.updateFeedUsage(usage);
      await loadUsage();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteUsage(int id) async {
    try {
      await _db.deleteFeedUsage(id);
      await loadUsage();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
