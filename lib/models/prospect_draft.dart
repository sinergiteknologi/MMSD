class ProspectDraft {
  const ProspectDraft({
    required this.company,
    required this.name,
    required this.phone,
    this.phone2 = '',
    this.idNo = '',
    this.provinceCode = '',
    this.cityCode = '',
    this.fgocId = '',
    this.fgocName = '',
    this.fgocPhone = '',
    this.fgocPosition = '',
  });

  final bool company;
  final String name;
  final String phone;
  final String phone2;
  final String idNo;
  final String provinceCode;
  final String cityCode;
  final String fgocId;
  final String fgocName;
  final String fgocPhone;
  final String fgocPosition;
}

class UnitJoin {
  static String of(List<String> values) =>
      values.where((value) => value.isNotEmpty).join('|');
}
