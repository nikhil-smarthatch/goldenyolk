import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import '../../widgets/widgets.dart';
import '../eggs/eggs_screen.dart';
import '../sales/sales_screen.dart';
import '../feed/feed_screen.dart';
import '../flock/flock_screen.dart';
import '../expenses/expenses_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(
        parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _headerController, curve: Curves.easeOutCubic));
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final todayEggs = ref.watch(todayEggCollectionProvider);
    final todaySales = ref.watch(todayEggSalesProvider);
    final totalLiveChickensAsync = ref.watch(totalLiveChickensProvider);
    final stockAsync = ref.watch(currentStockProvider);
    final weeklyProduction = ref.watch(weeklyEggProductionProvider);
    final remainingStock = ref.watch(remainingStockProvider);
    final now = DateTime.now();
    final greeting = _getGreeting();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F7F0),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(flockProvider);
            ref.invalidate(totalLiveChickensProvider);
            ref.invalidate(todayEggCollectionProvider);
            ref.invalidate(todayEggSalesProvider);
            ref.invalidate(currentStockProvider);
            ref.invalidate(weeklyEggProductionProvider);
            ref.invalidate(remainingStockProvider);
          },
          color: AppColors.primaryGreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header sliver ──
              SliverToBoxAdapter(
                child: _buildHeader(context, settings, greeting, now),
              ),
              // ── Stats row ──
              SliverToBoxAdapter(
                child: _buildStatsRow(
                    context, totalLiveChickensAsync, todayEggs,
                    todaySales, stockAsync, remainingStock, settings.currencySymbol),
              ),
              // ── Manage Farm grid ──
              SliverToBoxAdapter(
                child: _buildManageSection(context),
              ),
              // ── Weekly chart ──
              SliverToBoxAdapter(
                child: _buildWeeklyChart(context, weeklyProduction),
              ),
              // ── Quick actions ──
              SliverToBoxAdapter(
                child: _buildQuickActions(context),
              ),
              // ── Pending Orders ──
              SliverToBoxAdapter(
                child: _buildPendingOrdersSection(context, ref),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AppSettings settings,
      String greeting, DateTime now) {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF66BB6A)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              settings.farmName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Inter',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Settings button
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        ),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('⚙️', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Date chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          DateHelpers.formatDate(now),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Stats horizontal scroll ───────────────────────────────────────────────
  Widget _buildStatsRow(
    BuildContext context,
    AsyncValue<int> totalChickensAsync,
    AsyncValue<Map<String, dynamic>> todayEggs,
    AsyncValue<Map<String, dynamic>> todaySales,
    AsyncValue<double> stockAsync,
    AsyncValue<int> remainingStock,
    String currencySymbol,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, "Today's Overview", null),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              children: [
                totalChickensAsync.when(
                  data: (n) => _statCard(context, '🐓', 'Live Chickens',
                      NumberFormatter.format(n), const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                  loading: () => _statCardShimmer(),
                  error: (_, __) => _statCard(context, '🐓', 'Live Chickens',
                      '—', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                todayEggs.when(
                  data: (eggs) => remainingStock.when(
                    data: (stock) => _statCard(
                        context, '🥚', 'Eggs Today',
                        NumberFormatter.format(eggs['good'] as int? ?? 0),
                        const Color(0xFFFFFDE7), const Color(0xFFF57F17),
                        subtitle: '$stock remaining'),
                    loading: () => _statCard(
                        context, '🥚', 'Eggs Today',
                        NumberFormatter.format(eggs['good'] as int? ?? 0),
                        const Color(0xFFFFFDE7), const Color(0xFFF57F17),
                        subtitle: '${eggs['broken'] ?? 0} broken'),
                    error: (_, __) => _statCard(
                        context, '🥚', 'Eggs Today',
                        NumberFormatter.format(eggs['good'] as int? ?? 0),
                        const Color(0xFFFFFDE7), const Color(0xFFF57F17),
                        subtitle: '${eggs['broken'] ?? 0} broken'),
                  ),
                  loading: () => _statCardShimmer(),
                  error: (_, __) => _statCard(context, '🥚', 'Eggs Today',
                      '—', const Color(0xFFFFFDE7), const Color(0xFFF57F17)),
                ),
                const SizedBox(width: 12),
                todaySales.when(
                  data: (sales) => _statCard(
                      context, '💰', 'Revenue',
                      CurrencyFormatter.format(
                          (sales['revenue'] as num?)?.toDouble() ?? 0,
                          symbol: currencySymbol,
                          decimalDigits: 0),
                      const Color(0xFFE3F2FD), const Color(0xFF1565C0),
                      subtitle: '${sales['quantity'] ?? 0} sold'),
                  loading: () => _statCardShimmer(),
                  error: (_, __) => _statCard(context, '💰', 'Revenue',
                      '—', const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
                ),
                const SizedBox(width: 12),
                remainingStock.when(
                  data: (stock) => _statCard(
                      context, '📦', 'Egg Stock',
                      NumberFormatter.format(stock),
                      const Color(0xFFE0F7FA), const Color(0xFF00838F),
                      subtitle: 'remaining'),
                  loading: () => _statCardShimmer(),
                  error: (_, __) => _statCard(context, '📦', 'Egg Stock',
                      '—', const Color(0xFFE0F7FA), const Color(0xFF00838F)),
                ),
                const SizedBox(width: 12),
                stockAsync.when(
                  data: (stock) => _statCard(
                      context, '🌾', 'Feed Stock',
                      '${CurrencyFormatter.formatSimple(stock)} kg',
                      const Color(0xFFFCE4EC), const Color(0xFFC62828)),
                  loading: () => _statCardShimmer(),
                  error: (_, __) => _statCard(context, '🌾', 'Feed Stock',
                      '—', const Color(0xFFFCE4EC), const Color(0xFFC62828)),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String emoji, String label,
      String value, Color bgColor, Color textColor,
      {String? subtitle}) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            subtitle ?? label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontFamily: 'Inter',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _statCardShimmer() {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const LoadingShimmer(height: 120),
    );
  }

  // ─── Manage your farm ─────────────────────────────────────────────────────
  Widget _buildManageSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Manage Your Farm', null),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            children: [
              _farmCard(
                context,
                emoji: '🐔',
                title: 'My Flock',
                gradient: const LinearGradient(
                  colors: [Color(0xFFF9FBE7), Color(0xFFF0F4C3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                accentColor: const Color(0xFF827717),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FlockScreen()),
                ),
              ),
              _farmCard(
                context,
                emoji: '🥚',
                title: 'Eggs',
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                accentColor: const Color(0xFF6A1B9A),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EggsScreen()),
                ),
              ),
              _farmCard(
                context,
                emoji: '💵',
                title: 'Sales',
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFDCEDC8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                accentColor: const Color(0xFF2E7D32),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesScreen()),
                ),
              ),
              _farmCard(
                context,
                emoji: '🌾',
                title: 'Feed',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                accentColor: const Color(0xFFF57F17),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _farmCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required Gradient gradient,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Big emoji background
            Positioned(
              right: -10,
              bottom: -10,
              child: Text(emoji,
                  style: TextStyle(
                      fontSize: 70,
                      color: accentColor.withValues(alpha: 0.15))),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 24))),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'Tap to manage',
                    style: TextStyle(
                      fontSize: 10,
                      color: accentColor.withValues(alpha: 0.6),
                      fontFamily: 'Inter',
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

  // ─── Weekly chart ──────────────────────────────────────────────────────────
  Widget _buildWeeklyChart(
      BuildContext context, AsyncValue<List<Map<String, dynamic>>> weeklyData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('📊', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Weekly Production',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B5E20),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: weeklyData.when(
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🥚', style: TextStyle(fontSize: 36)),
                          SizedBox(height: 8),
                          Text('No eggs collected yet',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }
                  return _buildBarChart(data);
                },
                loading: () => const LoadingShimmer(height: 160),
                error: (_, __) => const Center(child: Text('Error')),
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
                width: 22,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value % 10 == 0) {
                  return Text(value.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 9, color: Colors.grey));
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
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateHelpers.getWeekdayShort(days[dayIndex]),
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50)),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: effectiveMaxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: const Color(0xFF2E7D32),
            tooltipRoundedRadius: 12,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} 🥚',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Quick Actions', null),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _quickActionButton(
                  context,
                  emoji: '📋',
                  label: 'Expenses',
                  bgColor: const Color(0xFFFCE4EC),
                  textColor: const Color(0xFFC62828),
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExpensesScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionButton(
                  context,
                  emoji: '📈',
                  label: 'Reports',
                  bgColor: const Color(0xFFE8EAF6),
                  textColor: const Color(0xFF283593),
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context, {
    required String emoji,
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pending Orders Section ───────────────────────────────────────────────
  Widget _buildPendingOrdersSection(BuildContext context, WidgetRef ref) {
    final pendingOrders = ref.watch(pendingOrdersProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pending Orders',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                  fontFamily: 'Inter',
                ),
              ),
              pendingOrders.when(
                data: (orders) => orders.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${orders.length} orders',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE65100),
                            fontFamily: 'Inter',
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          pendingOrders.when(
            data: (orders) {
              if (orders.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Text('📋', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text(
                          'No pending orders',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All orders have been delivered!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: orders.take(5).map((order) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('📦', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.buyer ?? 'Unknown Buyer',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B5E20),
                                  fontFamily: 'Inter',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${order.quantity} eggs • ${DateHelpers.formatCompact(order.orderDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            await ref.read(eggSalesProvider.notifier).markAsDelivered(order.id!);
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Color(0xFF2E7D32),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const LoadingShimmer(height: 120),
            error: (_, __) => const Center(child: Text('Error loading orders')),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ─────────────────────────────────────────────────────────
  Widget _sectionTitle(
      BuildContext context, String title, String? actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B5E20),
            fontFamily: 'Inter',
          ),
        ),
        if (actionText != null)
          Text(
            actionText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
              fontFamily: 'Inter',
            ),
          ),
      ],
    );
  }
}
