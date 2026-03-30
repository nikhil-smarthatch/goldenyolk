import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/feed_provider.dart';
import '../../core/providers/flock_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import '../../widgets/widgets.dart';
import 'add_feed_purchase_screen.dart';
import 'add_feed_usage_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(currentStockProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed & Inventory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Purchases'),
            Tab(text: 'Usage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(stockAsync, settings),
          _buildPurchasesTab(),
          _buildUsageTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewTab(AsyncValue<double> stockAsync, AppSettings settings) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentStockProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            stockAsync.when(
              data: (stock) {
                final isLow = stock < settings.lowStockThreshold;
                return Card(
                  color: isLow ? AppColors.warning.withValues(alpha: 0.1) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.grain,
                          size: 48,
                          color: isLow ? AppColors.warning : AppColors.accentOrange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${CurrencyFormatter.formatSimple(stock)} kg',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isLow ? AppColors.warning : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current Stock',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (isLow) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Low Stock Alert',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              loading: () => const LoadingShimmer(height: 200),
              error: (_, __) => const Center(child: Text('Error loading stock')),
            ),
            const SizedBox(height: 24),
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return FutureBuilder(
      future: Future.wait([
        ref.read(currentStockProvider.future),
      ]),
      builder: (context, snapshot) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 360;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: isSmallScreen ? 1.1 : 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'This Month\nPurchases',
                  '0 kg',
                  Icons.shopping_cart,
                  AppColors.accentBlue,
                ),
                _buildStatCard(
                  'This Month\nUsage',
                  '0 kg',
                  Icons.trending_down,
                  AppColors.accentOrange,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasesTab() {
    final purchasesAsync = ref.watch(feedPurchasesProvider);
    final settings = ref.watch(settingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(feedPurchasesProvider),
      child: purchasesAsync.when(
        data: (purchases) {
          if (purchases.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'No Feed Purchases',
              subtitle: 'Record your feed purchases to track inventory',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFeedPurchaseScreen()),
              ),
              actionLabel: 'Add Purchase',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final purchase = purchases[index];
              return _buildPurchaseCard(context, purchase, settings.currencySymbol);
            },
          );
        },
        loading: () => const CardShimmer(count: 3),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildPurchaseCard(BuildContext context, dynamic purchase, String currencySymbol) {
    Color feedColor;
    switch (purchase.feedType.toLowerCase()) {
      case 'starter':
        feedColor = AppColors.starterFeed;
        break;
      case 'grower':
        feedColor = AppColors.growerFeed;
        break;
      case 'layer':
        feedColor = AppColors.layerFeed;
        break;
      default:
        feedColor = Colors.grey.shade200;
    }

    return SwipeableListItem(
      onEdit: () {},
      onDelete: () async {
        await ref.read(feedPurchasesProvider.notifier).deletePurchase(purchase.id);
      },
      confirmDeleteMessage: 'Delete this feed purchase record?',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: feedColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      purchase.feedType,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateHelpers.formatDate(purchase.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      context,
                      'Quantity',
                      '${CurrencyFormatter.formatSimple(purchase.quantityKg)} kg',
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      context,
                      'Price/kg',
                      CurrencyFormatter.format(purchase.pricePerUnit, symbol: currencySymbol),
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      context,
                      'Total',
                      CurrencyFormatter.format(purchase.totalCost, symbol: currencySymbol),
                      isBold: true,
                    ),
                  ),
                ],
              ),
              if (purchase.supplier != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Supplier: ${purchase.supplier}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageTab() {
    final flockAsync = ref.watch(flockProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(flockProvider),
      child: flockAsync.when(
        data: (flocks) {
          if (flocks.isEmpty) {
            return const EmptyState(
              icon: Icons.grain_outlined,
              title: 'No Flocks',
              subtitle: 'Add flocks to track feed usage',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flocks.length,
            itemBuilder: (context, index) {
              final flock = flocks[index];
              return _buildFlockUsageCard(context, flock);
            },
          );
        },
        loading: () => const CardShimmer(count: 2),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildFlockUsageCard(BuildContext context, dynamic flock) {
    final usageAsync = ref.watch(feedUsageProvider(flock.id!));

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddFeedUsageScreen(flockId: flock.id!),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pets, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      flock.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddFeedUsageScreen(flockId: flock.id!),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              usageAsync.when(
                data: (usage) {
                  final totalUsed = usage.fold<double>(
                    0,
                    (sum, u) => sum + u.quantityKg,
                  );
                  return Row(
                    children: [
                      _buildStat(
                        context,
                        'Total Feed Used',
                        '${CurrencyFormatter.formatSimple(totalUsed)} kg',
                      ),
                      _buildStat(
                        context,
                        'Records',
                        '${usage.length} entries',
                      ),
                    ],
                  );
                },
                loading: () => const LoadingShimmer(height: 50),
                error: (_, __) => const Text('Error'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, {bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Record Feed Purchase'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFeedPurchaseScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_down),
              title: const Text('Record Feed Usage'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to feed usage selection
              },
            ),
          ],
        ),
      ),
    );
  }
}
