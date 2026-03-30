import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/egg_provider.dart';
import '../../core/providers/flock_provider.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_colors.dart';
import '../../widgets/widgets.dart';
import 'add_egg_collection_screen.dart';

class EggsScreen extends ConsumerStatefulWidget {
  const EggsScreen({super.key});

  @override
  ConsumerState<EggsScreen> createState() => _EggsScreenState();
}

class _EggsScreenState extends ConsumerState<EggsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(eggCollectionProvider);
    final flockAsync = ref.watch(flockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _showProductionChart(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(eggCollectionProvider);
              },
              child: collectionAsync.when(
                data: (collections) {
                  if (collections.isEmpty) {
                    return const EmptyState(
                      icon: Icons.egg_outlined,
                      title: 'No Egg Collections',
                      subtitle: 'Start recording your daily egg collections',
                    );
                  }

                  // Filter by selected date
                  final filtered = collections.where((c) => 
                    DateHelpers.isSameDay(c.date, _selectedDate)
                  ).toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.egg_outlined,
                      title: 'No Collections on ${DateHelpers.formatShortDate(_selectedDate)}',
                      subtitle: 'No eggs recorded for this date',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final collection = filtered[index];
                      return _buildCollectionCard(context, collection, flockAsync);
                    },
                  );
                },
                loading: () => const CardShimmer(count: 3),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEggCollectionScreen(initialDate: _selectedDate),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Collection'),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = DateHelpers.isSameDay(day, _selectedDate);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedDate = day),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateHelpers.formatDayName(day).substring(0, 3),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected 
                            ? Colors.white 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? Colors.white 
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionCard(
    BuildContext context,
    dynamic collection,
    AsyncValue<List<dynamic>> flockAsync,
  ) {
    final flockName = flockAsync.when(
      data: (flocks) {
        final matchingFlocks = flocks.where(
          (f) => f.id == collection.flockId,
        );
        final flock = matchingFlocks.isNotEmpty ? matchingFlocks.first : null;
        return flock?.name ?? 'Unknown Flock';
      },
      loading: () => 'Loading...',
      error: (_, __) => 'Unknown',
    );

    return SwipeableListItem(
      onEdit: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEggCollectionScreen(collection: collection),
          ),
        );
      },
      onDelete: () async {
        await ref.read(eggCollectionProvider.notifier)
            .deleteCollection(collection.id);
      },
      confirmDeleteMessage: 'Delete this egg collection record?',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.egg, color: AppColors.accentYellow),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flockName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateHelpers.formatDateTime(collection.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      context,
                      'Collected',
                      NumberFormatter.format(collection.collected),
                      AppColors.primaryGreen,
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      context,
                      'Good Eggs',
                      NumberFormatter.format(collection.goodEggs),
                      AppColors.success,
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      context,
                      'Broken',
                      NumberFormatter.format(collection.broken),
                      AppColors.error,
                    ),
                  ),
                ],
              ),
              if (collection.notes != null) ...[
                const SizedBox(height: 12),
                Text(
                  collection.notes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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
    );
  }

  void _showProductionChart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ProductionChartView(),
    );
  }
}

class _ProductionChartView extends ConsumerWidget {
  const _ProductionChartView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyData = ref.watch(weeklyEggProductionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Production Trend',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: weeklyData.when(
                  data: (data) {
                    // Build chart here
                    return const Center(child: Text('Chart view coming soon'));
                  },
                  loading: () => const LoadingShimmer(height: 200),
                  error: (_, __) => const Center(child: Text('Error loading chart')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
