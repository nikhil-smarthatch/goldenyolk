import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/egg_provider.dart';
import '../../core/providers/flock_provider.dart';
import '../../core/utils/validators.dart';
import '../../widgets/widgets.dart';

class AddEggCollectionScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final EggCollection? collection;

  const AddEggCollectionScreen({super.key, this.initialDate, this.collection});

  @override
  ConsumerState<AddEggCollectionScreen> createState() =>
      _AddEggCollectionScreenState();
}

class _AddEggCollectionScreenState
    extends ConsumerState<AddEggCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  int? _selectedFlockId;
  final TextEditingController _collectedController = TextEditingController();
  final TextEditingController _brokenController =
      TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final collection = widget.collection;
    if (collection != null) {
      _date = collection.date;
      _selectedFlockId = collection.flockId;
      _collectedController.text = collection.collected.toString();
      _brokenController.text = collection.broken.toString();
      _notesController.text = collection.notes ?? '';
    } else {
      _date = widget.initialDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _collectedController.dispose();
    _brokenController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFlockId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a flock')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final collected = int.parse(_collectedController.text.trim());
      final broken = int.parse(_brokenController.text.trim());

      if (broken > collected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Broken eggs cannot exceed collected eggs')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final collection = EggCollection(
        id: widget.collection?.id,
        flockId: _selectedFlockId!,
        date: _date,
        collected: collected,
        broken: broken,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.collection != null) {
        await ref
            .read(eggCollectionProvider.notifier)
            .updateCollection(collection);
      } else {
        await ref
            .read(eggCollectionProvider.notifier)
            .addCollection(collection);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.collection != null
                  ? 'Egg collection updated'
                  : 'Egg collection recorded')),
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
    final flockAsync = ref.watch(flockProvider);
    final isEditing = widget.collection != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Egg Collection' : 'Add Egg Collection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DatePickerField(
                label: 'Collection Date',
                initialDate: _date,
                onDateSelected: (date) => setState(() => _date = date),
                validator: (date) => Validators.dateNotInFuture(date),
              ),
              const SizedBox(height: 16),
              _buildFlockSelector(flockAsync),
              const SizedBox(height: 16),
              TextFormField(
                controller: _collectedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Eggs Collected',
                  hintText: 'Total number of eggs',
                  prefixIcon: Icon(Icons.egg),
                ),
                validator: (value) => Validators.positiveInteger(
                  value,
                  fieldName: 'Collected eggs',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brokenController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Broken Eggs',
                  hintText: 'Number of broken eggs',
                  prefixIcon: Icon(Icons.broken_image),
                ),
                validator: (value) => Validators.nonNegativeInteger(
                  value,
                  fieldName: 'Broken eggs',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional notes...',
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
                label: Text(_isLoading ? 'Saving...' : 'Save Collection'),
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
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          );
        }

        return DropdownButtonFormField<int>(
          initialValue: _selectedFlockId,
          decoration: const InputDecoration(
            labelText: 'Select Flock',
            prefixIcon: Icon(Icons.pets),
          ),
          items: flocks.map((flock) {
            return DropdownMenuItem<int>(
              value: flock.id,
              child: Text('${flock.name} (${flock.breed})'),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedFlockId = value),
          validator: (value) => value == null ? 'Please select a flock' : null,
        );
      },
      loading: () => const LoadingShimmer(height: 56),
      error: (_, __) => const Text('Error loading flocks'),
    );
  }
}
