import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/pref_service.dart';
import '../utils/safe_notifier.dart';
import '../utils/xml_parser.dart';

class SpkProvider with ChangeNotifier, SafeNotifier {
  SpkProvider({required this._apiService, PrefService? prefService})
    : _prefService = prefService ?? PrefService();

  final ApiService _apiService;
  final PrefService _prefService;

  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, String>> _rows = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<Map<String, String>> get rows => _rows;

  Future<void> _ensureConfigured() async {
    final server = await _prefService.getString(PrefService.keyServer);
    final bisnis = await _prefService.getString(PrefService.keyBisnis);
    if (server.isNotEmpty && bisnis.isNotEmpty) {
      _apiService.configure(server: server, bisnis: bisnis);
    }
  }

  Future<List<Map<String, String>>> getHistorySPK({
    required String kodeCabang,
    required String idNo,
    required String userCreated,
    required String userGroup,
    required String date1,
    required String date2,
    required String status,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifySafely();
    await _ensureConfigured();
    final xml = await _apiService.getDataHistorySPK(
      kodeCabang: kodeCabang,
      idNo: idNo,
      userCreated: userCreated,
      userGroup: userGroup,
      date1: date1,
      date2: date2,
      status: status,
    );
    _rows = xml == null
        ? []
        : XmlParser.parseDataPref(xml, maxPref: 12).toRows(maxPref: 12);
    if (xml == null) _errorMessage = 'Failed to getting data';
    _isLoading = false;
    notifySafely();
    return _rows;
  }

  Future<List<Map<String, String>>> getCustomerSPK({
    required String branchCode,
    required String idNo,
    required String historyNo,
    required String spkNo,
  }) async {
    await _ensureConfigured();
    final xml = await _apiService.getDataCustomerSPK(
      branchCode: branchCode,
      idNo: idNo,
      historyNo: historyNo,
      spkNo: spkNo,
    );
    return xml == null
        ? []
        : XmlParser.parseDataPref(xml, maxPref: 18).toRows(maxPref: 18);
  }

  Future<List<Map<String, String>>> getSPKIndent({
    required String branchCode,
    required String spkNo,
  }) async {
    await _ensureConfigured();
    final xml = await _apiService.getDataSPKIndent(
      branchCode: branchCode,
      spkNo: spkNo,
    );
    return xml == null
        ? []
        : XmlParser.parseDataPref(xml, maxPref: 55).toRows(maxPref: 55);
  }

  Future<bool> createSPK(Map<String, String> data) async {
    _isLoading = true;
    _errorMessage = '';
    notifySafely();
    await _ensureConfigured();
    final xml = await _apiService.uploadCreateSPK(data);
    final success = xml != null && XmlParser.parseStatus(xml);
    if (!success) {
      _errorMessage = _apiService.lastErrorMessage;
    }
    _isLoading = false;
    notifySafely();
    return success;
  }
}
