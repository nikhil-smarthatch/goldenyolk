import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String symbol = '₹', int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.compactCurrency(
      symbol: symbol,
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  static String formatSimple(double amount, {int decimalDigits = 0}) {
    final formatter = NumberFormat.decimalPattern();
    formatter.maximumFractionDigits = decimalDigits;
    return formatter.format(amount);
  }
}

class NumberFormatter {
  static String format(int number) {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(number);
  }

  static String formatCompact(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
