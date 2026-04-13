// lib/features/sync/sync_screen.dart
// UI for WiFi device-to-device sync

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/wifi_sync_service.dart';
import 'sync_provider.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final isScanning = ref.watch(isScanningProvider);
    final isHosting = ref.watch(isHostingProvider);
    final discoveredDevices = ref.watch(discoveredDevicesProvider);
    final localIp = ref.watch(localIpProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'WiFi Sync',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(syncState, isScanning, isHosting, localIp),
              const SizedBox(height: 20),
              if (!syncState.isActive) ...[
                _buildActionButtons(context, ref, isScanning, isHosting),
                const SizedBox(height: 20),
              ],
              if (isScanning || discoveredDevices.isNotEmpty)
                _buildDiscoveredDevices(context, ref, discoveredDevices, isScanning),
              if (isScanning || discoveredDevices.isNotEmpty) const SizedBox(height: 20),
              if (syncState.isActive) ...[
                _buildProgressIndicator(syncState),
                const SizedBox(height: 20),
              ],
              if (syncState.isActive)
                _buildCancelButton(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(SyncState syncState, bool isScanning, bool isHosting, AsyncValue<String> localIp) {
    IconData icon;
    Color color;
    String title;
    Widget subtitle;

    if (isScanning) {
      icon = Icons.search;
      color = const Color(0xFF1565C0);
      title = 'Scanning...';
      subtitle = const Text('Looking for nearby Golden Yolk devices');
    } else if (isHosting) {
      icon = Icons.broadcast_on_personal;
      color = const Color(0xFF2E7D32);
      title = 'Hosting';
      subtitle = localIp.when(
        data: (ip) => Text('Your IP: $ip:8080'),
        loading: () => const Text('Starting server...'),
        error: (_, __) => const Text('Waiting for connections'),
      );
    } else if (syncState.status == SyncStatus.complete) {
      icon = Icons.check_circle;
      color = const Color(0xFF2E7D32);
      title = 'Sync Complete';
      subtitle = Text(syncState.message ?? 'Data synchronized successfully');
    } else if (syncState.status == SyncStatus.error) {
      icon = Icons.error;
      color = const Color(0xFFC62828);
      title = 'Sync Failed';
      subtitle = Text(syncState.message ?? 'An error occurred');
    } else {
      icon = Icons.sync;
      color = const Color(0xFF2E7D32);
      title = 'Ready to Sync';
      subtitle = const Text('Host or Join to sync with another device on your WiFi network');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Inter',
                  ),
                  child: subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isScanning, bool isHosting) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.broadcast_on_personal,
            label: 'Host',
            color: const Color(0xFF2E7D32),
            onPressed: isHosting
                ? () => ref.read(syncActionsProvider).stopHosting()
                : () => ref.read(syncActionsProvider).startHosting(),
            isActive: isHosting,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            icon: Icons.search,
            label: 'Join',
            color: const Color(0xFF1565C0),
            onPressed: isScanning
                ? () => ref.read(syncActionsProvider).cancel()
                : () => ref.read(syncActionsProvider).startScanning(),
            isActive: isScanning,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : color, size: 40),
            const SizedBox(height: 12),
            Text(
              isActive ? 'Stop $label' : label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : color,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredDevices(BuildContext context, WidgetRef ref, List<WifiDevice> devices, bool isScanning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Devices',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B5E20),
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 12),
        if (devices.isEmpty && isScanning)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF2E7D32))),
            ),
          )
        else if (devices.isEmpty)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Text('No devices found automatically', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    _buildManualIpEntry(context, ref),
                  ],
                ),
              ),
            ],
          )
        else
          ...devices.map((device) => _buildDeviceItem(context, ref, device)),
      ],
    );
  }

  Widget _buildDeviceItem(BuildContext context, WidgetRef ref, WifiDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.wifi, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20), fontFamily: 'Inter')),
                Text('IP: ${device.ipAddress}', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Inter')),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => ref.read(syncActionsProvider).syncWithDevice(device.ipAddress),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sync'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(SyncState syncState) {
    final progress = syncState.progressPercent ?? 0;
    final stepLabels = {
      SyncStatus.scanning: 'Scanning...',
      SyncStatus.hosting: 'Waiting for connection...',
      SyncStatus.connecting: 'Connecting...',
      SyncStatus.exchanging: 'Syncing data...',
      SyncStatus.complete: 'Complete!',
      SyncStatus.error: 'Error',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stepLabels[syncState.status] ?? 'Working...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20), fontFamily: 'Inter')),
              Text('$progress%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600], fontFamily: 'Inter')),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2E7D32)),
              minHeight: 8,
            ),
          ),
          if (syncState.message != null) ...[
            const SizedBox(height: 8),
            Text(syncState.message!, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Inter')),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(syncActionsProvider).cancel(),
        icon: const Icon(Icons.cancel),
        label: const Text('Cancel'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC62828),
          side: const BorderSide(color: Color(0xFFC62828)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildManualIpEntry(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    return Column(
      children: [
        const Text(
          'Enter device IP manually:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '192.168.1.5',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final ip = controller.text.trim();
                if (ip.isNotEmpty) {
                  ref.read(syncActionsProvider).syncWithDevice(ip);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Connect'),
            ),
          ],
        ),
      ],
    );
  }
}