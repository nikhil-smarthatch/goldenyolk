import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/flock_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../widgets/widgets.dart';
import 'add_flock_screen.dart';

class FlockDetailScreen extends ConsumerStatefulWidget {
  final int flockId;

  const FlockDetailScreen({super.key, required this.flockId});

  @override
  ConsumerState<FlockDetailScreen> createState() => _FlockDetailScreenState();
}

class _FlockDetailScreenState extends ConsumerState<FlockDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final flockAsync = ref.watch(flockByIdProvider(widget.flockId));
    final mortalityAsync = ref.watch(mortalityByFlockProvider(widget.flockId));
    final liveCountAsync = ref.watch(liveCountProvider(widget.flockId));

    return flockAsync.when(
      data: (flock) {
        if (flock == null) {
          return const Scaffold(
            body: Center(child: Text('Flock not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(flock.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _EditFlockDialog(flock: flock),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(flockByIdProvider(widget.flockId));
              ref.invalidate(mortalityByFlockProvider(widget.flockId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFlockInfoCard(context, flock, liveCountAsync),
                  const SizedBox(height: 24),
                  _buildMortalitySection(context, mortalityAsync, flock),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddMortalityDialog(context, flock),
            icon: const Icon(Icons.warning_amber),
            label: const Text('Record Mortality'),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildFlockInfoCard(
    BuildContext context,
    Flock flock,
    AsyncValue<int> liveCountAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    flock.purpose.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Breed', flock.breed),
            _buildInfoRow(
              'Date Acquired',
              DateHelpers.formatDate(flock.dateAcquired),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    context,
                    'Initial',
                    NumberFormatter.format(flock.initialCount),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: liveCountAsync.when(
                    data: (count) => _buildStatBox(
                      context,
                      'Current Alive',
                      NumberFormatter.format(count),
                      count < flock.initialCount * 0.9
                          ? Colors.orange
                          : Colors.green,
                    ),
                    loading: () => const LoadingShimmer(height: 70),
                    error: (_, __) => _buildStatBox(
                      context,
                      'Current Alive',
                      'Error',
                      Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: liveCountAsync.when(
                    data: (count) => _buildStatBox(
                      context,
                      'Deaths',
                      NumberFormatter.format(flock.initialCount - count),
                      Colors.red,
                    ),
                    loading: () => const LoadingShimmer(height: 70),
                    error: (_, __) => _buildStatBox(
                      context,
                      'Deaths',
                      'Error',
                      Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            if (flock.notes != null) ...[
              const Divider(height: 24),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(flock.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMortalitySection(
    BuildContext context,
    AsyncValue<List<MortalityLog>> mortalityAsync,
    Flock flock,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mortality History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        mortalityAsync.when(
          data: (mortalities) {
            if (mortalities.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Mortality Records',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This is good! No deaths recorded for this flock.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mortalities.length,
              itemBuilder: (context, index) {
                final mortality = mortalities[index];
                return _buildMortalityCard(context, mortality, flock);
              },
            );
          },
          loading: () => const CardShimmer(count: 2),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }

  Widget _buildMortalityCard(
      BuildContext context, MortalityLog mortality, Flock flock) {
    return SwipeableListItem(
      onEdit: () => _showEditMortalityDialog(context, mortality, flock),
      onDelete: () async {
        await ref
            .read(mortalityByFlockProvider(flock.id!).notifier)
            .deleteMortality(mortality.id!);
      },
      confirmDeleteMessage: 'Delete this mortality record?',
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            child: const Icon(Icons.warning, color: Colors.red),
          ),
          title: Text(
            '${mortality.count} birds - ${mortality.reason}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(DateHelpers.formatDate(mortality.date)),
          trailing: mortality.notes != null
              ? const Icon(Icons.notes, size: 16)
              : null,
        ),
      ),
    );
  }

  void _showAddMortalityDialog(BuildContext context, Flock flock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MortalityForm(flockId: flock.id!),
    );
  }

  void _showEditMortalityDialog(
      BuildContext context, MortalityLog mortality, Flock flock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MortalityForm(
        flockId: flock.id!,
        mortality: mortality,
      ),
    );
  }
}

class _MortalityForm extends ConsumerStatefulWidget {
  final int flockId;
  final MortalityLog? mortality;

  const _MortalityForm({required this.flockId, this.mortality});

  @override
  ConsumerState<_MortalityForm> createState() => _MortalityFormState();
}

class _MortalityFormState extends ConsumerState<_MortalityForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _countController;
  late final TextEditingController _notesController;
  late DateTime _date;
  late String _reason;
  bool _isLoading = false;

  final List<String> _reasons = [
    'Disease',
    'Accident',
    'Predator',
    'Unknown',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final mortality = widget.mortality;
    _countController = TextEditingController(
      text: mortality?.count.toString() ?? '',
    );
    _notesController = TextEditingController(text: mortality?.notes ?? '');
    _date = mortality?.date ?? DateTime.now();
    _reason = mortality?.reason ?? 'Disease';
  }

  @override
  void dispose() {
    _countController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final mortality = MortalityLog(
        id: widget.mortality?.id,
        flockId: widget.flockId,
        date: _date,
        count: int.parse(_countController.text.trim()),
        reason: _reason,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.mortality == null) {
        await ref
            .read(mortalityByFlockProvider(widget.flockId).notifier)
            .addMortality(mortality);
      } else {
        await ref
            .read(mortalityByFlockProvider(widget.flockId).notifier)
            .updateMortality(mortality);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.mortality == null
                ? 'Mortality recorded'
                : 'Mortality updated'),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.mortality == null
                    ? 'Record Mortality'
                    : 'Edit Mortality',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of Birds',
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) => Validators.positiveInteger(
                  value,
                  fieldName: 'Count',
                ),
              ),
              const SizedBox(height: 16),
              DatePickerField(
                label: 'Date',
                initialDate: _date,
                onDateSelected: (date) => setState(() => _date = date),
                validator: (date) => Validators.dateNotInFuture(date),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: Icon(Icons.help_outline),
                ),
                items: _reasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _reason = value!),
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
                label: Text(_isLoading ? 'Saving...' : 'Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditFlockDialog extends StatelessWidget {
  final Flock flock;

  const _EditFlockDialog({required this.flock});

  @override
  Widget build(BuildContext context) {
    // Navigate to AddFlockScreen for editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AddFlockScreen(flock: flock),
        ),
      );
    });
    return const SizedBox.shrink();
  }
}
