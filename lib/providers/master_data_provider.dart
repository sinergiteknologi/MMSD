import 'package:flutter/material.dart';

import '../models/code_name.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/pref_service.dart';
import '../utils/xml_parser.dart';

class MasterDataProvider with ChangeNotifier {
  MasterDataProvider({
    required this._apiService,
    PrefService? prefService,
    DatabaseService? databaseService,
  }) : _prefService = prefService ?? PrefService(),
       _dbService = databaseService ?? DatabaseService();

  final ApiService _apiService;
  final PrefService _prefService;
  final DatabaseService _dbService;

  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String _syncMessage = '';
  String _syncError = '';

  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String get syncMessage => _syncMessage;
  String get syncError => _syncError;

  Future<void> configureFromPrefs() async {
    final server = await _prefService.getString(PrefService.keyServer);
    final bisnis = await _prefService.getString(PrefService.keyBisnis);
    if (server.isNotEmpty && bisnis.isNotEmpty) {
      _apiService.configure(server: server, bisnis: bisnis);
    }
  }

  Future<bool> syncAllMasterData() async {
    _isSyncing = true;
    _syncProgress = 0.0;
    _syncMessage = 'Menghubungkan ke server';
    _syncError = '';
    notifyListeners();

    try {
      await configureFromPrefs();
      var completed = 0;
      Future<List<Map<String, dynamic>>> tracked(
        String label,
        Future<List<Map<String, dynamic>>> future,
      ) async {
        final rows = await future;
        completed++;
        _setProgress(0.08 + completed * 0.11, label);
        return rows;
      }

      _setProgress(0.08, 'Mengunduh Brand');
      final rows = await Future.wait([
        tracked(
          'Mengunduh Brand',
          _fetchCodeName(
            fetch: _apiService.getBrand,
            codeKey: 'BrandCode',
            nameKey: 'BrandName',
          ),
        ),
        tracked(
          'Mengunduh Type',
          _fetchCodeName(
            fetch: _apiService.getType,
            codeKey: 'TypeCode',
            nameKey: 'TypeName',
          ),
        ),
        tracked(
          'Mengunduh Color',
          _fetchCodeName(
            fetch: _apiService.getColor,
            codeKey: 'ColorCode',
            nameKey: 'ColorName',
          ),
        ),
        tracked('Mengunduh Model', _fetchModels()),
        tracked(
          'Mengunduh Activity',
          _fetchCodeName(
            fetch: () => _apiService.getDataActivity(),
            codeKey: 'ActivityCode',
            nameKey: 'ActivityName',
          ),
        ),
        tracked('Mengunduh Sub Activity', _fetchSubActivity()),
        tracked('Mengunduh City', _fetchCity()),
        tracked('Mengunduh District', _fetchDistrict()),
      ]);

      _setProgress(0.96, 'Menyimpan data');
      await _dbService.replaceTablesAtomically({
        'M_BRAND': rows[0],
        'M_TYPE': rows[1],
        'M_COLOR': rows[2],
        'M_MODEL': rows[3],
        'M_ACTIVITY': rows[4],
        'M_SUBACTIVITY': rows[5],
        'M_CITY': rows[6],
        'M_DISTRICT': rows[7],
      });
      _setProgress(1.0, 'Data siap');
      return true;
    } catch (error) {
      _syncError = error.toString().replaceFirst('Bad state: ', '');
      _syncMessage = 'Sync failed';
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void _setProgress(double value, String message) {
    _syncProgress = value;
    _syncMessage = message;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _fetchCodeName({
    required Future<String?> Function() fetch,
    required String codeKey,
    required String nameKey,
  }) async {
    final xml = await fetch();
    if (xml == null) throw StateError(_apiService.lastErrorMessage);
    final items = XmlParser.parseCodeName(xml);
    if (items.isEmpty) throw StateError('Master data kosong.');
    return items
        .map<Map<String, dynamic>>(
          (item) => {codeKey: item.code, nameKey: item.name},
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchModels() async {
    final xml = await _apiService.getModel();
    if (xml == null) throw StateError(_apiService.lastErrorMessage);
    final rows = XmlParser.parseDataPref(xml, maxPref: 4).toRows(maxPref: 4);
    if (rows.isEmpty) throw StateError('Master model kosong.');
    return rows
        .map<Map<String, dynamic>>(
          (row) => {
            'BrandCode': row['Pref1'] ?? '',
            'TypeCode': row['Pref2'] ?? '',
            'ModelCode': row['Pref3'] ?? '',
            'ModelName': row['Pref4'] ?? '',
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchSubActivity() async {
    final xml = await _apiService.getDataSubActivity();
    if (xml == null) throw StateError(_apiService.lastErrorMessage);
    final rows = XmlParser.parseDataPref(xml, maxPref: 3).toRows(maxPref: 3);
    if (rows.isEmpty) throw StateError('Master sub activity kosong.');
    return rows
        .map<Map<String, dynamic>>(
          (row) => {
            'ActivityCode': row['Pref1'] ?? '',
            'SubActivityCode': row['Pref2'] ?? '',
            'SubActivityName': row['Pref3'] ?? '',
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchCity() async {
    final xml = await _apiService.getCity();
    if (xml == null) throw StateError(_apiService.lastErrorMessage);
    final rows = XmlParser.parseDataPref(xml, maxPref: 3).toRows(maxPref: 3);
    if (rows.isEmpty) throw StateError('Master city kosong.');
    return rows
        .map<Map<String, dynamic>>(
          (row) => {
            'ProvinceCode': row['Pref1'] ?? '',
            'CityCode': row['Pref2'] ?? '',
            'CityName': row['Pref3'] ?? '',
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchDistrict() async {
    final xml = await _apiService.getDistrict();
    if (xml == null) throw StateError(_apiService.lastErrorMessage);
    final rows = XmlParser.parseDataPref(xml, maxPref: 4).toRows(maxPref: 4);
    if (rows.isEmpty) throw StateError('Master district kosong.');
    return rows
        .map<Map<String, dynamic>>(
          (row) => {
            'ProvinceCode': row['Pref1'] ?? '',
            'CityCode': row['Pref2'] ?? '',
            'DistrictCode': row['Pref3'] ?? '',
            'DistrictName': row['Pref4'] ?? '',
          },
        )
        .toList();
  }

  Future<List<CodeName>> searchLocal(
    String table, {
    required String codeKey,
    required String nameKey,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final rows = await _dbService.queryTable(
      table,
      where: where,
      whereArgs: whereArgs,
    );
    return rows
        .map(
          (row) => CodeName(
            code: row[codeKey]?.toString() ?? '',
            name: row[nameKey]?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<List<CodeName>> getBrands() =>
      searchLocal('M_BRAND', codeKey: 'BrandCode', nameKey: 'BrandName');

  Future<List<CodeName>> getTypes() =>
      searchLocal('M_TYPE', codeKey: 'TypeCode', nameKey: 'TypeName');

  Future<List<CodeName>> getColors() =>
      searchLocal('M_COLOR', codeKey: 'ColorCode', nameKey: 'ColorName');

  Future<List<CodeName>> getActivities() => searchLocal(
    'M_ACTIVITY',
    codeKey: 'ActivityCode',
    nameKey: 'ActivityName',
  );

  Future<List<CodeName>> getModels({
    required String brandCode,
    required String typeCode,
  }) {
    return searchLocal(
      'M_MODEL',
      codeKey: 'ModelCode',
      nameKey: 'ModelName',
      where: 'BrandCode = ? AND TypeCode = ?',
      whereArgs: [brandCode, typeCode],
    );
  }

  Future<List<CodeName>> getSubActivities(String activityCode) {
    return searchLocal(
      'M_SUBACTIVITY',
      codeKey: 'SubActivityCode',
      nameKey: 'SubActivityName',
      where: 'ActivityCode = ?',
      whereArgs: [activityCode],
    );
  }

  Future<List<CityItem>> getCities() async {
    final rows = await _dbService.queryTable('M_CITY', orderBy: 'CityName');
    return rows
        .map(
          (row) => CityItem(
            provinceCode: row['ProvinceCode']?.toString() ?? '',
            cityCode: row['CityCode']?.toString() ?? '',
            cityName: row['CityName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<List<DistrictItem>> getDistricts({
    required String provinceCode,
    required String cityCode,
  }) async {
    final rows = await _dbService.queryTable(
      'M_DISTRICT',
      where: 'ProvinceCode = ? AND CityCode = ?',
      whereArgs: [provinceCode, cityCode],
      orderBy: 'DistrictName',
    );
    return rows
        .map(
          (row) => DistrictItem(
            provinceCode: row['ProvinceCode']?.toString() ?? '',
            cityCode: row['CityCode']?.toString() ?? '',
            districtCode: row['DistrictCode']?.toString() ?? '',
            districtName: row['DistrictName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<List<CodeName>> getFactors() async {
    await configureFromPrefs();
    final xml = await _apiService.getDataFactor();
    if (xml == null) return [];
    return XmlParser.parseCodeName(xml);
  }

  Future<List<CodeName>> getFleet() async {
    final xml = await _apiService.getDataFleet();
    if (xml == null) return [];
    final items = XmlParser.parseCodeName(xml);
    await _dbService.clearTable('M_FLEET');
    await _dbService.insertBatch(
      'M_FLEET',
      items
          .map((item) => {'FleetCode': item.code, 'FleetName': item.name})
          .toList(),
    );
    return items;
  }

  Future<List<CodeName>> getLOB() async {
    await configureFromPrefs();
    final xml = await _apiService.getDataLOB();
    if (xml == null) return [];
    return XmlParser.parseCodeName(xml);
  }

  Future<List<CodeName>> getTOP() async {
    final xml = await _apiService.getTOP();
    if (xml == null) return [];
    final items = XmlParser.parseCodeName(xml);
    await _dbService.clearTable('M_TOP');
    await _dbService.insertBatch(
      'M_TOP',
      items
          .map((item) => {'TOPCode': item.code, 'TOPName': item.name})
          .toList(),
    );
    return items;
  }

  Future<List<Map<String, String>>> searchCity(String like) async {
    final xml = await _apiService.getCity(like);
    if (xml == null) return [];
    return XmlParser.parseDataPref(xml).toRows(maxPref: 3);
  }

  Future<List<Map<String, String>>> searchDistrict(String like) async {
    final xml = await _apiService.getDistrict(like);
    if (xml == null) return [];
    return XmlParser.parseDataPref(xml).toRows(maxPref: 4);
  }

  Future<List<Map<String, String>>> searchFGOC({
    required String branchCode,
    String like = '',
  }) async {
    final xml = await _apiService.getFGOC(branchCode: branchCode, like: like);
    if (xml == null) return [];
    return XmlParser.parseDataPref(xml).toRows(maxPref: 6);
  }

  Future<List<Map<String, String>>> getFGOCContact({
    required String branchCode,
    required String custCode,
  }) async {
    final xml = await _apiService.getFGOCContect(
      branchCode: branchCode,
      custCode: custCode,
    );
    if (xml == null) return [];
    return XmlParser.parseDataPref(xml).toRows(maxPref: 6);
  }
}
