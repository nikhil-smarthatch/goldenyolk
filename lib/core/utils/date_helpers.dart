import 'package:intl/intl.dart';

class DateHelpers {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yy');
  static final DateFormat _dayNameFormat = DateFormat('EEEE');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _compactDateFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);
  static String formatDayName(DateTime date) => _dayNameFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatCompact(DateTime date) => _compactDateFormat.format(date);
  
  static String getWeekdayShort(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  static DateTime get startOfDay => DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );

  static DateTime get endOfDay => DateTime.now().copyWith(
        hour: 23,
        minute: 59,
        second: 59,
        millisecond: 999,
        microsecond: 999,
      );

  static DateTime startOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1)).copyWith(
          hour: 0,
          minute: 0,
          second: 0,
          millisecond: 0,
          microsecond: 0,
        );
  }

  static DateTime endOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.add(Duration(days: 7 - dayOfWeek)).copyWith(
          hour: 23,
          minute: 59,
          second: 59,
          millisecond: 999,
          microsecond: 999,
        );
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  static List<DateTime> getLast7Days() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index));
    });
  }

  static List<DateTime> getDaysInMonth(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List.generate(
      daysInMonth,
      (index) => DateTime(year, month, index + 1),
    );
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int daysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
