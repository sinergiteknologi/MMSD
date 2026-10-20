class CodeName {
  final String code;
  final String name;

  const CodeName({required this.code, required this.name});

  @override
  bool operator ==(Object other) =>
      other is CodeName && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(code, name);
}

class CityItem {
  final String provinceCode;
  final String cityCode;
  final String cityName;

  const CityItem({
    required this.provinceCode,
    required this.cityCode,
    required this.cityName,
  });

  @override
  bool operator ==(Object other) =>
      other is CityItem &&
      other.provinceCode == provinceCode &&
      other.cityCode == cityCode;

  @override
  int get hashCode => Object.hash(provinceCode, cityCode);
}

class DistrictItem {
  final String provinceCode;
  final String cityCode;
  final String districtCode;
  final String districtName;

  const DistrictItem({
    required this.provinceCode,
    required this.cityCode,
    required this.districtCode,
    required this.districtName,
  });

  @override
  bool operator ==(Object other) =>
      other is DistrictItem &&
      other.provinceCode == provinceCode &&
      other.cityCode == cityCode &&
      other.districtCode == districtCode;

  @override
  int get hashCode => Object.hash(provinceCode, cityCode, districtCode);
}
