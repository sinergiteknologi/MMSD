class AppDateFormat {
  static String mdy(DateTime date) => '${date.month}/${date.day}/${date.year}';

  static DateTime monthStart([DateTime? now]) {
    final date = now ?? DateTime.now();
    return DateTime(date.year, date.month, 1);
  }

  static DateTime monthEnd([DateTime? now]) {
    final date = now ?? DateTime.now();
    return DateTime(date.year, date.month + 1, 0);
  }
}
