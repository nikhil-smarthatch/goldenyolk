import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/flock_provider.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/widgets.dart';
import 'add_flock_screen.dart';
import 'flock_detail_screen.dart';

class FlockScreen extends ConsumerStatefulWidget {
  const FlockScreen({super.key});

  @override
  ConsumerState<FlockScreen> createState() => _FlockScreenState();
}

class _FlockScreenState extends ConsumerState<FlockScreen> {
  @override
  Widget build(BuildContext context) {
    final flockAsync = ref.watch(flockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flock Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(flockProvider);
        },
        child: flockAsync.when(
          data: (flocks) {
            if (flocks.isEmpty) {
              return const EmptyState(
                icon: Icons.pets,
                title: 'No Flocks Yet',
                subtitle: 'Add your first flock to start tracking',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: flocks.length,
              itemBuilder: (context, index) {
                final flock = flocks[index];
                return _FlockCard(flock: flock);
              },
            );
          },
          loading: () => const CardShimmer(count: 3),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddFlockScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Flock'),
      ),
    );
  }
}

class _FlockCard extends ConsumerWidget {
  final dynamic flock;

  const _FlockCard({required this.flock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveCountAsync = ref.watch(liveCountProvider(flock.id!));

    return SwipeableListItem(
      onEdit: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddFlockScreen(flock: flock),
        ),
      ),
      onDelete: () async {
        await ref.read(flockProvider.notifier).deleteFlock(flock.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Flock deleted')),
          );
        }
      },
      confirmDeleteMessage: 'Are you sure you want to delete this flock? This will also delete all related records.',
      child: Hero(
        tag: 'flock_${flock.id}',
        child: Card(
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlockDetailScreen(flockId: flock.id!),
              ),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: flock.purpose == 'layer' 
                              ? AppColors.layerPurpose.withValues(alpha: 0.2)
                              : AppColors.broilerPurpose.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          flock.purpose.toUpperCase(),
                          style: TextStyle(
                            color: flock.purpose == 'layer' 
                                ? Colors.orange[800]
                                : Colors.deepOrange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    flock.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    flock.breed,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      _buildStat(
                        context,
                        'Initial',
                        NumberFormatter.format(flock.initialCount),
                      ),
                      liveCountAsync.when(
                        data: (count) => _buildStat(
                          context,
                          'Current',
                          NumberFormatter.format(count),
                          isHighlighted: true,
                        ),
                        loading: () => _buildStat(
                          context,
                          'Current',
                          '...',
                          isHighlighted: true,
                        ),
                        error: (_, __) => _buildStat(
                          context,
                          'Current',
                          'Err',
                          isHighlighted: true,
                        ),
                      ),
                      _buildStat(
                        context,
                        'Acquired',
                        _formatDate(flock.dateAcquired),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, {bool isHighlighted = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlighted 
                  ? AppColors.primaryGreen 
                  : Theme.of(context).colorScheme.onSurface,
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
