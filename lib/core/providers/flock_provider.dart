import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/models.dart';

final flockProvider = StateNotifierProvider<FlockNotifier, AsyncValue<List<Flock>>>((ref) {
  return FlockNotifier(ref);
});

final flockByIdProvider = Provider.family<AsyncValue<Flock?>, int>((ref, id) {
  final flocksAsync = ref.watch(flockProvider);
  return flocksAsync.when(
    data: (flocks) => AsyncValue.data(flocks.where((f) => f.id == id).firstOrNull),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

// Provider to calculate total live chickens across all flocks
final totalLiveChickensProvider = FutureProvider<int>((ref) async {
  final db = DatabaseHelper.instance;
  final flocks = await db.getAllFlocks();
  
  int totalLive = 0;
  for (final flock in flocks) {
    final mortalities = await db.getMortalityByFlock(flock.id!);
    final totalDeaths = mortalities.fold<int>(0, (sum, m) => sum + m.count);
    totalLive += (flock.initialCount - totalDeaths);
  }
  
  return totalLive;
});

final liveCountProvider = Provider.family<AsyncValue<int>, int>((ref, flockId) {
  final mortalityAsync = ref.watch(mortalityByFlockProvider(flockId));
  final flockAsync = ref.watch(flockByIdProvider(flockId));
  
  return flockAsync.when(
    data: (flock) {
      if (flock == null) return const AsyncValue.data(0);
      return mortalityAsync.when(
        data: (mortalities) {
          final totalDeaths = mortalities.fold<int>(0, (sum, m) => sum + m.count);
          return AsyncValue.data(flock.initialCount - totalDeaths);
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

class FlockNotifier extends StateNotifier<AsyncValue<List<Flock>>> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Ref _ref;

  FlockNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadFlocks();
  }

  Future<void> loadFlocks() async {
    try {
      state = const AsyncValue.loading();
      final flocks = await _db.getAllFlocks();
      state = AsyncValue.data(flocks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addFlock(Flock flock) async {
    try {
      await _db.insertFlock(flock);
      await loadFlocks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateFlock(Flock flock) async {
    try {
      await _db.updateFlock(flock);
      await loadFlocks();
      _ref.invalidate(flockByIdProvider(flock.id!));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteFlock(int id) async {
    try {
      await _db.deleteFlock(id);
      await loadFlocks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final mortalityByFlockProvider = StateNotifierProvider.family<MortalityNotifier, AsyncValue<List<MortalityLog>>, int>((ref, flockId) {
  return MortalityNotifier(flockId, ref);
});

class MortalityNotifier extends StateNotifier<AsyncValue<List<MortalityLog>>> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final int flockId;
  final Ref _ref;

  MortalityNotifier(this.flockId, this._ref) : super(const AsyncValue.loading()) {
    loadMortalities();
  }

  Future<void> loadMortalities() async {
    try {
      state = const AsyncValue.loading();
      final mortalities = await _db.getMortalityByFlock(flockId);
      state = AsyncValue.data(mortalities);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addMortality(MortalityLog mortality) async {
    try {
      await _db.insertMortality(mortality);
      await loadMortalities();
      _ref.invalidate(flockProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateMortality(MortalityLog mortality) async {
    try {
      await _db.updateMortality(mortality);
      await loadMortalities();
      _ref.invalidate(flockProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteMortality(int id) async {
    try {
      await _db.deleteMortality(id);
      await loadMortalities();
      _ref.invalidate(flockProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
