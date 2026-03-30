import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/feed_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../widgets/widgets.dart';

class AddFeedPurchaseScreen extends ConsumerStatefulWidget {
  const AddFeedPurchaseScreen({super.key});

  @override
  ConsumerState<AddFeedPurchaseScreen> createState() => _AddFeedPurchaseScreenState();
}

class _AddFeedPurchaseScreenState extends ConsumerState<AddFeedPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _feedType = 'layer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    // Set default feed type from settings
    final feedTypes = ref.read(settingsProvider).feedTypes;
    if (feedTypes.isNotEmpty) {
      _feedType = feedTypes.first;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final purchase = FeedPurchase(
        date: _date,
        feedType: _feedType,
        quantityKg: double.parse(_quantityController.text.trim()),
        pricePerUnit: double.parse(_priceController.text.trim()),
        supplier: _supplierController.text.trim().isEmpty 
            ? null 
            : _supplierController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      await ref.read(feedPurchasesProvider.notifier).addPurchase(purchase);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feed purchase recorded')),
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

  double get _totalCost {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return quantity * price;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Feed Purchase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DatePickerField(
                label: 'Purchase Date',
                initialDate: _date,
                onDateSelected: (date) => setState(() => _date = date),
                validator: (date) => Validators.dateNotInFuture(date),
              ),
              const SizedBox(height: 16),
              _buildFeedTypeSelector(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier (Optional)',
                  hintText: 'Feed supplier name',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        hintText: 'kg or bags',
                        prefixIcon: Icon(Icons.scale),
                        suffixText: 'kg',
                      ),
                      validator: (value) => Validators.positiveDouble(
                        value,
                        fieldName: 'Quantity',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price per kg',
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
                        'Total Cost',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        CurrencyFormatter.format(_totalCost, symbol: settings.currencySymbol),
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
                label: Text(_isLoading ? 'Saving...' : 'Record Purchase'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedTypeSelector() {
    final settings = ref.watch(settingsProvider);
    final feedTypes = settings.feedTypes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feed Type',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: feedTypes.map((type) {
            final isSelected = _feedType == type;
            final color = _getFeedTypeColor(type);

            return Material(
              color: isSelected ? color.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => setState(() => _feedType = type),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? color : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getFeedTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'starter':
        return Colors.orange;
      case 'grower':
        return Colors.yellow.shade700;
      case 'layer':
        return Colors.blue;
      case 'finisher':
        return Colors.purple;
      case 'broiler':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
