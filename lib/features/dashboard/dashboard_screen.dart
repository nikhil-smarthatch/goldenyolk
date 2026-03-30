import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import '../../widgets/widgets.dart';
import '../eggs/add_egg_collection_screen.dart';
import '../sales/add_egg_sale_screen.dart';
import '../feed/add_feed_purchase_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final todayEggs = ref.watch(todayEggCollectionProvider);
    final todaySales = ref.watch(todayEggSalesProvider);
    final totalLiveChickensAsync = ref.watch(totalLiveChickensProvider);
    final stockAsync = ref.watch(currentStockProvider);
    final weeklyProduction = ref.watch(weeklyEggProductionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.farmName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(flockProvider);
          ref.invalidate(totalLiveChickensProvider);
          ref.invalidate(todayEggCollectionProvider);
          ref.invalidate(todayEggSalesProvider);
          ref.invalidate(currentStockProvider);
          ref.invalidate(weeklyEggProductionProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildSummaryCards(
                context,
                totalLiveChickensAsync,
                todayEggs,
                todaySales,
                stockAsync,
                settings.currencySymbol,
              ),
              const SizedBox(height: 24),
              _buildWeeklyChart(context, weeklyProduction),
              const SizedBox(height: 24),
              _buildAlertsSection(
                  context, totalLiveChickensAsync, stockAsync, settings.lowStockThreshold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return QuickActionsRow(
      actions: [
        QuickActionButton(
          icon: Icons.egg_alt,
          label: 'Add Eggs',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEggCollectionScreen()),
          ),
          color: AppColors.accentYellow,
        ),
        QuickActionButton(
          icon: Icons.attach_money,
          label: 'Record Sale',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEggSaleScreen()),
          ),
          color: AppColors.success,
        ),
        QuickActionButton(
          icon: Icons.grain,
          label: 'Add Feed',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFeedPurchaseScreen()),
          ),
          color: AppColors.accentOrange,
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AsyncValue<int> totalLiveChickensAsync,
    AsyncValue<Map<String, dynamic>> todayEggs,
    AsyncValue<Map<String, dynamic>> todaySales,
    AsyncValue<double> stockAsync,
    String currencySymbol,
  ) {
    return totalLiveChickensAsync.when(
      data: (totalChickens) {

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 360;
            final isTablet = constraints.maxWidth > 600;
            final crossAxisCount = isTablet ? 4 : 2;
            final childAspectRatio = isSmallScreen ? 0.9 : isTablet ? 1.2 : 1.1;
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                SummaryCard(
                  title: 'Total Chickens',
                  value: NumberFormatter.format(totalChickens),
                  icon: Icons.pets,
                  color: AppColors.primaryGreen,
                ),
                todayEggs.when(
                  data: (eggs) => SummaryCard(
                    title: 'Eggs Today',
                    value: NumberFormatter.format(eggs['good'] as int? ?? 0),
                    icon: Icons.egg,
                    color: AppColors.accentYellow,
                    subtitle: '${eggs['broken'] ?? 0} broken',
                  ),
                  loading: () => const LoadingShimmer(height: 100),
                  error: (_, __) => SummaryCard(
                    title: 'Eggs Today',
                    value: '0',
                    icon: Icons.egg,
                    color: AppColors.accentYellow,
                  ),
                ),
                todaySales.when(
                  data: (sales) => CurrencySummaryCard(
                    title: 'Revenue Today',
                    value: (sales['revenue'] as num?)?.toDouble() ?? 0,
                    icon: Icons.attach_money,
                    color: AppColors.success,
                    subtitle: '${sales['quantity'] ?? 0} eggs sold',
                  ),
                  loading: () => const LoadingShimmer(height: 100),
                  error: (_, __) => CurrencySummaryCard(
                    title: 'Revenue Today',
                    value: 0,
                    icon: Icons.attach_money,
                    color: AppColors.success,
                  ),
                ),
                stockAsync.when(
                  data: (stock) => SummaryCard(
                    title: 'Feed Stock',
                    value: '${CurrencyFormatter.formatSimple(stock)} kg',
                    icon: Icons.grain,
                    color: AppColors.accentOrange,
                  ),
                  loading: () => const LoadingShimmer(height: 100),
                  error: (_, __) => SummaryCard(
                    title: 'Feed Stock',
                    value: '0 kg',
                    icon: Icons.grain,
                    color: AppColors.accentOrange,
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const GridShimmer(crossAxisCount: 2, itemCount: 4),
      error: (_, __) => const Center(child: Text('Error loading data')),
    );
  }

  Widget _buildWeeklyChart(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> weeklyData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weekly Production',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: weeklyData.when(
                data: (data) {
                  if (data.isEmpty) {
                    return EmptyState(
                      icon: Icons.bar_chart,
                      title: 'No production data',
                      subtitle: 'Start collecting eggs to see your weekly trends',
                    );
                  }
                  return _buildBarChart(data);
                },
                loading: () => const LoadingShimmer(height: 200),
                error: (_, __) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error loading chart',
                  subtitle: 'Please try refreshing the data',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    final days = DateHelpers.getLast7Days();

    final Map<String, int> dailyData = {};
    for (final day in days) {
      dailyData[DateHelpers.formatCompact(day)] = 0;
    }

    for (final item in data) {
      final day = item['day'] as String;
      final eggs = item['good_eggs'] as int? ?? 0;
      dailyData[day] = eggs;
    }

    final spots = dailyData.values.toList();
    final maxY = (spots.reduce((a, b) => a > b ? a : b) / 10).ceil() * 10.0;
    final effectiveMaxY = (maxY < 10 ? 10 : maxY).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: effectiveMaxY,
        barGroups: List.generate(7, (index) {
          final value = spots[index].toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: AppColors.primaryGreen,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreenLight,
                    AppColors.primaryGreen,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 10 == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final dayIndex = value.toInt();
                if (dayIndex >= 0 && dayIndex < 7) {
                  final day = days[dayIndex];
                  final dayName = DateHelpers.getWeekdayShort(day);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: effectiveMaxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = days[group.x.toInt()];
              final value = rod.toY.toInt();
              return BarTooltipItem(
                '${DateHelpers.getWeekdayShort(day)}\n$value eggs',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsSection(
    BuildContext context,
    AsyncValue<int> totalLiveChickensAsync,
    AsyncValue<double> stockAsync,
    double lowStockThreshold,
  ) {
    final List<Widget> alerts = [];

    stockAsync.whenData((stock) {
      if (stock < lowStockThreshold) {
        alerts.add(_buildAlertCard(
          context,
          'Low Feed Stock',
          'Only ${stock.toStringAsFixed(1)} kg remaining. Consider purchasing more feed.',
          Icons.warning,
          AppColors.warning,
        ));
      }
    });

    if (alerts.isEmpty) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All systems running smoothly',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications_active,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...alerts,
      ],
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
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
}
