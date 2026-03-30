import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/customer_pricing_provider.dart';
import '../../core/providers/sales_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../widgets/widgets.dart';

class AddEggSaleScreen extends ConsumerStatefulWidget {
  final EggSale? sale;
  const AddEggSaleScreen({super.key, this.sale});

  @override
  ConsumerState<AddEggSaleScreen> createState() => _AddEggSaleScreenState();
}

class _AddEggSaleScreenState extends ConsumerState<AddEggSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _buyerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _paymentStatus = 'paid';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;
    if (sale != null) {
      _date = sale.date;
      _quantityController.text = sale.quantity.toString();
      _priceController.text = sale.pricePerUnit.toString();
      _buyerController.text = sale.buyer ?? '';
      _notesController.text = sale.notes ?? '';
      _paymentStatus = sale.paymentStatus;
    } else {
      _date = DateTime.now();
    }
    
    // Listen to buyer changes to auto-fill price
    _buyerController.addListener(_onBuyerChanged);
  }

  void _onBuyerChanged() {
    final buyerName = _buyerController.text.trim();
    if (buyerName.isNotEmpty && _priceController.text.isEmpty) {
      // Only auto-fill if price is empty
      final priceAsync = ref.read(customerPriceProvider(buyerName));
      priceAsync.when(
        data: (price) {
          if (price != null && mounted) {
            setState(() {
              _priceController.text = price.toString();
            });
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    }
  }

  @override
  void dispose() {
    _buyerController.removeListener(_onBuyerChanged);
    _quantityController.dispose();
    _priceController.dispose();
    _buyerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sale = EggSale(
        id: widget.sale?.id,
        date: _date,
        quantity: int.parse(_quantityController.text.trim()),
        pricePerUnit: double.parse(_priceController.text.trim()),
        buyer: _buyerController.text.trim().isEmpty 
            ? null 
            : _buyerController.text.trim(),
        paymentStatus: _paymentStatus,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      if (widget.sale != null) {
        await ref.read(eggSalesProvider.notifier).updateSale(sale);
      } else {
        await ref.read(eggSalesProvider.notifier).addSale(sale);
      }

      // Save/update customer price for future use
      if (sale.buyer != null && sale.buyer!.isNotEmpty) {
        await ref.read(customerPricingNotifierProvider.notifier)
            .saveCustomerPrice(sale.buyer!, sale.pricePerUnit);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.sale != null 
              ? 'Sale updated' 
              : 'Egg sale recorded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _totalAmount {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return quantity * price;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isEditing = widget.sale != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Egg Sale' : 'Add Egg Sale'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DatePickerField(
                label: 'Sale Date',
                initialDate: _date,
                onDateSelected: (date) => setState(() => _date = date),
                validator: (date) => Validators.dateNotInFuture(date),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyerController,
                decoration: const InputDecoration(
                  labelText: 'Buyer Name (Optional)',
                  hintText: 'Customer or business name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'Number of eggs',
                        prefixIcon: Icon(Icons.egg),
                      ),
                      validator: (value) => Validators.positiveInteger(
                        value,
                        fieldName: 'Quantity',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price per Egg',
                        hintText: '0.00',
                        prefixText: '${settings.currencySymbol} ',
                      ),
                      validator: (value) => Validators.positiveDouble(
                        value,
                        fieldName: 'Price',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        CurrencyFormatter.format(_totalAmount, symbol: settings.currencySymbol),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentStatusSelector(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : (isEditing ? 'Update Sale' : 'Record Sale')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Status',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PaymentStatusOption(
                label: 'Paid',
                icon: Icons.check_circle,
                isSelected: _paymentStatus == 'paid',
                onTap: () => setState(() => _paymentStatus = 'paid'),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentStatusOption(
                label: 'Credit',
                icon: Icons.schedule,
                isSelected: _paymentStatus == 'credit',
                onTap: () => setState(() => _paymentStatus = 'credit'),
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaymentStatusOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _PaymentStatusOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
