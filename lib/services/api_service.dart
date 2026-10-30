import '../utils/app_config.dart';
import 'rest_client.dart';

class ApiService {
  ApiService({RestClient? client}) : _client = client ?? RestClient();

  final RestClient _client;
  String _bisnis = '';

  void configure({required String server, required String bisnis}) {
    _bisnis = bisnis;
    _client.baseUrl = AppConfig.serviceUrl(server);
  }
  
  void updateBaseUrl(String url) {
    _client.baseUrl = AppConfig.serviceUrl(url);
  }

  String get bisnis => _bisnis;
  RestFailure? get lastFailure => _client.lastFailure;
  String get lastErrorMessage =>
      _client.lastFailure?.message ?? 'Layanan tidak memberikan respons.';

  static const Map<String, String> _mobileDbConfig = {
    'DB_SERVER': AppConfig.dbServer,
    'DB_NAME': AppConfig.dbName,
    'GETUSER_URL': AppConfig.getUserUrl,
  };

  Future<String?> _call(String method, [Map<String, String>? params]) {
    return _client.postJson(
      methodName: method,
      body: {..._mobileDbConfig, ...?params},
    );
  }

  Future<String?> _callAtUrl(
    String url,
    String method, [
    Map<String, String>? params,
  ]) {
    return _client.postJson(
      methodName: method,
      body: {..._mobileDbConfig, ...?params},
      requestUrl: url,
    );
  }

  Future<String?> _callWithBisnis(
    String method, [
    Map<String, String?>? params,
  ]) {
    return _call(method, {
      'sBisnis': _bisnis,
      if (params != null)
        for (final entry in params.entries) entry.key: entry.value ?? '',
    });
  }

  Future<String?> getVersi() {
    return _callAtUrl(AppConfig.defaultServiceUrl(), 'Versi');
  }

  Future<String?> getBisnis() {
    return _callAtUrl(AppConfig.defaultServiceUrl(), 'GetDataBisnis');
  }

  Future<String?> login({
    required String sCabang,
    required String sUser,
    required String sPwd,
  }) {
    
    return _callWithBisnis('Login', {
      'sCabang': sCabang,
      'sUser': sUser,
      'sPwd': sPwd,
    });
  }

  Future<String?> getFindProspect({
    required String filterTlp,
    required String filterId,
    required String user,
  }) {
    return _callWithBisnis('GetFindProspect', {
      'prmFilter': filterTlp,
      'prmFilter2': filterId,
      'prmUser': user,
    });
  }

  Future<String?> getFindProspect2({
    required String filterTlp,
    required String filterId,
    required String user,
    String historyId = '',
    bool forSpk = false,
  }) {
    return _callWithBisnis('GetFindProspect2', {
      'prmFilter': filterTlp,
      'prmFilter2': filterId,
      'prmUser': user,
      'prmHistoryID': historyId,
      if (forSpk) 'prmSPK': '1',
    });
  }

  Future<String?> getFindProspectFGOC({
    required String idNo,
    required String historyIdNo,
    required String user,
  }) {
    return _callWithBisnis('GetFindProspectFGOC', {
      'prmIDNo': idNo,
      'prmHistoryIdNo': historyIdNo,
      'prmUser': user,
    });
  }

  Future<String?> getTOP() => _callWithBisnis('GetDataTOP');

  Future<String?> getCustFindBy() => _callWithBisnis('GetDataCustFindBy');

  Future<String?> getBrand() => _callWithBisnis('GetDataBrand');

  Future<String?> getType() => _callWithBisnis('GetDataType');

  Future<String?> getModel({
    String brand = '',
    String type = '',
    String model = '',
  }) {
    return _callWithBisnis('GetDataModel', {
      'prmBrand': brand,
      'prmType': type,
      'prmModel': model,
    });
  }

  Future<String?> getColor() => _callWithBisnis('GetDataColor');

  Future<String?> getDataActivity([String like = '']) {
    return _callWithBisnis('GetDataActivity', {'prmLike': like});
  }

  Future<String?> getDataSubActivity({String activity = '', String like = ''}) {
    return _callWithBisnis('GetDataSubActivity', {
      'prmActivity': activity,
      'prmLike': like,
    });
  }

  Future<String?> getTranAct({
    required String date,
    required String branchCode,
    required String activityCode,
    required String subCode,
    required String provinceCode,
    required String cityCode,
    required String districtCode,
  }) {
    return _callWithBisnis('GetDataTranAct', {
      'prmDate': date,
      'prmMBranchCode': branchCode,
      'prmActivityCode': activityCode,
      'prmSubCode': subCode,
      'prmProvinceCode': provinceCode,
      'prmCityCode': cityCode,
      'prmDistrictCode': districtCode,
    });
  }

  Future<String?> getDataFactor() => _callWithBisnis('GetDataFactor');

  Future<String?> getDataFleet() => _callWithBisnis('GetDataFleet');

  Future<String?> getDataLOB() => _callWithBisnis('GetDataLOB');

  Future<String?> getDataCustomer({
    required String branchCode,
    required String idNo,
  }) {
    return _callWithBisnis('GetDataCustomer', {
      'prmBranchCode': branchCode,
      'prmIDNo': idNo,
    });
  }

  Future<String?> getDataCustomerSPK({
    required String branchCode,
    required String idNo,
    required String historyNo,
    required String spkNo,
  }) {
    return _callWithBisnis('GetDataCustomerSPK', {
      'prmBranchCode': branchCode,
      'prmIDNo': idNo,
      'prmHistoryNo': historyNo,
      'prmSPKNo': spkNo,
    });
  }

  Future<String?> getExistPhoneNumber({
    required String tlp,
    required String user,
  }) {
    return _callWithBisnis('GetExistPhoneNumber', {
      'prmTlp': tlp,
      'prmUser': user,
    });
  }

  Future<String?> getExistPhoneNumberFGOC({
    required String tlp,
    required String user,
  }) {
    return _callWithBisnis('GetExistPhoneNumberFGOC', {
      'prmTlp': tlp,
      'prmUser': user,
    });
  }

  Future<String?> uploadNewData(Map<String, String?> data) {
    return _callWithBisnis('UploadNewData', data);
  }

  Future<String?> uploadNewData2(Map<String, String?> data) {
    return _callWithBisnis('UploadNewData2', data);
  }

  Future<String?> uploadNewData3(Map<String, String?> data) {
    return _callWithBisnis('UploadNewData3', data);
  }

  Future<String?> uploadNewData4(Map<String, String?> data) {
    return _callWithBisnis('UploadNewData4', data);
  }

  Future<String?> uploadStatus(Map<String, String> data) {
    return _callWithBisnis('UploadStatus', data);
  }

  Future<String?> uploadStatusHP(Map<String, String> data) {
    return _callWithBisnis('UploadStatusHP', data);
  }

  Future<String?> uploadCreateSPK(Map<String, String> data) {
    return _callWithBisnis('UploadCreateSPK2', data);
  }

  Future<String?> uploadNewPassword({
    required String user,
    required String newPassword,
  }) {
    return _callWithBisnis('UploadNewPassword', {
      'prmUser': user,
      'prmNewPassword': newPassword,
    });
  }

  Future<String?> uploadTranAct({
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
  }) {
    return _callWithBisnis('UploadTranAct', {
      'prmKodeCabang': kodeCabang,
      'prmActivity': activity,
      'prmSubActivity': subActivity,
      'prmTranAct': tranAct,
      'prmDate1': date1,
      'prmDate2': date2,
      'prmDesc': desc,
      'prmCost': cost,
      'prmACTNumber': actNumber,
      'prmUserNam': userNam,
    });
  }

  Future<String?> getDataHistory({
    required String kodeCabang,
    required String idNo,
    required String userCreated,
    required String userGroup,
    required String date1,
    required String date2,
    required String status,
  }) {
    return _callWithBisnis('GetDataHistory', {
      'prmKodeCabang': kodeCabang,
      'prmIDNo': idNo,
      'prmUserCreated': userCreated,
      'prmUserGroup': userGroup,
      'prmDate1': date1,
      'prmDate2': date2,
      'prmStatus': status,
    });
  }

  Future<String?> getDataHistoryType({
    required String kodeCabang,
    required String idNo,
    required String userCreated,
    required String userGroup,
    required String date1,
    required String date2,
    required String status,
    required String type,
  }) {
    return _callWithBisnis('GetDataHistoryWithType', {
      'prmKodeCabang': kodeCabang,
      'prmIDNo': idNo,
      'prmUserCreated': userCreated,
      'prmUserGroup': userGroup,
      'prmDate1': date1,
      'prmDate2': date2,
      'prmStatus': status,
      'prmType': type,
    });
  }

  Future<String?> getDataHistorySPK({
    required String kodeCabang,
    required String idNo,
    required String userCreated,
    required String userGroup,
    required String date1,
    required String date2,
    required String status,
  }) {
    return _callWithBisnis('GetDataHistorySPK', {
      'prmKodeCabang': kodeCabang,
      'prmIDNo': idNo,
      'prmUserCreated': userCreated,
      'prmUserGroup': userGroup,
      'prmDate1': date1,
      'prmDate2': date2,
      'prmStatus': status,
    });
  }

  Future<String?> getFUProspect({
    required String date1,
    required String date2,
    required String userGroup,
  }) {
    return _callWithBisnis('GetFUProspect', {
      'prmDate1': date1,
      'prmDate2': date2,
      'prmUserGroup': userGroup,
    });
  }

  Future<String?> getDataHistoryEdit({
    required String kodeCabang,
    required String idNo,
    required String historyId,
    required String userCreated,
  }) {
    return _callWithBisnis('GetDataHistoryEdit', {
      'prmKodeCabang': kodeCabang,
      'prmIDNo': idNo,
      'prmHistoryID': historyId,
      'prmUserCreated': userCreated,
    });
  }

  Future<String?> getCity([String like = '']) {
    return _callWithBisnis('GetDataCity', {'prmLike': like});
  }

  Future<String?> getFGOCContect({
    required String branchCode,
    required String custCode,
  }) {
    return _callWithBisnis('GetDataFGOCContect', {
      'prmBranchCode': branchCode,
      'prmCustCode': custCode,
    });
  }

  Future<String?> getFGOC({required String branchCode, String like = ''}) {
    return _callWithBisnis('GetDataFGOC', {
      'prmBranchCode': branchCode,
      'prmLike': like,
    });
  }

  Future<String?> getDistrict([String like = '']) {
    return _callWithBisnis('GetDataDistrict', {'prmLike': like});
  }

  Future<String?> getReportDaily(Map<String, String> data) {
    return _callWithBisnis('GetDailyReport', data);
  }

  Future<String?> getReportActivity(Map<String, String> data) {
    return _callWithBisnis('GetActivityReport', data);
  }

  Future<String?> getReportFleetDetail(Map<String, String> data) {
    return _callWithBisnis('GetFleetDetailReport', data);
  }

  Future<String?> getReportFleetSummary(Map<String, String> data) {
    return _callWithBisnis('GetFleetSummaryReport', data);
  }

  Future<String?> getReportActivityRecap(Map<String, String> data) {
    return _callWithBisnis('GetActivityRecapReport', data);
  }

  Future<String?> getReportKPI(Map<String, String> data) {
    return _callWithBisnis('GetKPIReport', data);
  }

  Future<String?> getCustomerReport({
    required String branchCode,
    required String user,
    required String date1,
    required String date2,
    required String reportType,
    required String filter,
  }) {
    return _callWithBisnis('GetCustomerReport', {
      'prmBranchCode': branchCode,
      'prmUser': user,
      'prmDate1': date1,
      'prmDate2': date2,
      'prmReportType': reportType,
      'prmFilter': filter,
    });
  }

  Future<String?> getIncentiveReport({
    required String branchCode,
    required String user,
    required String date1,
    required String date2,
    required String reportType,
  }) {
    return _callWithBisnis('GetIncentiveReport', {
      'prmBranchCode': branchCode,
      'prmUser': user,
      'prmDate1': date1,
      'prmDate2': date2,
      'prmReportType': reportType,
    });
  }

  Future<String?> getIncentiveSPVReport({
    required String branchCode,
    required String user,
    required String date1,
    required String date2,
    required String reportType,
  }) {
    return _callWithBisnis('GetIncentiveSPVReport', {
      'prmBranchCode': branchCode,
      'prmUser': user,
      'prmDate1': date1,
      'prmDate2': date2,
      'prmReportType': reportType,
    });
  }

  Future<String?> getDataSPKIndent({
    required String branchCode,
    required String spkNo,
  }) {
    return _callWithBisnis('GetDataSPKIndent', {
      'prmBranchCode': branchCode,
      'prmSPKNo': spkNo,
    });
  }

  Future<String?> getReportDailySales({
    required String branchCode,
    required String date,
  }) {
    return _callWithBisnis('GetDailySalesReport', {
      'prmBusCode': branchCode,
      'prmDate': date,
    });
  }

  Future<String?> getReportWeeklySales({
    required String branchCode,
    required String date,
  }) {
    return _callWithBisnis('GetWeeklySalesReport', {
      'prmBusCode': branchCode,
      'prmDate': date,
    });
  }

  Future<String?> getReportMonthLyActivity({
    required String branchCode,
    required String date,
  }) {
    return _callWithBisnis('GetMonthLyActivityReport', {
      'prmBusCode': branchCode,
      'prmDate': date,
    });
  }

  Future<String?> getReportMonthLyFGOC({
    required String branchCode,
    required String username,
    required String date,
  }) {
    return _callWithBisnis('GetMonthLyActivityFGOCReport', {
      'prmBusCode': branchCode,
      'prmUsername': username,
      'prmDate': date,
    });
  }

  Future<String?> getReportMonthlySumSPV({
    required String branchCode,
    required String date,
  }) {
    return _callWithBisnis('GetMonthlySummarySPVReport', {
      'prmBusCode': branchCode,
      'prmDate': date,
    });
  }

  Future<String?> getReportDailySalesDetail({
    required String branchCode,
    required String user,
    required String date1,
  }) {
    return _callWithBisnis('GetCRMDailySalesDetailMMSDReport', {
      'prmBranchCode': branchCode,
      'prmUser': user,
      'prmDate1': date1,
    });
  }

  Future<String?> getReportMonthlySumBM({
    required String branchCode,
    required String date,
  }) {
    return _callWithBisnis('GetMonthlySummaryBMReport', {
      'prmBusCode': branchCode,
      'prmDate': date,
    });
  }

  Future<String?> getReportMonthlySumGM({
    required String branchCode,
    required String date,
    required String user,
    required String userStatus,
  }) {
    return _callWithBisnis('GetMonthlySummaryGMReport', {
      'prmBusCode': branchCode,
      'prmDate': date,
      'prmUser': user,
      'prmUserStatus': userStatus,
    });
  }

  Future<String?> getReportDailySalesGM({
    required String branchCode,
    required String date,
    required String user,
    required String userStatus,
  }) {
    return _callWithBisnis('GetDailySalesGMReport', {
      'prmBusCode': branchCode,
      'prmDate': date,
      'prmUser': user,
      'prmUserStatus': userStatus,
    });
  }

  Future<String?> getReportDailySalesGM2({
    required String branchCode,
    required String date,
    required String user,
    required String userStatus,
  }) {
    return _callWithBisnis('GetDailySalesGMReport2', {
      'prmBusCode': branchCode,
      'prmDate': date,
      'prmUser': user,
      'prmUserStatus': userStatus,
    });
  }
}
