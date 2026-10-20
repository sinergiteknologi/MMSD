import 'history_row.dart';

class HotProspectPayload {
  const HotProspectPayload({
    required this.row,
    required this.hpDate,
    required this.hpDesc,
    this.name = '',
    this.address = '',
    this.phone2 = '',
    this.birthDate = '',
    this.religion = '',
    this.top = '',
    this.pic = '',
    this.lobCode = '',
    this.provinceCode = '',
    this.cityCode = '',
    this.districtCode = '',
  });

  final HistoryRow row;
  final String hpDate;
  final String hpDesc;
  final String name;
  final String address;
  final String phone2;
  final String birthDate;
  final String religion;
  final String top;
  final String pic;
  final String lobCode;
  final String provinceCode;
  final String cityCode;
  final String districtCode;

  bool get isPersonal => row.idNo.isNotEmpty && row.idNo.startsWith('1');
}
