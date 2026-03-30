import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/db_helper.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/utils/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Farm Information'),
          ListTile(
            leading: const Icon(Icons.agriculture),
            title: const Text('Farm Name'),
            subtitle: Text(settings.farmName),
            onTap: () => _showEditFarmNameDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Owner Name'),
            subtitle: Text(settings.ownerName.isEmpty ? 'Not set' : settings.ownerName),
            onTap: () => _showEditOwnerNameDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text('Currency Symbol'),
            subtitle: Text(settings.currencySymbol),
            onTap: () => _showEditCurrencyDialog(context),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Dark Mode'),
            subtitle: Text(isDarkMode ? 'Enabled' : 'Disabled'),
            value: isDarkMode,
            onChanged: (value) => ref.read(themeProvider.notifier).setDarkMode(value),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Feed Types'),
          ListTile(
            leading: const Icon(Icons.grain),
            title: const Text('Manage Feed Types'),
            subtitle: Text(settings.feedTypes.join(', ')),
            onTap: () => _showManageFeedTypesDialog(context),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Alerts'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Low Stock Threshold'),
            subtitle: Text('${settings.lowStockThreshold} kg'),
            onTap: () => _showEditThresholdDialog(context),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Data'),
            subtitle: const Text('Export all data as JSON'),
            onTap: _isExporting ? null : () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Data'),
            subtitle: const Text('Import data from JSON backup'),
            onTap: _isImporting ? null : () => _importData(context),
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('PoultryPro'),
            subtitle: Text('Version 1.0.0'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() => _isExporting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final jsonString = jsonEncode(data);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'poultrypro_backup_$timestamp.json';

      // Share the file
      await Share.shareXFiles(
        [XFile.fromData(
          utf8.encode(jsonString),
          name: fileName,
          mimeType: 'application/json',
        )],
        subject: 'PoultryPro Data Backup',
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importData(BuildContext context) async {
    setState(() => _isImporting = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isImporting = false);
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate data structure
      final requiredTables = [
        'flocks', 'mortality_log', 'egg_collection', 'egg_sales',
        'chicken_sales', 'feed_purchases', 'feed_usage', 'expenses'
      ];

      for (final table in requiredTables) {
        if (!data.containsKey(table) || data[table] is! List) {
          throw FormatException('Invalid backup file: missing $table');
        }
      }

      // Show confirmation dialog
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Restore'),
          content: const Text(
            'This will replace ALL existing data with the backup data. This action cannot be undone. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await DatabaseHelper.instance.importAllData(
          data.map((key, value) => MapEntry(key, List<Map<String, dynamic>>.from(value))),
        );

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Data restored successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _showEditFarmNameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: ref.read(settingsProvider).farmName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farm Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter farm name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).updateSettings(
                farmName: controller.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditOwnerNameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: ref.read(settingsProvider).ownerName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Owner Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter owner name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).updateSettings(
                ownerName: controller.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditCurrencyDialog(BuildContext context) {
    final currencies = [r'₹', r'$', r'€', r'£', r'¥'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency Symbol'),
        content: Wrap(
          spacing: 8,
          children: currencies.map((currency) {
            final isSelected = ref.read(settingsProvider).currencySymbol == currency;
            return ChoiceChip(
              label: Text(currency, style: const TextStyle(fontSize: 18)),
              selected: isSelected,
              onSelected: (_) {
                ref.read(settingsProvider.notifier).updateSettings(
                  currencySymbol: currency,
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showManageFeedTypesDialog(BuildContext context) {
    final currentTypes = List<String>.from(ref.read(settingsProvider).feedTypes);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manage Feed Types'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'New Feed Type',
                    hintText: 'e.g., finisher, broiler',
                    suffixIcon: Icon(Icons.add),
                  ),
                  onSubmitted: (value) {
                    final newType = value.trim().toLowerCase();
                    if (newType.isNotEmpty && !currentTypes.contains(newType)) {
                      setState(() {
                        currentTypes.add(newType);
                      });
                      controller.clear();
                    }
                  },
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: currentTypes.length,
                    itemBuilder: (context, index) {
                      final type = currentTypes[index];
                      return ListTile(
                        dense: true,
                        title: Text(type.toUpperCase()),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() {
                              currentTypes.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).updateSettings(
                  feedTypes: currentTypes,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditThresholdDialog(BuildContext context) {
    final controller = TextEditingController(
      text: ref.read(settingsProvider).lowStockThreshold.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Low Stock Threshold'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Alert when stock below (kg)',
            suffixText: 'kg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value > 0) {
                ref.read(settingsProvider.notifier).updateSettings(
                  lowStockThreshold: value,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
