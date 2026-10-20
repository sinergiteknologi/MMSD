import 'package:flutter/material.dart';

import '../models/report_models.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/pref_service.dart';
import '../utils/safe_notifier.dart';
import '../utils/xml_parser.dart';

class ReportProvider with ChangeNotifier, SafeNotifier {
  ReportProvider({required this._apiService, PrefService? prefService})
    : _prefService = prefService ?? PrefService();

  final ApiService _apiService;
  final PrefService _prefService;

  bool _isLoading = false;
  String _errorMessage = '';
  List<Map<String, String>> _rows = [];
  ReportDaily? _daily;
  ReportActivity? _activity;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<Map<String, String>> get rows => _rows;
  ReportDaily? get daily => _daily;
  ReportActivity? get activity => _activity;

  Future<void> _ensureConfigured() async {
    final server = await _prefService.getString(PrefService.keyServer);
    final bisnis = await _prefService.getString(PrefService.keyBisnis);
    if (server.isNotEmpty && bisnis.isNotEmpty) {
      _apiService.configure(server: server, bisnis: bisnis);
    }
  }

  Future<List<Map<String, String>>> _load(
    Future<String?> Function() request, {
    int maxPref = 21,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifySafely();
    await _ensureConfigured();
    final xml = await request();
    _rows = xml == null
        ? []
        : XmlParser.parseDataPref(
            xml,
            maxPref: maxPref,
          ).toRows(maxPref: maxPref);
    if (xml == null) _errorMessage = _apiService.lastErrorMessage;
    _isLoading = false;
    notifySafely();
    return _rows;
  }

  Future<ReportDaily?> getReportDaily(Map<String, String> data) async {
    _isLoading = true;
    notifySafely();
    await _ensureConfigured();
    final xml = await _apiService.getReportDaily(data);
    _daily = xml == null ? null : XmlParser.parseReportDaily(xml);
    _isLoading = false;
    notifySafely();
    return _daily;
  }

  Future<ReportActivity?> getReportActivity(Map<String, String> data) async {
    _isLoading = true;
    notifySafely();
    await _ensureConfigured();
    final xml = await _apiService.getReportActivity(data);
    _activity = xml == null ? null : XmlParser.parseReportActivity(xml);
    _isLoading = false;
    notifySafely();
    return _activity;
  }

  Future<List<Map<String, String>>> getStatusList({
    required UserModel user,
    required String date1,
    required String date2,
    String status = '',
    String type = '',
  }) {
    return _load(
      () => type.isEmpty || type == 'Sales'
          ? _apiService.getDataHistory(
              kodeCabang: user.historyBranch,
              idNo: '',
              userCreated: user.username,
              userGroup: user.userGroup,
              date1: date1,
              date2: date2,
              status: status,
            )
          : _apiService.getDataHistoryType(
              kodeCabang: user.historyBranch,
              idNo: '',
              userCreated: user.username,
              userGroup: user.userGroup,
              date1: date1,
              date2: date2,
              status: status,
              type: type,
            ),
      maxPref: 12,
    );
  }

  Future<List<Map<String, String>>> getReportDailyRows(
    Map<String, String> data,
  ) async {
    final report = await getReportDaily(data);
    if (report == null) return const [];
    return _expandPipes({
      'User': report.user,
      'Status': report.status,
      ...report.days,
      'Total': report.total,
    });
  }

  Future<List<Map<String, String>>> getReportActivityRows(
    Map<String, String> data,
  ) async {
    final report = await getReportActivity(data);
    if (report == null) return const [];
    return _expandPipes({
      'ActivityName': report.activityName,
      'SubActivityName': report.subActivityName,
      'ACTNumber': report.actNumber,
      'ACTName': report.actName,
      'SPVName': report.spvName,
      'SalesName': report.salesName,
      'StartDate': report.startDate,
      'EndDate': report.endDate,
      'CityName': report.cityName,
      'DistrictName': report.districtName,
      'TotalProspect': report.totalProspect,
      'TotalSPK': report.totalSpk,
      'TotalDO': report.totalDo,
    });
  }

  List<Map<String, String>> _expandPipes(Map<String, String> source) {
    var length = 1;
    final split = <String, List<String>>{};
    source.forEach((key, value) {
      final parts = value.split('|');
      split[key] = parts;
      if (parts.length > length) length = parts.length;
    });
    return List.generate(length, (index) {
      final row = <String, String>{};
      split.forEach((key, parts) {
        row[key] = index < parts.length ? parts[index] : '';
      });
      return row;
    });
  }

  Future<List<Map<String, String>>> getReportFleetDetail(
    Map<String, String> data,
  ) => _load(() => _apiService.getReportFleetDetail(data), maxPref: 8);

  Future<List<Map<String, String>>> getReportFleetSummary(
    Map<String, String> data,
  ) => _load(() => _apiService.getReportFleetSummary(data), maxPref: 7);

  Future<List<Map<String, String>>> getReportActivityRecap(
    Map<String, String> data,
  ) => _load(() => _apiService.getReportActivityRecap(data), maxPref: 10);

  Future<List<Map<String, String>>> getReportKPI(Map<String, String> data) =>
      _load(() => _apiService.getReportKPI(data), maxPref: 12);

  Future<List<Map<String, String>>> getCustomerReport({
    required String branchCode,
    required String user,
    required String date1,
    required String date2,
    required String reportType,
    required String filter,
  }) {
    return _load(
      () => _apiService.getCustomerReport(
        branchCode: branchCode,
        user: user,
        date1: date1,
        date2: date2,
        reportType: reportType,
        filter: filter,
      ),
      maxPref: 16,
    );
  }

  Future<List<Map<String, String>>> getIncentiveReport({
    required String branchCode,
    required String user,
    required String date1,
    required String date2,
    required String reportType,
  }) {
    return _load(
      () => _apiService.getIncentiveReport(
        branchCode: branchCode,
        user: user,
        date1: date1,
        date2: date2,
        reportType: reportType,
      ),
    );
  }

  Future<List<Map<String, String>>> getIncentiveSPVReport({
    required String branchCode,
    required String user,
    required String date1,
    required String date2,
    required String reportType,
  }) {
    return _load(
      () => _apiService.getIncentiveSPVReport(
        branchCode: branchCode,
        user: user,
        date1: date1,
        date2: date2,
        reportType: reportType,
      ),
      maxPref: 9,
    );
  }

  Future<List<Map<String, String>>> getDailySales({
    required String branchCode,
    required String date,
  }) {
    return _load(
      () => _apiService.getReportDailySales(branchCode: branchCode, date: date),
      maxPref: 11,
    );
  }

  Future<List<Map<String, String>>> getWeeklySales({
    required String branchCode,
    required String date,
  }) {
    return _load(
      () =>
          _apiService.getReportWeeklySales(branchCode: branchCode, date: date),
      maxPref: 19,
    );
  }

  Future<List<Map<String, String>>> getMonthlyActivity({
    required String branchCode,
    required String date,
  }) {
    return _load(
      () => _apiService.getReportMonthLyActivity(
        branchCode: branchCode,
        date: date,
      ),
      maxPref: 11,
    );
  }

  Future<List<Map<String, String>>> getMonthlyFGOC({
    required String branchCode,
    required String username,
    required String date,
  }) {
    return _load(
      () => _apiService.getReportMonthLyFGOC(
        branchCode: branchCode,
        username: username,
        date: date,
      ),
      maxPref: 12,
    );
  }

  Future<List<Map<String, String>>> getMonthlySumSPV({
    required String branchCode,
    required String date,
  }) {
    return _load(
      () => _apiService.getReportMonthlySumSPV(
        branchCode: branchCode,
        date: date,
      ),
      maxPref: 7,
    );
  }

  Future<List<Map<String, String>>> getDailySalesDetail({
    required String branchCode,
    required String user,
    required String date1,
  }) {
    return _load(
      () => _apiService.getReportDailySalesDetail(
        branchCode: branchCode,
        user: user,
        date1: date1,
      ),
      maxPref: 16,
    );
  }

  Future<List<Map<String, String>>> getMonthlySumBM({
    required String branchCode,
    required String date,
  }) {
    return _load(
      () =>
          _apiService.getReportMonthlySumBM(branchCode: branchCode, date: date),
      maxPref: 9,
    );
  }

  Future<List<Map<String, String>>> getMonthlySumGM({
    required String branchCode,
    required String date,
    required String user,
    required String userStatus,
  }) {
    return _load(
      () => _apiService.getReportMonthlySumGM(
        branchCode: branchCode,
        date: date,
        user: user,
        userStatus: userStatus,
      ),
      maxPref: 6,
    );
  }

  Future<List<Map<String, String>>> getDailySalesGM({
    required String branchCode,
    required String date,
    required String user,
    required String userStatus,
  }) {
    return _load(
      () => _apiService.getReportDailySalesGM(
        branchCode: branchCode,
        date: date,
        user: user,
        userStatus: userStatus,
      ),
      maxPref: 10,
    );
  }

  Future<List<Map<String, String>>> getDailySalesGM2({
    required String branchCode,
    required String date,
    required String user,
    required String userStatus,
  }) {
    return _load(
      () => _apiService.getReportDailySalesGM2(
        branchCode: branchCode,
        date: date,
        user: user,
        userStatus: userStatus,
      ),
      maxPref: 11,
    );
  }
}
