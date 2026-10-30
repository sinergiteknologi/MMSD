class AppDateFormat {
  static String mdy(DateTime date) => '${date.month}/${date.day}/${date.year}';

  /// Tanggal hari ini tanpa jam (untuk TranDate dll).
  static String todayMdy() {
    final now = DateTime.now();
    return mdy(DateTime(now.year, now.month, now.day));
  }

  /// Periode YYYYMM (sama Android getPeriode untuk Weekly/Monthly CRM).
  static String periode([DateTime? date]) {
    final d = date ?? DateTime.now();
    final m = d.month.toString().padLeft(2, '0');
    return '${d.year}$m';
  }

  /// Dari string M/d/yyyy atau MM/yyyy → YYYYMM.
  static String periodeFromMdy(String value) {
    final parts = value.trim().split(RegExp(r'[\/\-]'));
    if (parts.length >= 3) {
      final month = parts[0].padLeft(2, '0');
      final year = parts[2].length == 2 ? '20${parts[2]}' : parts[2];
      return '$year$month';
    }
    if (parts.length == 2) {
      // MM/yyyy → YYYYMM (sama Android getPeriode)
      final month = parts[0].padLeft(2, '0');
      final year = parts[1];
      return '$year$month';
    }
    return periode();
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
