class ReportDaily {
  final String busCode;
  final String business;
  final String user;
  final String status;
  final Map<String, String> days;
  final String total;

  const ReportDaily({
    this.busCode = '',
    this.business = '',
    this.user = '',
    this.status = '',
    this.days = const {},
    this.total = '',
  });
}

class ReportActivity {
  final String activityName;
  final String subActivityName;
  final String actNumber;
  final String actName;
  final String spvName;
  final String salesName;
  final String startDate;
  final String endDate;
  final String cityName;
  final String districtName;
  final String totalProspect;
  final String totalSpk;
  final String totalDo;

  const ReportActivity({
    this.activityName = '',
    this.subActivityName = '',
    this.actNumber = '',
    this.actName = '',
    this.spvName = '',
    this.salesName = '',
    this.startDate = '',
    this.endDate = '',
    this.cityName = '',
    this.districtName = '',
    this.totalProspect = '',
    this.totalSpk = '',
    this.totalDo = '',
  });
}
