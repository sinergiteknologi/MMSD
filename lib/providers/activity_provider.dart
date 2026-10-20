import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/pref_service.dart';
import '../utils/safe_notifier.dart';
import '../utils/xml_parser.dart';

class ActivityProvider with ChangeNotifier, SafeNotifier {
  ActivityProvider({
    required this._apiService,
    PrefService? prefService,
    DatabaseService? databaseService,
  }) : _prefService = prefService ?? PrefService(),
       _dbService = databaseService ?? DatabaseService();

  final ApiService _apiService;
  final PrefService _prefService;
  final DatabaseService _dbService;

  bool _isLoading = false;
  List<Map<String, String>> _rows = [];

  bool get isLoading => _isLoading;
  List<Map<String, String>> get rows => _rows;

  Future<void> _ensureConfigured() async {
    final server = await _prefService.getString(PrefService.keyServer);
    final bisnis = await _prefService.getString(PrefService.keyBisnis);
    if (server.isNotEmpty && bisnis.isNotEmpty) {
      _apiService.configure(server: server, bisnis: bisnis);
    }
  }

  Future<List<Map<String, String>>> getTranAct({
    required String date,
    required String branchCode,
    required String activityCode,
    required String subCode,
    required String provinceCode,
    required String cityCode,
    required String districtCode,
  }) async {
    _isLoading = true;
    notifySafely();
    await _ensureConfigured();
    final xml = await _apiService.getTranAct(
      date: date,
      branchCode: branchCode,
      activityCode: activityCode,
      subCode: subCode,
      provinceCode: provinceCode,
      cityCode: cityCode,
      districtCode: districtCode,
    );
    _rows = xml == null
        ? []
        : XmlParser.parseDataPref(xml, maxPref: 7).toRows(maxPref: 7);
    if (xml != null) {
      await _dbService.clearTable('T_TRANACT');
      await _dbService.insertBatch(
        'T_TRANACT',
        _rows
            .map(
              (row) => {
                'ACTNumber': row['Pref1'] ?? '',
                'ACTName': row['Pref2'] ?? '',
                'ActivityCode': activityCode,
                'SubActivityCode': subCode,
                'ProvinceCode': provinceCode,
                'CityCode': cityCode,
                'DistrictCode': districtCode,
              },
            )
            .toList(),
      );
    }
    _isLoading = false;
    notifySafely();
    return _rows;
  }

  Future<bool> uploadTranAct({
    required String kodeCabang,
    required String activity,
    required String subActivity,
    required String tranAct,
    required String date1,
    required String date2,
    required String desc,
    required String cost,
    required String actNumber,
    required String userNam,
  }) async {
    await _ensureConfigured();
    final xml = await _apiService.uploadTranAct(
      kodeCabang: kodeCabang,
      activity: activity,
      subActivity: subActivity,
      tranAct: tranAct,
      date1: date1,
      date2: date2,
      desc: desc,
      cost: cost,
      actNumber: actNumber,
      userNam: userNam,
    );
    return xml != null && XmlParser.parseStatus(xml);
  }

  Future<List<Map<String, String>>> getFUProspect({
    required String date1,
    required String date2,
    required String userGroup,
  }) async {
    await _ensureConfigured();
    final xml = await _apiService.getFUProspect(
      date1: date1,
      date2: date2,
      userGroup: userGroup,
    );
    return xml == null
        ? []
        : XmlParser.parseDataPref(xml, maxPref: 7).toRows(maxPref: 7);
  }
}
