import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';

final customerPriceProvider = FutureProvider.family<double?, String>((ref, buyerName) async {
  if (buyerName.trim().isEmpty) {
    return null;
  }
  
  final db = DatabaseHelper.instance;
  return await db.getCustomerPrice(buyerName);
});

final allCustomerPricesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = DatabaseHelper.instance;
  return await db.getAllCustomerPrices();
});

class CustomerPricingNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  CustomerPricingNotifier() : super(const AsyncValue.data(null));
  
  Future<void> saveCustomerPrice(String buyerName, double pricePerUnit) async {
    try {
      state = const AsyncValue.loading();
      await _db.saveCustomerPrice(buyerName, pricePerUnit);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final customerPricingNotifierProvider = StateNotifierProvider<CustomerPricingNotifier, AsyncValue<void>>((ref) {
  return CustomerPricingNotifier();
});
