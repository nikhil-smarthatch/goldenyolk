import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/egg_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/formatters.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late int _year;
  late int _month;

  static const List<String> _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year < now.year || (_year == now.year && _month < now.month)) {
      setState(() {
        if (_month == 12) {
          _month = 1;
          _year++;
        } else {
          _month++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final reportAsync = ref.watch(
      monthlyEggReportProvider((year: _year, month: _month)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'Monthly Report',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(monthlyEggReportProvider);
        },
        color: const Color(0xFF2E7D32),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Month Navigation Header
            SliverToBoxAdapter(
              child: _buildMonthHeader(),
            ),
            // Report Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: reportAsync.when(
                data: (report) => _buildReportContent(report, settings.currencySymbol),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(
                    child: Text('Error loading report: $error'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFF2E7D32),
          ),
          Column(
            children: [
              Text(
                _monthNames[_month],
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFF1B5E20),
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                '$_year',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> report, String currencySymbol) {
    final eggsLaid = report['eggs_laid'] as int;
    final eggsBroken = report['eggs_broken'] as int;
    final eggsSold = report['eggs_sold'] as int;
    final revenue = report['revenue'] as double;
    final remainingStock = report['remaining_stock'] as int;
    final pendingOrders = report['pending_orders'] as int;
    final orderCount = report['order_count'] as int;
    final dailyBreakdown = report['daily_breakdown'] as List<Map<String, dynamic>>;

    return SliverList(
      delegate: SliverChildListDelegate([
        // Summary Cards
        _buildSummaryCards(
          eggsLaid: eggsLaid,
          eggsSold: eggsSold,
          remainingStock: remainingStock,
          revenue: revenue,
          currencySymbol: currencySymbol,
        ),
        const SizedBox(height: 24),

        // Monthly Details Card
        _buildDetailsCard(
          eggsLaid: eggsLaid,
          eggsBroken: eggsBroken,
          eggsSold: eggsSold,
          pendingOrders: pendingOrders,
          orderCount: orderCount,
        ),
        const SizedBox(height: 24),

        // Daily Breakdown
        if (dailyBreakdown.isNotEmpty) ...[
          _buildSectionTitle('Daily Collection'),
          const SizedBox(height: 12),
          _buildDailyBreakdown(dailyBreakdown),
          const SizedBox(height: 32),
        ],
      ]),
    );
  }

  Widget _buildSummaryCards({
    required int eggsLaid,
    required int eggsSold,
    required int remainingStock,
    required double revenue,
    required String currencySymbol,
  }) {
    return Column(
      children: [
        // Revenue Card (Full Width)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Revenue',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(revenue, symbol: currencySymbol),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                'from $eggsSold eggs delivered',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                emoji: '🥚',
                label: 'Eggs Laid',
                value: eggsLaid.toString(),
                color: const Color(0xFFFFF9C4),
                textColor: const Color(0xFFF57F17),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                emoji: '📦',
                label: 'In Stock',
                value: remainingStock.toString(),
                color: const Color(0xFFE0F7FA),
                textColor: const Color(0xFF00838F),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textColor,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard({
    required int eggsLaid,
    required int eggsBroken,
    required int eggsSold,
    required int pendingOrders,
    required int orderCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B5E20),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Total Eggs Laid', eggsLaid.toString(), '🥚'),
          const Divider(height: 24),
          _buildDetailRow('Broken Eggs', eggsBroken.toString(), '💔'),
          const Divider(height: 24),
          _buildDetailRow('Good Eggs', (eggsLaid - eggsBroken).toString(), '✅'),
          const Divider(height: 24),
          _buildDetailRow('Eggs Delivered', eggsSold.toString(), '🚚'),
          const Divider(height: 24),
          _buildDetailRow('Orders Count', orderCount.toString(), '📋'),
          const Divider(height: 24),
          _buildDetailRow('Pending Orders', pendingOrders.toString(), '⏳'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, String emoji) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2E7D32),
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1B5E20),
        fontFamily: 'Inter',
      ),
    );
  }

  Widget _buildDailyBreakdown(List<Map<String, dynamic>> dailyData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dailyData.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final day = dailyData[index];
          final date = DateTime.parse(day['day'] as String);
          final broken = day['broken'] as int? ?? 0;
          final good = day['good'] as int? ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.day} ${_monthNames[date.month]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (broken > 0)
                      Text(
                        '$broken broken',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'Inter',
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$good good eggs',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
