import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/feed_provider.dart';
import '../../core/providers/flock_provider.dart';
import '../../core/utils/validators.dart';
import '../../widgets/widgets.dart';

class AddFeedUsageScreen extends ConsumerStatefulWidget {
  final int flockId;

  const AddFeedUsageScreen({super.key, required this.flockId});

  @override
  ConsumerState<AddFeedUsageScreen> createState() => _AddFeedUsageScreenState();
}

class _AddFeedUsageScreenState extends ConsumerState<AddFeedUsageScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final usage = FeedUsage(
        flockId: widget.flockId,
        date: _date,
        quantityKg: double.parse(_quantityController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ref
          .read(feedUsageProvider(widget.flockId).notifier)
          .addUsage(usage);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feed usage recorded')),
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

  @override
  Widget build(BuildContext context) {
    final flockAsync = ref.watch(flockByIdProvider(widget.flockId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Feed Usage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              flockAsync.when(
                data: (flock) {
                  if (flock == null) {
                    return const Text('Flock not found');
                  }
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.pets),
                      title: Text(flock.name),
                      subtitle: Text(flock.breed),
                    ),
                  );
                },
                loading: () => const LoadingShimmer(height: 70),
                error: (_, __) => const Text('Error loading flock'),
              ),
              const SizedBox(height: 24),
              DatePickerField(
                label: 'Usage Date',
                initialDate: _date,
                onDateSelected: (date) => setState(() => _date = date),
                validator: (date) => Validators.dateNotInFuture(date),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Quantity Used',
                  hintText: 'Amount of feed consumed',
                  prefixIcon: Icon(Icons.scale),
                  suffixText: 'kg',
                ),
                validator: (value) => Validators.positiveDouble(
                  value,
                  fieldName: 'Quantity',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional information...',
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
                label: Text(_isLoading ? 'Saving...' : 'Record Usage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
