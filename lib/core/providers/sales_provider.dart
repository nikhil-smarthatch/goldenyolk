import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/models.dart';

final eggSalesProvider = StateNotifierProvider<EggSalesNotifier, AsyncValue<List<EggSale>>>((ref) {
  return EggSalesNotifier(ref);
});

final chickenSalesProvider = StateNotifierProvider<ChickenSalesNotifier, AsyncValue<List<ChickenSale>>>((ref) {
  return ChickenSalesNotifier();
});

final todayEggSalesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getEggSalesSummary(DateTime.now());
});

final pendingPaymentsProvider = Provider<AsyncValue<List<EggSale>>>((ref) {
  final salesAsync = ref.watch(eggSalesProvider);
  return salesAsync.when(
    data: (sales) => AsyncValue.data(
      sales.where((s) => s.paymentStatus == 'credit').toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

class EggSalesNotifier extends StateNotifier<AsyncValue<List<EggSale>>> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Ref _ref;

  EggSalesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadSales();
  }

  Future<void> loadSales() async {
    try {
      state = const AsyncValue.loading();
      final sales = await _db.getAllEggSales();
      state = AsyncValue.data(sales);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSale(EggSale sale) async {
    try {
      await _db.insertEggSale(sale);
      await loadSales();
      _ref.invalidate(todayEggSalesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSale(EggSale sale) async {
    try {
      await _db.updateEggSale(sale);
      await loadSales();
      _ref.invalidate(todayEggSalesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSale(int id) async {
    try {
      await _db.deleteEggSale(id);
      await loadSales();
      _ref.invalidate(todayEggSalesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsPaid(int id) async {
    try {
      final sales = state.value ?? [];
      final matchingSales = sales.where((s) => s.id == id);
      final current = matchingSales.isNotEmpty ? matchingSales.first : null;
      if (current != null) {
        await _db.updateEggSale(current.copyWith(paymentStatus: 'paid'));
        await loadSales();
        _ref.invalidate(todayEggSalesProvider);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class ChickenSalesNotifier extends StateNotifier<AsyncValue<List<ChickenSale>>> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  ChickenSalesNotifier() : super(const AsyncValue.loading()) {
    loadSales();
  }

  Future<void> loadSales() async {
    try {
      state = const AsyncValue.loading();
      final sales = await _db.getAllChickenSales();
      state = AsyncValue.data(sales);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSale(ChickenSale sale) async {
    try {
      await _db.insertChickenSale(sale);
      await loadSales();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSale(ChickenSale sale) async {
    try {
      await _db.updateChickenSale(sale);
      await loadSales();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSale(int id) async {
    try {
      await _db.deleteChickenSale(id);
      await loadSales();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
