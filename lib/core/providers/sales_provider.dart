import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/models.dart';
import 'egg_provider.dart';

final eggSalesProvider = StateNotifierProvider<EggSalesNotifier, AsyncValue<List<EggSale>>>((ref) {
  return EggSalesNotifier(ref);
});

final todayEggSalesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getEggSalesSummary(DateTime.now());
});

final pendingOrdersProvider = Provider<AsyncValue<List<EggSale>>>((ref) {
  final salesAsync = ref.watch(eggSalesProvider);
  return salesAsync.when(
    data: (sales) => AsyncValue.data(
      sales.where((s) => s.status == 'ordered').toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

final deliveredOrdersProvider = Provider<AsyncValue<List<EggSale>>>((ref) {
  final salesAsync = ref.watch(eggSalesProvider);
  return salesAsync.when(
    data: (sales) => AsyncValue.data(
      sales.where((s) => s.status == 'delivered').toList(),
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

  Future<void> addOrder(EggSale sale) async {
    try {
      await _db.insertEggSale(sale);
      await loadSales();
      _ref.invalidate(todayEggSalesProvider);
      _ref.invalidate(pendingOrderEggCountProvider);
      _ref.invalidate(inventorySummaryProvider);
      // Invalidate monthly report for current month
      final now = DateTime.now();
      _ref.invalidate(monthlyEggReportProvider((year: now.year, month: now.month)));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateOrder(EggSale sale) async {
    try {
      await _db.updateEggSale(sale);
      await loadSales();
      _ref.invalidate(todayEggSalesProvider);
      _ref.invalidate(pendingOrderEggCountProvider);
      _ref.invalidate(remainingStockProvider);
      _ref.invalidate(inventorySummaryProvider);
      // Invalidate monthly report for current month
      final now = DateTime.now();
      _ref.invalidate(monthlyEggReportProvider((year: now.year, month: now.month)));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteOrder(int id) async {
    try {
      await _db.deleteEggSale(id);
      await loadSales();
      _ref.invalidate(todayEggSalesProvider);
      _ref.invalidate(pendingOrderEggCountProvider);
      _ref.invalidate(remainingStockProvider);
      _ref.invalidate(inventorySummaryProvider);
      // Invalidate monthly report for current month
      final now = DateTime.now();
      _ref.invalidate(monthlyEggReportProvider((year: now.year, month: now.month)));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsDelivered(int id) async {
    try {
      final sales = state.value ?? [];
      final matchingSales = sales.where((s) => s.id == id);
      final current = matchingSales.isNotEmpty ? matchingSales.first : null;
      if (current != null) {
        await _db.updateEggSale(current.copyWith(
          status: 'delivered',
          deliveryDate: DateTime.now(),
        ));
        await loadSales();
        _ref.invalidate(todayEggSalesProvider);
        _ref.invalidate(remainingStockProvider);
        _ref.invalidate(inventorySummaryProvider);
        _ref.invalidate(pendingOrderEggCountProvider);
        // Invalidate monthly report for current month
        final now = DateTime.now();
        _ref.invalidate(monthlyEggReportProvider((year: now.year, month: now.month)));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> cancelOrder(int id) async {
    try {
      final sales = state.value ?? [];
      final matchingSales = sales.where((s) => s.id == id);
      final current = matchingSales.isNotEmpty ? matchingSales.first : null;
      if (current != null) {
        await _db.updateEggSale(current.copyWith(status: 'cancelled'));
        await loadSales();
        _ref.invalidate(todayEggSalesProvider);
        _ref.invalidate(pendingOrderEggCountProvider);
        _ref.invalidate(inventorySummaryProvider);
        // Invalidate monthly report for current month
        final now = DateTime.now();
        _ref.invalidate(monthlyEggReportProvider((year: now.year, month: now.month)));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
