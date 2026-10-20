class DataPref {
  final Map<String, String> values;

  const DataPref(this.values);

  String get(String key) => values[key] ?? '';

  String pref(int index) => get('Pref$index');

  bool get isEmpty => values.values.every((value) => value.isEmpty);

  List<Map<String, String>> toRows({int maxPref = 55}) {
    final columns = <String, List<String>>{};
    var length = 0;
    for (var i = 1; i <= maxPref; i++) {
      final key = 'Pref$i';
      final raw = values[key];
      if (raw == null || raw.isEmpty) continue;
      final parts = raw.split('|');
      columns[key] = parts;
      if (parts.length > length) length = parts.length;
    }
    return List.generate(length, (index) {
      final row = <String, String>{};
      columns.forEach((key, parts) {
        row[key] = index < parts.length ? parts[index] : '';
      });
      return row;
    });
  }
}
