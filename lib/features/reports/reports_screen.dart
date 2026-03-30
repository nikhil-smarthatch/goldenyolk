import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/database/db_helper.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import '../../widgets/widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeSelector(context),
            const SizedBox(height: 24),
            _buildProfitLossCard(settings.currencySymbol),
            const SizedBox(height: 24),
            _buildProductionReport(),
            const SizedBox(height: 24),
            _buildMonthlyEggCollectionReport(),
            const SizedBox(height: 24),
            _buildMonthlySalesReport(),
            const SizedBox(height: 24),
            _buildQuickLinks(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateChip(
                    context,
                    'Start',
                    DateHelpers.formatShortDate(_startDate),
                    () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateChip(
                    context,
                    'End',
                    DateHelpers.formatShortDate(_endDate),
                    () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(
      BuildContext context, String label, String date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitLossCard(String currencySymbol) {
    return FutureBuilder<Map<String, dynamic>>(
      future:
          DatabaseHelper.instance.getProfitLossSummary(_startDate, _endDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingShimmer(height: 200);
        }

        final data = snapshot.data!;
        final profit = data['profit_loss'] as double;
        final isProfit = profit >= 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isProfit
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isProfit ? Icons.trending_up : Icons.trending_down,
                        color: isProfit ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profit & Loss',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        CurrencyFormatter.format(profit.abs(),
                            symbol: currencySymbol),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isProfit
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                      ),
                      Text(
                        isProfit ? 'PROFIT' : 'LOSS',
                        style: TextStyle(
                          color: isProfit ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                _buildFinancialRow(
                  context,
                  'Total Revenue',
                  data['total_revenue'] as double,
                  currencySymbol,
                  isPositive: true,
                ),
                const SizedBox(height: 8),
                _buildFinancialRow(
                  context,
                  '  Egg Sales',
                  data['egg_sales'] as double,
                  currencySymbol,
                  isSubItem: true,
                ),
                const SizedBox(height: 8),
                _buildFinancialRow(
                  context,
                  '  Chicken Sales',
                  data['chicken_sales'] as double,
                  currencySymbol,
                  isSubItem: true,
                ),
                const Divider(height: 16),
                _buildFinancialRow(
                  context,
                  'Total Expenses',
                  data['total_expenses'] as double,
                  currencySymbol,
                  isPositive: false,
                ),
                const SizedBox(height: 8),
                _buildFinancialRow(
                  context,
                  '  Feed Costs',
                  data['feed_costs'] as double,
                  currencySymbol,
                  isSubItem: true,
                ),
                const SizedBox(height: 8),
                _buildFinancialRow(
                  context,
                  '  Other Expenses',
                  data['other_expenses'] as double,
                  currencySymbol,
                  isSubItem: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialRow(
    BuildContext context,
    String label,
    double amount,
    String currencySymbol, {
    bool isSubItem = false,
    bool isPositive = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSubItem ? FontWeight.normal : FontWeight.w500,
                color: isSubItem
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
              ),
        ),
        const Spacer(),
        Text(
          CurrencyFormatter.format(amount, symbol: currencySymbol),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isSubItem ? FontWeight.normal : FontWeight.bold,
                color: isPositive && !isSubItem ? AppColors.success : null,
              ),
        ),
      ],
    );
  }

  Widget _buildProductionReport() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getMonthlyEggProduction(
        _endDate.year,
        _endDate.month,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingShimmer(height: 250);
        }

        final data = snapshot.data!;
        final totalCollected = data.fold<int>(
          0,
          (sum, item) => sum + (item['collected'] as int? ?? 0),
        );
        final totalGood = data.fold<int>(
          0,
          (sum, item) => sum + (item['good_eggs'] as int? ?? 0),
        );
        final avgDaily = data.isEmpty ? 0 : totalGood / data.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Egg Production - ${DateHelpers.formatMonthYear(_endDate)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Total Eggs',
                        NumberFormatter.format(totalCollected),
                        AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Good Eggs',
                        NumberFormatter.format(totalGood),
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Daily Avg',
                        CurrencyFormatter.formatSimple(avgDaily.toDouble()),
                        AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
                if (data.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 150,
                    child: _buildMonthlyBarChart(data),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBox(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(List<Map<String, dynamic>> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (data
                        .map((e) => e['good_eggs'] as int? ?? 0)
                        .reduce((a, b) => a > b ? a : b) /
                    10)
                .ceil() *
            10.0,
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (item['good_eggs'] as int? ?? 0).toDouble(),
                color: AppColors.accentYellow,
                width: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 20 == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildMonthlyEggCollectionReport() {
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseHelper.instance.getMonthlyEggCollectionReport(
        _endDate.year,
        _endDate.month,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingShimmer(height: 200);
        }

        final data = snapshot.data!;
        final totalCollected = data['total_collected'] as int;
        final totalGood = data['total_good_eggs'] as int;
        final totalBroken = data['total_broken'] as int;
        final activeFlocks = data['active_flocks'] as int;
        final avgDaily = data['avg_daily_collection'] as double;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.egg, color: AppColors.accentYellow),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly Egg Collection Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Collected',
                        NumberFormatter.format(totalCollected),
                        AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Good Eggs',
                        NumberFormatter.format(totalGood),
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Broken',
                        NumberFormatter.format(totalBroken),
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Active Flocks',
                        NumberFormatter.format(activeFlocks),
                        AppColors.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Daily Avg',
                        NumberFormatter.format(avgDaily.round()),
                        AppColors.accentPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySalesReport() {
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseHelper.instance.getMonthlySalesReport(
        _endDate.year,
        _endDate.month,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingShimmer(height: 200);
        }

        final data = snapshot.data!;
        final totalQuantity = data['total_quantity'] as int;
        final paidRevenue = data['paid_revenue'] as double;
        final creditAmount = data['credit_amount'] as double;
        final totalSales = data['total_sales'] as int;
        final paidSales = data['paid_sales'] as int;
        final creditSales = data['credit_sales'] as int;
        final avgPrice = data['avg_price_per_egg'] as double;
        final buyerBreakdown = data['buyer_breakdown'] as List<dynamic>;

        final settings = ref.watch(settingsProvider);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_money, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly Sales Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Eggs Sold',
                        NumberFormatter.format(totalQuantity),
                        AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Paid Revenue',
                        CurrencyFormatter.format(paidRevenue, symbol: settings.currencySymbol),
                        AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Credit Amount',
                        CurrencyFormatter.format(creditAmount, symbol: settings.currencySymbol),
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Avg Price',
                        CurrencyFormatter.format(avgPrice, symbol: settings.currencySymbol),
                        AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Total Sales',
                        NumberFormatter.format(totalSales),
                        Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Paid Sales',
                        NumberFormatter.format(paidSales),
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Credit Sales',
                        NumberFormatter.format(creditSales),
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
                if (buyerBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Top Buyers',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...buyerBreakdown.take(3).map((buyer) {
                    final name = buyer['buyer'] as String? ?? 'Unknown';
                    final qty = buyer['quantity'] as int? ?? 0;
                    final revenue = buyer['revenue'] as double? ?? 0.0;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      ),
                      title: Text(name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text('$qty eggs', style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        CurrencyFormatter.format(revenue, symbol: settings.currencySymbol),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Reports',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildReportTile(
          context,
          'FCR (Feed Conversion Ratio)',
          Icons.analytics,
          AppColors.accentBlue,
          () {},
        ),
        _buildReportTile(
          context,
          'Mortality Analysis',
          Icons.trending_down,
          AppColors.error,
          () {},
        ),
        _buildReportTile(
          context,
          'Sales Summary',
          Icons.attach_money,
          AppColors.success,
          () {},
        ),
        _buildReportTile(
          context,
          'Export Data',
          Icons.download,
          AppColors.accentPurple,
          () => _showExportDialog(context),
        ),
      ],
    );
  }

  Widget _buildReportTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showExportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement PDF export
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement CSV export
              },
            ),
          ],
        ),
      ),
    );
  }
}
