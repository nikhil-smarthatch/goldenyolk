import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/flock_provider.dart';
import '../../core/providers/sales_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../widgets/widgets.dart';

class AddChickenSaleScreen extends ConsumerStatefulWidget {
  final ChickenSale? sale;
  const AddChickenSaleScreen({super.key, this.sale});

  @override
  ConsumerState<AddChickenSaleScreen> createState() => _AddChickenSaleScreenState();
}

class _AddChickenSaleScreenState extends ConsumerState<AddChickenSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  int? _selectedFlockId;
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
      _date = sale.date;
      _selectedFlockId = sale.flockId;
      _quantityController.text = sale.quantity.toString();
      _priceController.text = sale.pricePerBird.toString();
      _buyerController.text = sale.buyer ?? '';
      _notesController.text = sale.notes ?? '';
    } else {
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
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
      final sale = ChickenSale(
        id: widget.sale?.id,
        flockId: _selectedFlockId,
        date: _date,
        quantity: int.parse(_quantityController.text.trim()),
        pricePerBird: double.parse(_priceController.text.trim()),
        buyer: _buyerController.text.trim().isEmpty 
            ? null 
            : _buyerController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      if (widget.sale != null) {
        await ref.read(chickenSalesProvider.notifier).updateSale(sale);
      } else {
        await ref.read(chickenSalesProvider.notifier).addSale(sale);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.sale != null 
              ? 'Sale updated' 
              : 'Chicken sale recorded')),
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
    final flockAsync = ref.watch(flockProvider);
    final isEditing = widget.sale != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Chicken Sale' : 'Add Chicken Sale'),
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
              _buildFlockSelector(flockAsync),
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
                        hintText: 'Number of birds',
                        prefixIcon: Icon(Icons.pets),
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
                        labelText: 'Price per Bird',
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

  Widget _buildFlockSelector(AsyncValue<List<dynamic>> flockAsync) {
    return flockAsync.when(
      data: (flocks) {
        if (flocks.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No flocks available. Please add a flock first.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<int?>(
          initialValue: _selectedFlockId,
          decoration: const InputDecoration(
            labelText: 'Select Flock (Optional)',
            prefixIcon: Icon(Icons.pets),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('No specific flock'),
            ),
            ...flocks.map((flock) {
              return DropdownMenuItem(
                value: flock.id,
                child: Text('${flock.name} (${flock.breed})'),
              );
            }),
          ],
          onChanged: (value) => setState(() => _selectedFlockId = value),
        );
      },
      loading: () => const LoadingShimmer(height: 56),
      error: (_, __) => const Text('Error loading flocks'),
    );
  }
}
