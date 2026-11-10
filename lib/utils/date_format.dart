class AppDateFormat {
  static String mdy(DateTime date) => '${date.month}/${date.day}/${date.year}';

  static DateTime? tryParseMdy(String value) {
    final parts = value.trim().split(RegExp(r'[\/\-]'));
    if (parts.length < 3) return null;
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    var year = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) return null;
    if (year < 100) year += 2000;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static DateTime clampDate(DateTime date, DateTime first, DateTime last) {
    final d = DateTime(date.year, date.month, date.day);
    final f = DateTime(first.year, first.month, first.day);
    final l = DateTime(last.year, last.month, last.day);
    if (d.isBefore(f)) return f;
    if (d.isAfter(l)) return l;
    return d;
  }

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
