import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';

class DataExportService {
  static Future<String> exportAllData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Export all tables
      final flocks = await db.query('flocks');
      final mortalityLog = await db.query('mortality_log');
      final eggCollection = await db.query('egg_collection');
      final eggSales = await db.query('egg_sales');
      final feedPurchases = await db.query('feed_purchases');
      final feedUsage = await db.query('feed_usage');
      final expenses = await db.query('expenses');
      final customerPricing = await db.query('customer_pricing');
      final syncLog = await db.query('sync_log');
      final paymentHistory = await db.query('payment_history');

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'data': {
          'flocks': flocks,
          'mortality_log': mortalityLog,
          'egg_collection': eggCollection,
          'egg_sales': eggSales,
          'feed_purchases': feedPurchases,
          'feed_usage': feedUsage,
          'expenses': expenses,
          'customer_pricing': customerPricing,
          'sync_log': syncLog,
          'payment_history': paymentHistory,
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'poultrypro_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  static Future<void> shareExportFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'PoultryPro Data Backup',
      text: 'Here is your PoultryPro data backup file. Keep it safe!',
    );
  }

  static Future<String> exportToCSV() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final eggSales = await db.query('egg_sales');
      final eggCollection = await db.query('egg_collection');
      final expenses = await db.query('expenses');
      final paymentHistory = await db.query('payment_history');

      final buffer = StringBuffer();
      
      // Sales CSV with payment fields
      buffer.writeln('SALES DATA');
      buffer.writeln('ID,Buyer,Quantity,Price Per Unit,Total Amount,Amount Paid,Balance Due,Payment Status,Order Date,Delivery Date,Status,Notes');
      for (final sale in eggSales) {
        final total = (sale['quantity'] as int) * (sale['price_per_unit'] as double);
        final amountPaid = (sale['amount_paid'] as double?) ?? 0.0;
        final balance = total - amountPaid;
        buffer.writeln(
          '"${sale['id']}","${sale['buyer'] ?? ''}","${sale['quantity']}","${sale['price_per_unit']}","$total","$amountPaid","$balance","${sale['payment_status'] ?? 'unpaid'}","${sale['order_date']}","${sale['delivery_date'] ?? ''}","${sale['status']}","${sale['notes'] ?? ''}"',
        );
      }
      
      // Payment History CSV
      if (paymentHistory.isNotEmpty) {
        buffer.writeln('\nPAYMENT HISTORY');
        buffer.writeln('ID,Sale ID,Amount Paid,Payment Date,Notes');
        for (final payment in paymentHistory) {
          buffer.writeln(
            '"${payment['id']}","${payment['sale_id']}","${payment['amount_paid']}","${payment['payment_date']}","${payment['notes'] ?? ''}"',
          );
        }
      }
      
      buffer.writeln('\nEGG COLLECTION DATA');
      buffer.writeln('ID,Flock ID,Date,Collected,Broken,Notes');
      for (final record in eggCollection) {
        buffer.writeln(
          '"${record['id']}","${record['flock_id']}","${record['date']}","${record['collected']}","${record['broken']}","${record['notes'] ?? ''}"',
        );
      }
      
      buffer.writeln('\nEXPENSES DATA');
      buffer.writeln('ID,Category,Amount,Date,Description,Notes');
      for (final expense in expenses) {
        buffer.writeln(
          '"${expense['id']}","${expense['category']}","${expense['amount']}","${expense['date']}","${expense['description']}","${expense['notes'] ?? ''}"',
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'poultrypro_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());
      
      return file.path;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }
}
