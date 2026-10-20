class HistoryRow {
  final String idNo;
  final String historyId;
  final String date;
  final String phone;
  final String name;
  final String qty;
  final String model;
  final String status;
  final String salesName;
  final String pic;
  final String spkNo;
  final String branchCode;

  const HistoryRow({
    this.idNo = '',
    this.historyId = '',
    this.date = '',
    this.phone = '',
    this.name = '',
    this.qty = '',
    this.model = '',
    this.status = '',
    this.salesName = '',
    this.pic = '',
    this.spkNo = '',
    this.branchCode = '',
  });

  factory HistoryRow.fromPref(Map<String, String> row, {bool isSpk = false}) {
    final pref12 = row['Pref12'] ?? '';
    return HistoryRow(
      idNo: row['Pref1'] ?? '',
      historyId: row['Pref2'] ?? '',
      date: row['Pref3'] ?? '',
      phone: row['Pref4'] ?? '',
      name: row['Pref5'] ?? '',
      qty: row['Pref6'] ?? '',
      model: row['Pref7'] ?? '',
      status: row['Pref8'] ?? '',
      salesName: row['Pref9'] ?? '',
      pic: isSpk ? '' : pref12,
      spkNo: row['Pref11'] ?? '',
      branchCode: isSpk ? pref12 : '',
    );
  }

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final needle = query.toLowerCase();
    return [
      name,
      phone,
      model,
      status,
      salesName,
      idNo,
      spkNo,
    ].any((value) => value.toLowerCase().contains(needle));
  }
}
