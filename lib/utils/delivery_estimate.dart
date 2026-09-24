import 'package:intl/intl.dart';

class DeliveryEstimate {
  /// Calculates estimated delivery date string based on delivery days (default 2 to 3 days)
  static String getEstimate({int minDays = 2, int maxDays = 3}) {
    final now = DateTime.now();
    final minDate = now.add(Duration(days: minDays));
    final maxDate = now.add(Duration(days: maxDays));

    final formatter = DateFormat('EEE, d MMM');
    if (minDate.month == maxDate.month && minDate.day == maxDate.day) {
      return formatter.format(minDate);
    }
    return '${formatter.format(minDate)} - ${formatter.format(maxDate)}';
  }

  /// Calculates hours remaining today for same-day artisan dispatch
  static String getDispatchCountdown() {
    final now = DateTime.now();
    // Cutoff time 6:00 PM local
    final cutoff = DateTime(now.year, now.month, now.day, 18, 0);
    if (now.isBefore(cutoff)) {
      final diff = cutoff.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return 'Order within ${hours}h ${minutes}m for priority dispatch';
    }
    return 'Priority dispatch by 10 AM tomorrow';
  }
}
