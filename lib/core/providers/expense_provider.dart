import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/models.dart';

final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  return ExpensesNotifier();
});

final expensesByDateRangeProvider = StateNotifierProvider.family<ExpensesByRangeNotifier, AsyncValue<List<Expense>>, DateTimeRange>((ref, range) {
  return ExpensesByRangeNotifier(range);
});

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});
}

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  ExpensesNotifier() : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      state = const AsyncValue.loading();
      final expenses = await _db.getAllExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _db.insertExpense(expense);
      await loadExpenses();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _db.updateExpense(expense);
      await loadExpenses();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _db.deleteExpense(id);
      await loadExpenses();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class ExpensesByRangeNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final DateTimeRange range;

  ExpensesByRangeNotifier(this.range) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      state = const AsyncValue.loading();
      final expenses = await _db.getExpensesByDateRange(range.start, range.end);
      state = AsyncValue.data(expenses);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
