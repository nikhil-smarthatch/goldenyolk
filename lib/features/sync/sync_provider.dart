// lib/features/sync/sync_provider.dart
// Riverpod providers for WiFi sync state

import 'dart:async'; // FIX: added for StreamSubscription
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/wifi_sync_service.dart';

/// WiFi sync service singleton provider
final wifiSyncServiceProvider = Provider<WifiSyncService>((ref) {
  final service = WifiSyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Current sync state stream provider
final syncStateStreamProvider = StreamProvider<SyncState>((ref) {
  final service = ref.watch(wifiSyncServiceProvider);
  return service.syncState;
});

/// Current sync state (latest value)
final syncStateProvider = StateProvider<SyncState>((ref) {
  final asyncState = ref.watch(syncStateStreamProvider);
  return asyncState.when(
    data: (state) => state,
    loading: () => const SyncState(status: SyncStatus.idle),
    error: (_, __) => const SyncState(
      status: SyncStatus.error,
      message: 'Failed to load sync state',
    ),
  );
});

/// Is sync currently active
final isSyncingProvider = Provider<bool>((ref) {
  final state = ref.watch(syncStateProvider);
  return state.isActive;
});

/// Sync status enum provider
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final state = ref.watch(syncStateProvider);
  return state.status;
});

/// Sync progress percentage (0-100)
final syncProgressProvider = Provider<int?>((ref) {
  final state = ref.watch(syncStateProvider);
  return state.progressPercent;
});

/// Sync status message
final syncMessageProvider = Provider<String?>((ref) {
  final state = ref.watch(syncStateProvider);
  return state.message;
});

/// Discovered WiFi devices during scanning
final discoveredDevicesProvider = StateProvider<List<WifiDevice>>((ref) => []);

/// Whether currently scanning for devices
final isScanningProvider = StateProvider<bool>((ref) => false);

/// Whether currently hosting
final isHostingProvider = StateProvider<bool>((ref) => false);

/// Local IP address provider
final localIpProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(wifiSyncServiceProvider);
  return await service.getLocalIpAddress();
});

/// Actions provider for sync operations
class SyncActions {
  final Ref _ref;
  StreamSubscription? _scanSubscription; // FIX: track subscription to prevent leaks

  SyncActions(this._ref);

  /// Start scanning for devices on WiFi
  Future<void> startScanning() async {
    final service = _ref.read(wifiSyncServiceProvider);
    final devicesNotifier = _ref.read(discoveredDevicesProvider.notifier);

    await _scanSubscription?.cancel(); // FIX: cancel old listener before creating new one
    _ref.read(isScanningProvider.notifier).state = true;
    devicesNotifier.state = [];

    try {
      // FIX: save subscription so it can be cancelled later
      _scanSubscription = service.discoveredDevices.listen((device) {
        final current = _ref.read(discoveredDevicesProvider);
        if (!current.any((d) => d.deviceId == device.deviceId)) {
          _ref.read(discoveredDevicesProvider.notifier).state = [...current, device];
        }
      });

      await service.startScanning(timeout: const Duration(seconds: 10));
    } catch (e) {
      print('Scan error: $e');
    } finally {
      _ref.read(isScanningProvider.notifier).state = false;
    }
  }

  /// Start hosting as sync server
  Future<void> startHosting() async {
    final service = _ref.read(wifiSyncServiceProvider);

    _ref.read(isHostingProvider.notifier).state = true;

    try {
      await service.startHosting();
    } catch (e) {
      print('Hosting error: $e');
      _ref.read(isHostingProvider.notifier).state = false;
    }
  }

  /// Stop hosting
  Future<void> stopHosting() async {
    final service = _ref.read(wifiSyncServiceProvider);

    await service.stopHosting();
    _ref.read(isHostingProvider.notifier).state = false;
  }

  /// Sync with a discovered device
  Future<bool> syncWithDevice(String deviceIp) async {
    final service = _ref.read(wifiSyncServiceProvider);

    // FIX: cancel scan subscription before syncing
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _ref.read(isScanningProvider.notifier).state = false;

    final success = await service.syncWithHost(deviceIp);

    if (success) {
      // Invalidate all data providers after successful sync
      _invalidateAllProviders();
    }

    return success;
  }

  /// Cancel current operation
  Future<void> cancel() async {
    final service = _ref.read(wifiSyncServiceProvider);

    // FIX: cancel scan subscription on cancel
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    await service.stopScanning();
    await service.stopHosting();

    _ref.read(isScanningProvider.notifier).state = false;
    _ref.read(isHostingProvider.notifier).state = false;
  }

  /// Invalidate all data providers after sync
  void _invalidateAllProviders() {
    try {
      _ref.invalidate(eggSalesProvider);
      _ref.invalidate(eggCollectionProvider);
      _ref.invalidate(flocksProvider);
      _ref.invalidate(expensesProvider);
    } catch (e) {
      // Providers might not exist yet
    }
  }
}

/// Provider for sync actions
final syncActionsProvider = Provider<SyncActions>((ref) => SyncActions(ref));

// Stub providers - will be overridden by actual providers from other files
final eggSalesProvider = Provider((ref) => throw UnimplementedError());
final eggCollectionProvider = Provider((ref) => throw UnimplementedError());
final flocksProvider = Provider((ref) => throw UnimplementedError());
final expensesProvider = Provider((ref) => throw UnimplementedError());