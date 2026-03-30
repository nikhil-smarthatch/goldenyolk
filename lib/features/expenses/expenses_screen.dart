import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/expense_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import '../../widgets/widgets.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () => _showCategoryBreakdown(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(expensesProvider),
              child: expensesAsync.when(
                data: (expenses) {
                  // Filter by selected month
                  final filtered = expenses.where((e) {
                    return e.date.year == _selectedMonth.year &&
                        e.date.month == _selectedMonth.month;
                  }).toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Expenses',
                      subtitle: 'Track your farm expenses to manage costs',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddExpenseScreen()),
                      ),
                      actionLabel: 'Add Expense',
                    );
                  }

                  final totalExpenses = filtered.fold<double>(
                    0,
                    (sum, e) => sum + e.amount,
                  );

                  return Column(
                    children: [
                      _buildTotalCard(
                          context, totalExpenses, settings.currencySymbol),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final expense = filtered[index];
                            return _buildExpenseCard(
                                context, expense, settings.currencySymbol);
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CardShimmer(count: 3),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Expanded(
            child: Text(
              DateHelpers.formatMonthYear(_selectedMonth),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year
                ? null
                : () {
                    setState(() {
                      _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      );
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(
      BuildContext context, double total, String currencySymbol) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.trending_down, color: AppColors.error),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    CurrencyFormatter.format(total, symbol: currencySymbol),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(
      BuildContext context, dynamic expense, String currencySymbol) {
    final icon = _getCategoryIcon(expense.category);
    final color = _getCategoryColor(expense.category);

    return SwipeableListItem(
      onEdit: () {},
      onDelete: () async {
        await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
      },
      confirmDeleteMessage: 'Delete this expense record?',
      child: Card(
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(expense.description),
          subtitle: Text(
            '${expense.category} • ${DateHelpers.formatDate(expense.date)}',
          ),
          trailing: Text(
            CurrencyFormatter.format(expense.amount, symbol: currencySymbol),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medicine':
        return Icons.medical_services;
      case 'vaccine':
        return Icons.vaccines;
      case 'equipment':
        return Icons.handyman;
      case 'labor':
        return Icons.people;
      case 'electricity':
        return Icons.electric_bolt;
      case 'water':
        return Icons.water_drop;
      case 'transport':
        return Icons.local_shipping;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'medicine':
        return Colors.red;
      case 'vaccine':
        return Colors.orange;
      case 'equipment':
        return Colors.blue;
      case 'labor':
        return Colors.green;
      case 'electricity':
        return Colors.yellow.shade700;
      case 'water':
        return Colors.cyan;
      case 'transport':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showCategoryBreakdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CategoryBreakdownView(),
    );
  }
}

class _CategoryBreakdownView extends ConsumerWidget {
  const _CategoryBreakdownView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final settings = ref.watch(settingsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expense Breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: expensesAsync.when(
                  data: (expenses) {
                    // Group by category
                    final Map<String, double> byCategory = {};
                    for (final expense in expenses) {
                      byCategory[expense.category] =
                          (byCategory[expense.category] ?? 0) + expense.amount;
                    }

                    if (byCategory.isEmpty) {
                      return const Center(child: Text('No data available'));
                    }

                    return Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: _buildPieChart(byCategory),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: byCategory.entries.map((entry) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getCategoryColor(entry.key)
                                      .withValues(alpha: 0.2),
                                  child: Icon(
                                    _getCategoryIcon(entry.key),
                                    color: _getCategoryColor(entry.key),
                                  ),
                                ),
                                title: Text(entry.key),
                                trailing: Text(
                                  CurrencyFormatter.format(entry.value,
                                      symbol: settings.currencySymbol),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const LoadingShimmer(height: 200),
                  error: (_, __) => const Center(child: Text('Error')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart(Map<String, double> data) {
    final total = data.values.reduce((a, b) => a + b);
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.yellow,
    ];

    return PieChart(
      PieChartData(
        sections: data.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value.value;
          final percentage = (value / total * 100).toStringAsFixed(1);

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: value,
            title: '$percentage%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medicine':
        return Icons.medical_services;
      case 'vaccine':
        return Icons.vaccines;
      case 'equipment':
        return Icons.handyman;
      case 'labor':
        return Icons.people;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'medicine':
        return Colors.red;
      case 'vaccine':
        return Colors.orange;
      case 'equipment':
        return Colors.blue;
      case 'labor':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
