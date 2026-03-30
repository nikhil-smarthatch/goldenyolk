import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final String farmName;
  final String ownerName;
  final String currencySymbol;
  final double lowStockThreshold;
  final List<String> feedTypes;

  const AppSettings({
    this.farmName = 'My Poultry Farm',
    this.ownerName = '',
    this.currencySymbol = '₹',
    this.lowStockThreshold = 50.0,
    this.feedTypes = const ['starter', 'grower', 'layer'],
  });

  AppSettings copyWith({
    String? farmName,
    String? ownerName,
    String? currencySymbol,
    double? lowStockThreshold,
    List<String>? feedTypes,
  }) {
    return AppSettings(
      farmName: farmName ?? this.farmName,
      ownerName: ownerName ?? this.ownerName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      feedTypes: feedTypes ?? this.feedTypes,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final feedTypesJson = prefs.getStringList('feed_types') ?? ['starter', 'grower', 'layer'];
    state = AppSettings(
      farmName: prefs.getString('farm_name') ?? 'My Poultry Farm',
      ownerName: prefs.getString('owner_name') ?? '',
      currencySymbol: prefs.getString('currency_symbol') ?? '₹',
      lowStockThreshold: prefs.getDouble('low_stock_threshold') ?? 50.0,
      feedTypes: feedTypesJson,
    );
  }

  Future<void> updateSettings({
    String? farmName,
    String? ownerName,
    String? currencySymbol,
    double? lowStockThreshold,
    List<String>? feedTypes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (farmName != null) {
      await prefs.setString('farm_name', farmName);
    }
    if (ownerName != null) {
      await prefs.setString('owner_name', ownerName);
    }
    if (currencySymbol != null) {
      await prefs.setString('currency_symbol', currencySymbol);
    }
    if (lowStockThreshold != null) {
      await prefs.setDouble('low_stock_threshold', lowStockThreshold);
    }
    if (feedTypes != null) {
      await prefs.setStringList('feed_types', feedTypes);
    }
    
    state = state.copyWith(
      farmName: farmName,
      ownerName: ownerName,
      currencySymbol: currencySymbol,
      lowStockThreshold: lowStockThreshold,
      feedTypes: feedTypes,
    );
  }
}
