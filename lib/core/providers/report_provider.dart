import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';

final monthlyEggReportProvider = FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  final db = DatabaseHelper.instance;
  return await db.getMonthlyEggCollectionReport(date.year, date.month);
});

final monthlySalesReportProvider = FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  final db = DatabaseHelper.instance;
  return await db.getMonthlySalesReport(date.year, date.month);
});

class ReportDateNotifier extends StateNotifier<DateTime> {
  ReportDateNotifier() : super(DateTime.now());
  
  void setMonth(int year, int month) {
    state = DateTime(year, month);
  }
  
  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }
  
  void nextMonth() {
    final now = DateTime.now();
    final next = DateTime(state.year, state.month + 1);
    if (next.isBefore(now) || next.month == now.month) {
      state = next;
    }
  }
}

final reportDateProvider = StateNotifierProvider<ReportDateNotifier, DateTime>((ref) {
  return ReportDateNotifier();
});
