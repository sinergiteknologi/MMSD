class ProspectDraft {
  const ProspectDraft({
    required this.company,
    required this.name,
    required this.phone,
    this.phone2 = '',
    this.idNo = '',
    this.provinceCode = '',
    this.cityCode = '',
    this.fgocCode = '',
    this.fgocDesc = '',
    this.fgocType = '',
    this.fgocContactId = '',
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
  final String fgocCode;
  final String fgocDesc;
  final String fgocType;
  final String fgocContactId;
  final String fgocName;
  final String fgocPhone;
  final String fgocPosition;
}

class UnitJoin {
  static String of(List<String?> values) =>
      values.map((value) => value ?? '').join('|');
}

String emptyStr(String? value) => value ?? '';
