import 'package:intl/intl.dart';

// Format date to readable string (e.g., "Mar 12, 2023")
String formatDate(DateTime date) {
  return DateFormat.yMMMd().format(date);
}

// Format date to include time (e.g., "Mar 12, 2023 - 3:45 PM")
String formatDateWithTime(DateTime date) {
  return DateFormat.yMMMd().add_jm().format(date);
}

// Format relative date (e.g., "Today", "Yesterday", "2 days ago")
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  
  final difference = today.difference(dateOnly).inDays;
  
  if (difference == 0) {
    return 'Today';
  } else if (difference == 1) {
    return 'Yesterday';
  } else if (difference < 7) {
    return '$difference days ago';
  } else {
    return DateFormat.yMMMd().format(date);
  }
}

// Format time duration (e.g., "2:30" for 2 minutes 30 seconds)
String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

// Get month name (e.g., "January" for 1)
String getMonthName(int month) {
  final date = DateTime(2022, month);
  return DateFormat.MMMM().format(date);
}