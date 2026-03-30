import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/sales_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import '../../widgets/widgets.dart';
import 'add_egg_sale_screen.dart';
import 'add_chicken_sale_screen.dart';

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
            Tab(text: 'Egg Sales'),
            Tab(text: 'Chicken Sales'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEggSalesTab(),
          _buildChickenSalesTab(),
          _buildPendingPaymentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSaleDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEggSalesTab() {
    final eggSalesAsync = ref.watch(eggSalesProvider);
    final settings = ref.watch(settingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(eggSalesProvider),
      child: eggSalesAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyState(
              icon: Icons.egg_outlined,
              title: 'No Egg Sales',
              subtitle: 'Record your egg sales to track revenue',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _buildEggSaleCard(context, sale, settings.currencySymbol);
            },
          );
        },
        loading: () => const CardShimmer(count: 3),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEggSaleCard(
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
        await ref.read(eggSalesProvider.notifier).deleteSale(sale.id);
      },
      confirmDeleteMessage: 'Delete this egg sale record?',
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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          DateHelpers.formatDateTime(sale.date),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    status: sale.paymentStatus == 'paid' ? 'Paid' : 'Credit',
                    color: sale.paymentStatus == 'paid'
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ],
              ),
              const Divider(height: 24),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChickenSalesTab() {
    final chickenSalesAsync = ref.watch(chickenSalesProvider);
    final settings = ref.watch(settingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(chickenSalesProvider),
      child: chickenSalesAsync.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const EmptyState(
              icon: Icons.pets_outlined,
              title: 'No Chicken Sales',
              subtitle: 'Record chicken sales to track revenue',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              return _buildChickenSaleCard(
                  context, sale, settings.currencySymbol);
            },
          );
        },
        loading: () => const CardShimmer(count: 3),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildChickenSaleCard(
      BuildContext context, dynamic sale, String currencySymbol) {
    return SwipeableListItem(
      onEdit: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddChickenSaleScreen(sale: sale),
          ),
        );
      },
      onDelete: () async {
        await ref.read(chickenSalesProvider.notifier).deleteSale(sale.id);
      },
      confirmDeleteMessage: 'Delete this chicken sale record?',
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
                      color: AppColors.accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.pets, color: AppColors.accentOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.buyer ?? 'Unknown Buyer',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          DateHelpers.formatDateTime(sale.date),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      context,
                      'Quantity',
                      '${sale.quantity} birds',
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      context,
                      'Price/Bird',
                      CurrencyFormatter.format(sale.pricePerBird,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingPaymentsTab() {
    final pendingAsync = ref.watch(pendingPaymentsProvider);
    final settings = ref.watch(settingsProvider);

    return pendingAsync.when(
      data: (sales) {
        if (sales.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Pending Payments',
            subtitle: 'All payments are up to date!',
          );
        }

        final totalPending = sales.fold<double>(
          0,
          (sum, sale) => sum + sale.totalAmount,
        );

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pending',
                          style: TextStyle(
                              color: AppColors.warning.withValues(alpha: 0.8)),
                        ),
                        Text(
                          CurrencyFormatter.format(totalPending,
                              symbol: settings.currencySymbol),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  return _buildPendingCard(
                      context, sale, settings.currencySymbol);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const CardShimmer(count: 2),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildPendingCard(
      BuildContext context, dynamic sale, String currencySymbol) {
    return _PendingCard(
      sale: sale,
      currencySymbol: currencySymbol,
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
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  void _showAddSaleDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.egg),
              title: const Text('Add Egg Sale'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEggSaleScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Add Chicken Sale'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddChickenSaleScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends ConsumerStatefulWidget {
  final dynamic sale;
  final String currencySymbol;

  const _PendingCard({
    required this.sale,
    required this.currencySymbol,
  });

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final currencySymbol = widget.currencySymbol;

    return Card(
      color: AppColors.warning.withValues(alpha: 0.05),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.warning,
          child: Icon(Icons.schedule, color: Colors.white),
        ),
        title: Text(sale.buyer ?? 'Unknown'),
        subtitle: Text(DateHelpers.formatDate(sale.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.format(sale.totalAmount,
                  symbol: currencySymbol),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      try {
                        await ref
                            .read(eggSalesProvider.notifier)
                            .markAsPaid(sale.id);
                      } finally {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Mark Paid'),
            ),
          ],
        ),
      ),
    );
  }
}
