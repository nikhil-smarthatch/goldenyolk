// lib/core/sync/wifi_sync_service.dart
// WiFi-based sync for device-to-device data synchronization

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';

/// Simple device representation for WiFi sync
class WifiDevice {
  final String deviceId;
  final String name;
  final String ipAddress;
  final DateTime discoveredAt;

  WifiDevice({
    required this.deviceId,
    required this.name,
    required this.ipAddress,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();
}

/// Sync status for UI feedback
enum SyncStatus { idle, scanning, hosting, connecting, exchanging, complete, error }

/// Simple sync state
class SyncState {
  final SyncStatus status;
  final String? message;
  final int? progressPercent;

  const SyncState({
    this.status = SyncStatus.idle,
    this.message,
    this.progressPercent,
  });

  bool get isActive =>
      status == SyncStatus.scanning ||
      status == SyncStatus.hosting ||
      status == SyncStatus.connecting ||
      status == SyncStatus.exchanging;
}

/// WiFi sync service for Golden Yolk
class WifiSyncService {
  static const String serviceName = 'GoldenYolk';
  static const int port = 8080;

  final _discoveredDevicesController = StreamController<WifiDevice>.broadcast();
  final _syncStateController = StreamController<SyncState>.broadcast();

  Stream<WifiDevice> get discoveredDevices => _discoveredDevicesController.stream;
  Stream<SyncState> get syncState => _syncStateController.stream;
  bool get isHosting => _isHosting;

  HttpServer? _server;
  bool _isScanning = false;
  bool _cancelScan = false; // FIX: cancellation flag
  bool _isHosting = false;
  final List<WifiDevice> _discoveredHosts = [];

  /// Start hosting as HTTP server
  Future<bool> startHosting() async {
    try {
      // FIX: removed init() call - no shared HttpClient
      if (_server != null) {
        _updateState(SyncStatus.hosting, 'Already hosting');
        return true;
      }

      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isHosting = true;

      final ip = await getLocalIpAddress();
      print('Hosting on $ip:$port');
      _updateState(SyncStatus.hosting, 'Hosting on $ip:$port');

      _server!.listen((HttpRequest request) async {
        try {
          if (request.method == 'POST' && request.uri.path == '/sync') {
            await _handleSyncRequest(request);
          } else if (request.method == 'GET' && request.uri.path == '/handshake') {
            await _handleHandshake(request);
          } else {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
          }
        } catch (e) {
          print('Error handling request: $e');
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        }
      });

      return true;
    } catch (e) {
      print('Hosting error: $e');
      _updateState(SyncStatus.error, 'Failed to host: $e');
      return false;
    }
  }

  /// Handle sync request from client
  Future<void> _handleSyncRequest(HttpRequest request) async {
    try {
      final content = await utf8.decodeStream(request);
      final data = jsonDecode(content) as Map<String, dynamic>;

      _updateState(SyncStatus.exchanging, 'Receiving data...', 50);

      // Import received data
      final db = DatabaseHelper.instance;
      await _importData(db, data);

      // Send our data back
      final ourData = await _exportData();

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(ourData));

      await request.response.close();
      _updateState(SyncStatus.complete, 'Sync complete!', 100);

      // Record sync log
      await _recordSync(
        peerId: data['deviceId'] ?? 'unknown',
        direction: 'bidirectional',
        rowsSent: _countRows(ourData),
        rowsReceived: _countRows(data),
      );
    } catch (e) {
      print('Sync request error: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
      _updateState(SyncStatus.error, 'Error: $e');
    }
  }

  /// Handle handshake request
  Future<void> _handleHandshake(HttpRequest request) async {
    final deviceId = await _getDeviceId();
    final response = {
      'deviceName': serviceName,
      'deviceId': deviceId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(response));

    await request.response.close();
  }

  /// Stop hosting
  Future<void> stopHosting() async {
    _isHosting = false;
    if (_server != null) {
      await _server!.close();
      _server = null;
    }
    _updateState(SyncStatus.idle);
  }

  /// Scan for Golden Yolk hosts on local network
  Future<void> startScanning({Duration timeout = const Duration(seconds: 30)}) async {
    if (_isScanning) {
      _updateState(SyncStatus.idle, 'Already scanning...');
      return;
    }

    _discoveredHosts.clear();
    _isScanning = true;
    _cancelScan = false; // FIX: reset cancel flag
    _updateState(SyncStatus.scanning, 'Scanning for devices...');

    final networkInfo = NetworkInfo();
    final wifiIP = await networkInfo.getWifiIP();
    print('Scanning on network: $wifiIP');

    if (wifiIP == null) {
      _isScanning = false;
      _updateState(SyncStatus.error, 'Not connected to WiFi');
      return;
    }

    final segments = wifiIP.split('.');
    if (segments.length != 4) {
      _isScanning = false;
      _updateState(SyncStatus.error, 'Invalid IP address format');
      return;
    }

    final baseIP = '${segments[0]}.${segments[1]}.${segments[2]}';
    _updateState(SyncStatus.scanning, 'Scanning $baseIP.x...');

    final futures = <Future<void>>[];

    for (int i = 1; i <= 254; i++) {
      if (_cancelScan) break; // FIX: respect cancellation
      final testIP = '$baseIP.$i';
      if (testIP != wifiIP) {
        futures.add(_checkHost(testIP));
      }
      if (futures.length >= 50) {
        if (_cancelScan) break; // FIX: respect cancellation in batch
        await Future.wait(futures, eagerError: false);
        futures.clear();
        _updateState(SyncStatus.scanning, 'Scanning... (${_discoveredHosts.length} found)');
      }
    }

    // Wait for remaining
    if (futures.isNotEmpty && !_cancelScan) {
      await Future.wait(futures, eagerError: false);
    }

    _isScanning = false;
    if (_discoveredHosts.isEmpty) {
      _updateState(SyncStatus.idle, 'No devices found on $baseIP.x');
    } else {
      _updateState(SyncStatus.idle, 'Found ${_discoveredHosts.length} device(s)');
    }
  }

  /// Check if a host is running Golden Yolk
  Future<void> _checkHost(String ip) async {
    final client = HttpClient(); // FIX: fresh client per request
    try {
      print('Checking host at $ip:$port...');
      final request = await client // FIX: use local client
          .getUrl(Uri.parse('http://$ip:$port/handshake'))
          .timeout(const Duration(seconds: 1));

      final response = await request.close();
      print('Response from $ip: ${response.statusCode}');

      if (response.statusCode == HttpStatus.ok) {
        final content = await utf8.decodeStream(response);
        print('Handshake response: $content');
        final data = jsonDecode(content) as Map<String, dynamic>;

        if (data['deviceName'] == serviceName) {
          final device = WifiDevice(
            deviceId: data['deviceId'] ?? ip,
            name: '$serviceName ($ip)',
            ipAddress: ip,
          );
          _discoveredHosts.add(device);
          _discoveredDevicesController.add(device);
          print('Found device at $ip');
        } else {
          print('Device at $ip has wrong name: ${data['deviceName']}');
        }
      }
    } on TimeoutException {
      print('Timeout checking $ip');
    } on SocketException catch (e) {
      print('Socket error checking $ip: ${e.message}');
    } catch (e) {
      print('Error checking $ip: $e');
    } finally {
      client.close(); // FIX: always close
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    _cancelScan = true; // FIX: signal running futures to stop
    _isScanning = false;
  }

  /// Connect to host and perform bidirectional sync
  Future<bool> syncWithHost(String hostIp) async {
    final client = HttpClient(); // FIX: fresh client per sync
    try {
      _updateState(SyncStatus.connecting, 'Connecting to $hostIp...', 10);

      // Export our data
      _updateState(SyncStatus.exchanging, 'Preparing data...', 20);
      final ourData = await _exportData();
      ourData['deviceId'] = await _getDeviceId();

      // Send to host and receive their data
      _updateState(SyncStatus.exchanging, 'Sending data...', 40);

      final request = await client // FIX: use local client
          .postUrl(Uri.parse('http://$hostIp:$port/sync'))
          .timeout(const Duration(seconds: 30));

      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(ourData));

      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        _updateState(SyncStatus.exchanging, 'Receiving data...', 60);

        final content = await utf8.decodeStream(response);
        final theirData = jsonDecode(content) as Map<String, dynamic>;

        // Import their data
        _updateState(SyncStatus.exchanging, 'Merging data...', 80);
        final db = DatabaseHelper.instance;
        await _importData(db, theirData);

        _updateState(SyncStatus.complete, 'Sync complete!', 100);

        // Record sync log
        await _recordSync(
          peerId: theirData['deviceId'] ?? hostIp,
          direction: 'bidirectional',
          rowsSent: _countRows(ourData),
          rowsReceived: _countRows(theirData),
        );

        return true;
      }

      return false;
    } catch (e) {
      print('Sync error: $e');
      _updateState(SyncStatus.error, 'Sync failed: $e');
      return false;
    } finally {
      client.close(); // FIX: always close
    }
  }

  /// Export all data from database
  Future<Map<String, dynamic>> _exportData() async {
    final db = await DatabaseHelper.instance.database;

    return {
      'flocks': await db.query('flocks'),
      'mortality_log': await db.query('mortality_log'),
      'egg_collection': await db.query('egg_collection'),
      'egg_sales': await db.query('egg_sales'),
      'feed_purchases': await db.query('feed_purchases'),
      'feed_usage': await db.query('feed_usage'),
      'expenses': await db.query('expenses'),
      'customer_pricing': await db.query('customer_pricing'),
      'payment_history': await db.query('payment_history'),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import data into database
  Future<void> _importData(DatabaseHelper db, Map<String, dynamic> data) async {
    final database = await db.database;
    await database.transaction((txn) async {
      for (final table in [
        'flocks', 'mortality_log', 'egg_collection',
        'egg_sales', 'feed_purchases', 'feed_usage',
        'expenses', 'customer_pricing', 'payment_history'
      ]) {
        final rows = data[table] as List<dynamic>?;
        if (rows == null) continue;

        for (final row in rows) {
          final rowMap = Map<String, dynamic>.from(row as Map);

          final existing = await txn.query(
            table,
            where: 'id = ?',
            whereArgs: [rowMap['id']],
          );

          if (existing.isEmpty) {
            await txn.insert(table, rowMap, conflictAlgorithm: ConflictAlgorithm.ignore);
          } else {
            final existingUpdatedAt = existing.first['updated_at'] ?? existing.first['created_at'];
            final newUpdatedAt = rowMap['updated_at'] ?? rowMap['created_at'];

            if (newUpdatedAt != null && existingUpdatedAt != null) {
              final existingTime = _parseTime(existingUpdatedAt);
              final newTime = _parseTime(newUpdatedAt);

              if (newTime.isAfter(existingTime)) {
                await txn.update(
                  table,
                  rowMap,
                  where: 'id = ?',
                  whereArgs: [rowMap['id']],
                );
              }
            }
          }
        }
      }
    });
  }

  /// Parse time from various formats
  DateTime _parseTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime(1970);
    }
    return DateTime(1970);
  }

  /// Count total rows in exported data
  int _countRows(Map<String, dynamic> data) {
    int count = 0;
    for (final table in [
      'flocks', 'mortality_log', 'egg_collection',
      'egg_sales', 'feed_purchases', 'feed_usage',
      'expenses', 'customer_pricing', 'payment_history'
    ]) {
      final rows = data[table] as List<dynamic>?;
      if (rows != null) count += rows.length;
    }
    return count;
  }

  /// Record sync in log
  Future<void> _recordSync({
    required String peerId,
    required String direction,
    required int rowsSent,
    required int rowsReceived,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('sync_log', {
        'peer_device_id': peerId,
        'last_synced_at': DateTime.now().millisecondsSinceEpoch,
        'sync_direction': direction,
        'rows_sent': rowsSent,
        'rows_received': rowsReceived,
      });
    } catch (e) {
      print('Failed to record sync log: $e');
    }
  }

  /// FIX: Stable device ID persisted in SharedPreferences
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('golden_yolk_device_id');
    if (id == null) {
      id = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('golden_yolk_device_id', id);
    }
    return id;
  }

  /// Get local IP address
  Future<String> getLocalIpAddress() async {
    try {
      final networkInfo = NetworkInfo();
      final wifiIP = await networkInfo.getWifiIP();
      return wifiIP ?? '127.0.0.1';
    } catch (e) {
      return '127.0.0.1';
    }
  }

  /// Update sync state
  void _updateState(SyncStatus status, [String? message, int? progress]) {
    _syncStateController.add(SyncState(
      status: status,
      message: message,
      progressPercent: progress,
    ));
  }

  /// Dispose resources
  void dispose() {
    stopHosting();
    stopScanning();
    _discoveredDevicesController.close();
    _syncStateController.close();
    // FIX: removed _client?.close() - no shared client anymore
  }
}