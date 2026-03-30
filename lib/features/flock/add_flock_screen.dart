import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/flock_provider.dart';
import '../../core/utils/validators.dart';
import '../../widgets/widgets.dart';

class AddFlockScreen extends ConsumerStatefulWidget {
  final Flock? flock;

  const AddFlockScreen({super.key, this.flock});

  @override
  ConsumerState<AddFlockScreen> createState() => _AddFlockScreenState();
}

class _AddFlockScreenState extends ConsumerState<AddFlockScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _countController;
  late final TextEditingController _notesController;
  late DateTime _dateAcquired;
  late String _purpose = widget.flock?.purpose ?? 'layer';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final flock = widget.flock;
    _nameController = TextEditingController(text: flock?.name ?? '');
    _breedController = TextEditingController(text: flock?.breed ?? '');
    _countController = TextEditingController(
      text: flock?.initialCount.toString() ?? '',
    );
    _notesController = TextEditingController(text: flock?.notes ?? '');
    _dateAcquired = flock?.dateAcquired ?? DateTime.now();
    _purpose = flock?.purpose ?? 'layer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveFlock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final flock = Flock(
        id: widget.flock?.id,
        name: _nameController.text.trim(),
        breed: _breedController.text.trim(),
        initialCount: int.parse(_countController.text.trim()),
        dateAcquired: _dateAcquired,
        purpose: _purpose,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.flock?.createdAt,
      );

      if (widget.flock == null) {
        await ref.read(flockProvider.notifier).addFlock(flock);
      } else {
        await ref.read(flockProvider.notifier).updateFlock(flock);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.flock == null
                ? 'Flock added successfully'
                : 'Flock updated successfully'),
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.flock == null ? 'Add Flock' : 'Edit Flock'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Batch Name',
                  hintText: 'e.g., Batch A - January 2024',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) =>
                    Validators.required(value, fieldName: 'Batch name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(
                  labelText: 'Breed',
                  hintText: 'e.g., Rhode Island Red',
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) =>
                    Validators.required(value, fieldName: 'Breed'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Count',
                  hintText: 'Number of birds',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                validator: (value) =>
                    Validators.positiveInteger(value, fieldName: 'Count'),
              ),
              const SizedBox(height: 16),
              DatePickerField(
                label: 'Date Acquired',
                initialDate: _dateAcquired,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                onDateSelected: (date) => setState(() => _dateAcquired = date),
                validator: (date) => Validators.dateNotInFuture(date,
                    fieldName: 'Date acquired'),
              ),
              const SizedBox(height: 16),
              _buildPurposeSelector(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional information...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveFlock,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(widget.flock == null ? Icons.add : Icons.save),
                label: Text(_isLoading
                    ? 'Saving...'
                    : (widget.flock == null ? 'Add Flock' : 'Update Flock')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurposeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purpose',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PurposeOption(
                label: 'Layer',
                icon: Icons.egg,
                isSelected: _purpose == 'layer',
                onTap: () => setState(() => _purpose = 'layer'),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PurposeOption(
                label: 'Broiler',
                icon: Icons.restaurant,
                isSelected: _purpose == 'broiler',
                onTap: () => setState(() => _purpose = 'broiler'),
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PurposeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _PurposeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? color.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
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
