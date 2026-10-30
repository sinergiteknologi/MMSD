import 'package:flutter/material.dart';

import '../models/data_pref.dart';
import '../services/api_service.dart';
import '../services/pref_service.dart';
import '../utils/safe_notifier.dart';
import '../utils/xml_parser.dart';

class ProspectProvider with ChangeNotifier, SafeNotifier {
  ProspectProvider({required this._apiService, PrefService? prefService})
    : _prefService = prefService ?? PrefService();

  final ApiService _apiService;
  final PrefService _prefService;

  bool _isLoading = false;
  String _errorMessage = '';
  String _lastApiDetail = '';
  List<Map<String, String>> _rows = [];

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get lastApiDetail => _lastApiDetail;
  List<Map<String, String>> get rows => _rows;

  Future<void> _ensureConfigured() async {
    final server = await _prefService.getString(PrefService.keyServer);
    final bisnis = await _prefService.getString(PrefService.keyBisnis);
    if (server.isNotEmpty && bisnis.isNotEmpty) {
      _apiService.configure(server: server, bisnis: bisnis);
    }
  }

  Future<List<Map<String, String>>> _loadPref(
    Future<String?> Function() request, {
    int maxPref = 15,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifySafely();
    await _ensureConfigured();
    try {
      final xml = await request();
      if (xml == null) {
        _rows = [];
        _errorMessage = 'Failed to getting data';
        final fail = _apiService.lastFailure;
        _lastApiDetail =
            '${_apiService.lastErrorMessage}${fail?.statusCode != null ? ' (HTTP ${fail!.statusCode})' : ''}';
        // ignore: avoid_print
        print('[HP-CITY] _loadPref xml=null maxPref=$maxPref detail=$_lastApiDetail');
      } else {
        // ignore: avoid_print
        print('[HP-CITY] _loadPref raw len=${xml.length} head=${xml.length > 400 ? xml.substring(0, 400) : xml}');
        _rows = XmlParser.parseDataPref(
          xml,
          maxPref: maxPref,
        ).toRows(maxPref: maxPref);
        _lastApiDetail = '';
        // ignore: avoid_print
        print('[HP-CITY] _loadPref parsed rows=${_rows.length} first=${_rows.isEmpty ? {} : _rows.first}');
      }
    } catch (e, st) {
      _rows = [];
      _errorMessage = 'Failed to getting data';
      _lastApiDetail = e.toString();
      // ignore: avoid_print
      print('[HP-CITY] _loadPref EXCEPTION $e\n$st');
    }
    _isLoading = false;
    notifySafely();
    return _rows;
  }

  Future<List<Map<String, String>>> findProspect({
    required String filterTlp,
    required String filterId,
    required String user,
  }) {
    return _loadPref(
      () => _apiService.getFindProspect(
        filterTlp: filterTlp,
        filterId: filterId,
        user: user,
      ),
      maxPref: 7,
    );
  }

  Future<List<Map<String, String>>> findProspect2({
    required String filterTlp,
    required String filterId,
    required String user,
    String historyId = '',
    bool forSpk = false,
  }) {
    return _loadPref(
      () => _apiService.getFindProspect2(
        filterTlp: filterTlp,
        filterId: filterId,
        user: user,
        historyId: historyId,
        forSpk: forSpk,
      ),
      maxPref: 19,
    );
  }

  Future<List<Map<String, String>>> findProspectFGOC({
    required String idNo,
    required String historyIdNo,
    required String user,
  }) {
    return _loadPref(
      () => _apiService.getFindProspectFGOC(
        idNo: idNo,
        historyIdNo: historyIdNo,
        user: user,
      ),
      maxPref: 7,
    );
  }

  Future<List<Map<String, String>>> getHistory({
    required String kodeCabang,
    required String idNo,
    required String userCreated,
    required String userGroup,
    required String date1,
    required String date2,
    required String status,
  }) {
    return _loadPref(
      () => _apiService.getDataHistory(
        kodeCabang: kodeCabang,
        idNo: idNo,
        userCreated: userCreated,
        userGroup: userGroup,
        date1: date1,
        date2: date2,
        status: status,
      ),
      maxPref: 12,
    );
  }

  Future<List<Map<String, String>>> getHistoryType({
    required String kodeCabang,
    required String idNo,
    required String userCreated,
    required String userGroup,
    required String date1,
    required String date2,
    required String status,
    required String type,
  }) {
    return _loadPref(
      () => _apiService.getDataHistoryType(
        kodeCabang: kodeCabang,
        idNo: idNo,
        userCreated: userCreated,
        userGroup: userGroup,
        date1: date1,
        date2: date2,
        status: status,
        type: type,
      ),
      maxPref: 12,
    );
  }

  Future<DataPref?> getHistoryEdit({
    required String kodeCabang,
    required String idNo,
    required String historyId,
    required String userCreated,
  }) async {
    await _ensureConfigured();
    final xml = await _apiService.getDataHistoryEdit(
      kodeCabang: kodeCabang,
      idNo: idNo,
      historyId: historyId,
      userCreated: userCreated,
    );
    if (xml == null) return null;
    return XmlParser.parseDataPref(xml, maxPref: 14);
  }

  Future<bool> checkPhone({required String tlp, required String user}) async {
    await _ensureConfigured();
    final xml = await _apiService.getExistPhoneNumber(tlp: tlp, user: user);
    return xml != null && XmlParser.parseStatus(xml);
  }

  Future<bool> checkPhoneFGOC({
    required String tlp,
    required String user,
  }) async {
    await _ensureConfigured();
    final xml = await _apiService.getExistPhoneNumberFGOC(tlp: tlp, user: user);
    return xml != null && XmlParser.parseStatus(xml);
  }

  Future<bool> uploadNewData4(Map<String, String> data) async {
    await _ensureConfigured();
    final xml = await _apiService.uploadNewData4(data);
    return xml != null && XmlParser.parseStatus(xml);
  }

  Future<bool> uploadNewData3(Map<String, String> data) async {
    await _ensureConfigured();
    final xml = await _apiService.uploadNewData3(data);
    return xml != null && XmlParser.parseStatus(xml);
  }

  Future<bool> uploadStatus(Map<String, String> data) async {
    await _ensureConfigured();
    final xml = await _apiService.uploadStatus(data);
    return xml != null && XmlParser.parseStatus(xml);
  }

  Future<bool> uploadStatusHP(Map<String, String> data) async {
    await _ensureConfigured();
    final xml = await _apiService.uploadStatusHP(data);
    return xml != null && XmlParser.parseStatus(xml);
  }

  Future<List<Map<String, String>>> getCustomer({
    required String branchCode,
    required String idNo,
  }) {
    return _loadPref(
      () => _apiService.getDataCustomer(branchCode: branchCode, idNo: idNo),
      maxPref: 10,
    );
  }
}
