import 'package:intl/intl.dart';

String formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) return '';

  final localTimestamp = timestamp.toLocal();
  final now = DateTime.now();

  final hour = localTimestamp.hour % 12 == 0 ? 12 : localTimestamp.hour % 12;
  final minute = localTimestamp.minute.toString().padLeft(2, '0');
  final amPm = localTimestamp.hour >= 12 ? 'PM' : 'AM';

  // Compare calendar days
  final isSameDay =
      localTimestamp.year == now.year &&
      localTimestamp.month == now.month &&
      localTimestamp.day == now.day;

  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday =
      localTimestamp.year == yesterday.year &&
      localTimestamp.month == yesterday.month &&
      localTimestamp.day == yesterday.day;

  if (isSameDay) {
    return 'Today $hour:$minute $amPm';
  } else if (isYesterday) {
    return 'Yesterday $hour:$minute $amPm';
  } else {
    final monthName = DateFormat('MMM').format(localTimestamp);
    return '${localTimestamp.day} $monthName ${localTimestamp.year} $hour:$minute $amPm';
  }
}

/* String formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) return '';

  final localTimestamp = timestamp.toLocal();
  final now = DateTime.now();
  final difference = now.difference(localTimestamp);

  final hour = localTimestamp.hour % 12 == 0 ? 12 : localTimestamp.hour % 12;
  final minute = localTimestamp.minute.toString().padLeft(2, '0');
  final amPm = localTimestamp.hour >= 12 ? 'PM' : 'AM';

  if (difference.inDays == 0) {
    return 'Today $hour:$minute $amPm';
  } else if (difference.inDays == 1) {
    return 'Yesterday $hour:$minute $amPm';
    /* } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago at $hour:$minute $amPm'; */
  } else {
    // Use intl to format with month name
    final monthName = DateFormat('MMM').format(localTimestamp); // e.g. Nov, Dec
    return '${localTimestamp.day} $monthName ${localTimestamp.year} $hour:$minute $amPm';
  }
} */

/* String formatTimestamp(dynamic timestamp) {
  if (timestamp == null) return '';

  try {
    DateTime? dt;

    // Handle DateTime inputs directly
    if (timestamp is DateTime) {
      dt = timestamp;
    } else if (timestamp is String) {
      // Try to parse ISO-like strings; if it fails, treat as already formatted
      dt = DateTime.tryParse(timestamp);
      if (dt == null) {
        return timestamp;
      }
    } else {
      // Fallback for numeric / other types by using toString + tryParse
      dt = DateTime.tryParse(timestamp.toString());
      if (dt == null) {
        return timestamp.toString();
      }
    }

    final local = dt.toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    return '$day $month $year';
  } catch (e, stackTrace) {
    ErrorHandler.handleSilent(
      e,
      stackTrace,
      context: 'Formatting timestamp: $timestamp',
    );
    return '';
  }
} */
