class HistoryUnit {
  final String brandCode;
  final String brandName;
  final String typeCode;
  final String typeName;
  final String modelCode;
  final String modelName;
  final String colourCode;
  final String colourName;
  final String activityCode;
  final String activityName;
  final String qty;
  final String provinceCode;
  final String cityCode;
  final String districtCode;
  final String subActivityCode;
  final String actNumber;
  final String fleetType;
  final String fleetCode;

  const HistoryUnit({
    this.brandCode = '',
    this.brandName = '',
    this.typeCode = '',
    this.typeName = '',
    this.modelCode = '',
    this.modelName = '',
    this.colourCode = '',
    this.colourName = '',
    this.activityCode = '',
    this.activityName = '',
    this.qty = '1',
    this.provinceCode = '',
    this.cityCode = '',
    this.districtCode = '',
    this.subActivityCode = '',
    this.actNumber = '',
    this.fleetType = '',
    this.fleetCode = '',
  });

  Map<String, dynamic> toMap() => {
    'BrandCode': brandCode,
    'BrandName': brandName,
    'TypeCode': typeCode,
    'TypeName': typeName,
    'ModelCode': modelCode,
    'ModelName': modelName,
    'ColourCode': colourCode,
    'ColourName': colourName,
    'ActivityCode': activityCode,
    'ActivityName': activityName,
    'Qty': qty,
    'ProvinceCode': provinceCode,
    'CityCode': cityCode,
    'DistrictCode': districtCode,
    'SubActivityCode': subActivityCode,
    'ACTNumber': actNumber,
    'FleetType': fleetType,
    'FleetCode': fleetCode,
  };

  factory HistoryUnit.fromMap(Map<String, dynamic> map) => HistoryUnit(
    brandCode: map['BrandCode']?.toString() ?? '',
    brandName: map['BrandName']?.toString() ?? '',
    typeCode: map['TypeCode']?.toString() ?? '',
    typeName: map['TypeName']?.toString() ?? '',
    modelCode: map['ModelCode']?.toString() ?? '',
    modelName: map['ModelName']?.toString() ?? '',
    colourCode: map['ColourCode']?.toString() ?? '',
    colourName: map['ColourName']?.toString() ?? '',
    activityCode: map['ActivityCode']?.toString() ?? '',
    activityName: map['ActivityName']?.toString() ?? '',
    qty: (map['Qty']?.toString().trim().isNotEmpty ?? false)
        ? map['Qty'].toString().trim()
        : '1',
    provinceCode: map['ProvinceCode']?.toString() ?? '',
    cityCode: map['CityCode']?.toString() ?? '',
    districtCode: map['DistrictCode']?.toString() ?? '',
    subActivityCode: map['SubActivityCode']?.toString() ?? '',
    actNumber: map['ACTNumber']?.toString() ?? '',
    fleetType: map['FleetType']?.toString() ?? '',
    fleetCode: map['FleetCode']?.toString() ?? '',
  );
}
