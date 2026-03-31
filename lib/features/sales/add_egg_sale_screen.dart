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
  late DateTime _orderDate;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _buyerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;
    if (sale != null) {
      _orderDate = sale.orderDate;
      _quantityController.text = sale.quantity.toString();
      _priceController.text = sale.pricePerUnit.toString();
      _buyerController.text = sale.buyer ?? '';
      _notesController.text = sale.notes ?? '';
    } else {
      _orderDate = DateTime.now();
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
        orderDate: _orderDate,
        deliveryDate: widget.sale?.deliveryDate,
        quantity: int.parse(_quantityController.text.trim()),
        pricePerUnit: double.parse(_priceController.text.trim()),
        buyer: _buyerController.text.trim().isEmpty 
            ? null 
            : _buyerController.text.trim(),
        status: widget.sale?.status ?? 'ordered',
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      if (widget.sale != null) {
        await ref.read(eggSalesProvider.notifier).updateOrder(sale);
      } else {
        await ref.read(eggSalesProvider.notifier).addOrder(sale);
      }
      
      if (mounted) {
        Navigator.pop(context);
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
                label: 'Order Date',
                initialDate: _orderDate,
                onDateSelected: (date) => setState(() => _orderDate = date),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any additional details',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Update Order' : 'Create Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
