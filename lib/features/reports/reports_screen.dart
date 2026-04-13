import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/db_helper.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../core/services/error_logger.dart';
import '../../widgets/widgets.dart';
import 'monthly_report_screen.dart';

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
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading profit/loss data',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const LoadingShimmer(height: 200);
        }

        final data = snapshot.data!;
        final profit = (data['profit_loss'] as num?)?.toDouble() ?? 0.0;
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
                  (data['total_revenue'] as num?)?.toDouble() ?? 0.0,
                  currencySymbol,
                  isPositive: true,
                ),
                const SizedBox(height: 8),
                _buildFinancialRow(
                  context,
                  '  Egg Sales',
                  (data['egg_sales'] as num?)?.toDouble() ?? 0.0,
                  currencySymbol,
                  isSubItem: true,
                ),
                const Divider(height: 16),
                _buildFinancialRow(
                  context,
                  'Total Expenses',
                  (data['total_expenses'] as num?)?.toDouble() ?? 0.0,
                  currencySymbol,
                  isPositive: false,
                ),
                const SizedBox(height: 8),
                _buildFinancialRow(
                  context,
                  '  Feed Costs',
                  (data['feed_costs'] as num?)?.toDouble() ?? 0.0,
                  currencySymbol,
                  isSubItem: true,
                ),
                const SizedBox(height: 8),
                _buildFinancialRow(
                  context,
                  '  Other Expenses',
                  (data['other_expenses'] as num?)?.toDouble() ?? 0.0,
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

  Widget _buildMonthlyEggCollectionReport() {
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseHelper.instance.getMonthlyEggCollectionReport(
        _endDate.year,
        _endDate.month,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading collection data',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
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

  Widget _buildMonthlySalesReport() {
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseHelper.instance.getMonthlySalesReport(
        _endDate.year,
        _endDate.month,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading sales data',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const LoadingShimmer(height: 200);
        }

        final data = snapshot.data!;
        final totalQuantity = (data['total_quantity'] as num?)?.toInt() ?? 0;
        final paidRevenue = (data['paid_revenue'] as num?)?.toDouble() ?? 0.0;
        final creditAmount = (data['credit_amount'] as num?)?.toDouble() ?? 0.0;
        final totalSales = (data['total_sales'] as num?)?.toInt() ?? 0;
        final paidSales = (data['paid_sales'] as num?)?.toInt() ?? 0;
        final creditSales = (data['credit_sales'] as num?)?.toInt() ?? 0;
        final avgPrice = (data['avg_price_per_egg'] as num?)?.toDouble() ?? 0.0;
        final buyerBreakdown = data['buyer_breakdown'] as List<dynamic>? ?? [];

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
                        CurrencyFormatter.format(paidRevenue,
                            symbol: settings.currencySymbol),
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
                        CurrencyFormatter.format(creditAmount,
                            symbol: settings.currencySymbol),
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatBox(
                        context,
                        'Avg Price',
                        CurrencyFormatter.format(avgPrice,
                            symbol: settings.currencySymbol),
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
                    final revenue =
                        (buyer['revenue'] as num?)?.toDouble() ?? 0.0;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        child:
                            Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      ),
                      title: Text(name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text('$qty eggs',
                          style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        CurrencyFormatter.format(revenue,
                            symbol: settings.currencySymbol),
                        style: const TextStyle(
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
          'Monthly Egg Report',
          Icons.calendar_month,
          AppColors.primaryGreen,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
          ),
        ),
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
          () => _showMortalityAnalysis(context),
        ),
        _buildReportTile(
          context,
          'Sales Summary',
          Icons.attach_money,
          AppColors.success,
          () => _showSalesSummary(context),
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

  void _showMortalityAnalysis(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return FutureBuilder<Map<String, dynamic>>(
            future: DatabaseHelper.instance.getMortalityAnalysis(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;
              final flockMortality = data['flock_mortality'] as List<dynamic>;
              final totalDeaths = data['total_deaths'] as int;
              // final totalInitial = data['total_initial'] as int; // Available if needed
              final mortalityRate = data['mortality_rate'] as double;

              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mortality Analysis',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Deaths',
                            '$totalDeaths',
                            AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Mortality Rate',
                            '${mortalityRate.toStringAsFixed(1)}%',
                            AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'By Flock',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: flockMortality.isEmpty
                          ? const EmptyState(
                              icon: Icons.check_circle,
                              title: 'No Mortality Records',
                              subtitle: 'All flocks are healthy!',
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: flockMortality.length,
                              itemBuilder: (context, index) {
                                final flock = flockMortality[index];
                                final deaths =
                                    (flock['total_deaths'] as num?)?.toInt() ??
                                        0;
                                final initial =
                                    (flock['initial_count'] as num?)?.toInt() ??
                                        0;
                                final rate = initial > 0
                                    ? (deaths / initial) * 100
                                    : 0.0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: deaths > 0
                                          ? AppColors.error
                                          : AppColors.success,
                                      child: Icon(
                                        deaths > 0
                                            ? Icons.trending_down
                                            : Icons.check,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                        flock['breed'] as String? ?? 'Unknown'),
                                    subtitle: Text('Initial: $initial birds'),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$deaths deaths',
                                          style: TextStyle(
                                            color: deaths > 0
                                                ? AppColors.error
                                                : null,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${rate.toStringAsFixed(1)}%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSalesSummary(BuildContext context) {
    final settings = ref.read(settingsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return FutureBuilder<Map<String, dynamic>>(
            future: DatabaseHelper.instance.getSalesSummary(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading sales data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          '${snapshot.error}',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;
              final totalEggs = (data['total_eggs_sold'] as num?)?.toInt() ?? 0;
              final totalRevenue =
                  (data['total_revenue'] as num?)?.toDouble() ?? 0.0;
              final deliveredOrders =
                  (data['delivered_orders'] as num?)?.toInt() ?? 0;
              final pendingOrders =
                  (data['pending_orders'] as num?)?.toInt() ?? 0;
              final topBuyers = data['top_buyers'] as List<dynamic>;

              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sales Summary',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Eggs',
                            '$totalEggs',
                            AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Revenue',
                            CurrencyFormatter.format(totalRevenue,
                                symbol: settings.currencySymbol),
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Delivered',
                            '$deliveredOrders',
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Pending',
                            '$pendingOrders',
                            AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (topBuyers.isNotEmpty) ...[
                      Text(
                        'Top Buyers',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: topBuyers.length,
                          itemBuilder: (context, index) {
                            final buyer = topBuyers[index];
                            final name = buyer['buyer'] as String? ?? 'Unknown';
                            final qty =
                                (buyer['total_quantity'] as num?)?.toInt() ?? 0;
                            final revenue =
                                (buyer['total_revenue'] as num?)?.toDouble() ??
                                    0.0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?'),
                                ),
                                title: Text(name),
                                subtitle: Text('$qty eggs'),
                                trailing: Text(
                                  CurrencyFormatter.format(revenue,
                                      symbol: settings.currencySymbol),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.people_outline,
                          title: 'No Buyers Yet',
                          subtitle:
                              'Start creating orders to see buyer analytics',
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                _showExportNotImplemented(context, 'PDF export coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () => _handleCSVExport(context),
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup All Data (JSON)'),
              onTap: () => _handleJSONExport(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportNotImplemented(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCSVExport(BuildContext context) async {
    Navigator.pop(context);
    try {
      final filePath = await DataExportService.exportToCSV();
      if (context.mounted) {
        await DataExportService.shareExportFile(filePath);
      }
    } catch (e) {
      await logError('CSV export failed', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _handleJSONExport(BuildContext context) async {
    Navigator.pop(context);
    try {
      final filePath = await DataExportService.exportAllData();
      if (context.mounted) {
        await DataExportService.shareExportFile(filePath);
      }
    } catch (e) {
      await logError('JSON backup failed', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }
}
