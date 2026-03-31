import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/sales_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import '../../widgets/widgets.dart';
import 'add_egg_sale_screen.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Orders'),
            Tab(text: 'Delivered'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildDeliveredTab(),
          _buildPendingTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrderDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }

  void _showAddOrderDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.egg),
              title: const Text('Create Order'),
              subtitle: const Text('Create a new egg order from customer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEggSaleScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    final eggSalesAsync = ref.watch(eggSalesProvider);
    final settings = ref.watch(settingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(eggSalesProvider),
      child: eggSalesAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyState(
              icon: Icons.egg_outlined,
              title: 'No Orders',
              subtitle: 'Create orders from customers to track sales',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _buildOrderCard(context, sale, settings.currencySymbol);
            },
          );
        },
        loading: () => const CardShimmer(count: 3),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDeliveredTab() {
    final deliveredAsync = ref.watch(deliveredOrdersProvider);
    final settings = ref.watch(settingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(eggSalesProvider),
      child: deliveredAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyState(
              icon: Icons.local_shipping,
              title: 'No Delivered Orders',
              subtitle: 'Mark orders as delivered to see them here',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _buildOrderCard(context, sale, settings.currencySymbol);
            },
          );
        },
        loading: () => const CardShimmer(count: 3),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildPendingTab() {
    final pendingAsync = ref.watch(pendingOrdersProvider);
    final settings = ref.watch(settingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(eggSalesProvider),
      child: pendingAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No Pending Orders',
              subtitle: 'All orders have been delivered!',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _buildOrderCard(context, sale, settings.currencySymbol);
            },
          );
        },
        loading: () => const CardShimmer(count: 3),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, dynamic sale, String currencySymbol) {
    return SwipeableListItem(
      onEdit: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEggSaleScreen(sale: sale),
          ),
        );
      },
      onDelete: () async {
        await ref.read(eggSalesProvider.notifier).deleteOrder(sale.id);
      },
      confirmDeleteMessage: 'Delete this order?',
      child: Card(
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
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.egg, color: AppColors.success),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.buyer ?? 'Unknown Buyer',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          DateHelpers.formatDateTime(sale.orderDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    status: sale.status == 'delivered'
                        ? 'Delivered'
                        : sale.status == 'cancelled'
                            ? 'Cancelled'
                            : 'Ordered',
                    color: sale.status == 'delivered'
                        ? AppColors.success
                        : sale.status == 'cancelled'
                            ? AppColors.error
                            : AppColors.warning,
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
                      '${sale.quantity} eggs',
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      context,
                      'Price/Egg',
                      CurrencyFormatter.format(sale.pricePerUnit,
                          symbol: currencySymbol),
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      context,
                      'Total',
                      CurrencyFormatter.format(sale.totalAmount,
                          symbol: currencySymbol),
                      isBold: true,
                    ),
                  ),
                ],
              ),
              if (sale.isOrdered) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(eggSalesProvider.notifier)
                          .markAsDelivered(sale.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Order marked as delivered')),
                        );
                      }
                    },
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Mark Delivered'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value,
      {bool isBold = false}) {
    return Column(
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
    );
  }
}
