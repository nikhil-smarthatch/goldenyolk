import 'package:flutter/material.dart';
import '../../core/models/egg_sale.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import 'add_egg_sale_screen.dart';

class EggSaleDetailScreen extends ConsumerWidget {
  final EggSale sale;

  const EggSaleDetailScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEggSaleScreen(sale: sale),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.egg,
                      size: 48,
                      color: AppColors.accentYellow,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      CurrencyFormatter.format(sale.totalAmount,
                          symbol: settings.currencySymbol),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sale.isPaid
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sale.isPaid
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sale.isPaid ? Icons.check_circle : Icons.schedule,
                            color: sale.isPaid
                                ? AppColors.success
                                : AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sale.paymentStatus.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sale.isPaid
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Details Section
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            _buildDetailRow(context, 'Order ID', '#${sale.id ?? 'N/A'}'),
            _buildDetailRow(
                context, 'Date', DateHelpers.formatDateTime(sale.date)),
            _buildDetailRow(context, 'Buyer', sale.buyer ?? 'Not specified'),
            _buildDetailRow(context, 'Quantity', '${sale.quantity} eggs'),
            _buildDetailRow(
                context,
                'Price per Egg',
                CurrencyFormatter.format(sale.pricePerUnit,
                    symbol: settings.currencySymbol)),
            _buildDetailRow(
                context,
                'Total',
                CurrencyFormatter.format(sale.totalAmount,
                    symbol: settings.currencySymbol),
                isBold: true),
            _buildDetailRow(context, 'Payment Status', sale.paymentStatus),
            _buildDetailRow(
                context, 'Created', DateHelpers.formatDateTime(sale.createdAt)),

            if (sale.notes != null && sale.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(sale.notes!),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                if (sale.isCredit) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(eggSalesProvider.notifier)
                            .markAsPaid(sale.id!);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Payment marked as paid')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark as Paid'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEggSaleScreen(sale: sale),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Sale'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
