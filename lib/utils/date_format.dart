class AppDateFormat {
  static String mdy(DateTime date) => '${date.month}/${date.day}/${date.year}';

  /// Tanggal hari ini tanpa jam (untuk TranDate dll).
  static String todayMdy() {
    final now = DateTime.now();
    return mdy(DateTime(now.year, now.month, now.day));
  }

  static DateTime monthStart([DateTime? now]) {
    final date = now ?? DateTime.now();
    return DateTime(date.year, date.month, 1);
  }

  static DateTime monthEnd([DateTime? now]) {
    final date = now ?? DateTime.now();
    return DateTime(date.year, date.month + 1, 0);
  }
}
