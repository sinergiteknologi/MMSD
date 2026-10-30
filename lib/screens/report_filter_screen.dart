import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/code_name.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/master_data_provider.dart';
import '../providers/report_provider.dart';
import '../utils/app_status.dart';
import '../utils/date_format.dart';
import '../widgets/app_widgets.dart';
import 'report_table_screen.dart';

class ReportFilterScreen extends StatefulWidget {
  const ReportFilterScreen({super.key, required this.crm});

  final bool crm;

  @override
  State<ReportFilterScreen> createState() => _ReportFilterScreenState();
}

class _ReportFilterScreenState extends State<ReportFilterScreen> {
  late String _report;
  late String _date1;
  late String _date2;
  late String _date;
  String _scope = 'Sales';
  String _customerType = 'Birth Date';
  String _findBy = 'Customer';
  final _findValue = TextEditingController();
  final Set<String> _statuses = {
    AppStatus.prospect,
    AppStatus.followUp,
    AppStatus.hotProspect,
    AppStatus.trueProspect,
    AppStatus.spk,
    'DO',
    AppStatus.cancel,
  };
  List<CodeName> _brands = [];
  List<CodeName> _types = [];
  List<CodeName> _models = [];
  List<CodeName> _activities = [];
  List<CodeName> _subActivities = [];
  List<CodeName> _fleets = [];
  CodeName? _brand;
  CodeName? _type;
  CodeName? _model;
  CodeName? _activity;
  CodeName? _subActivity;
  CodeName? _fleet1;
  CodeName? _fleet2;

  static const _all = CodeName(code: '', name: 'All');

  List<String> get _reports => widget.crm
      ? const [
          'Daily Sales',
          'Daily Sales Detail',
          'Weekly Sales',
          'Monthly Activity',
          'Monthly Summary SPV',
          'Monthly Summary BM',
          'Monthly Summary GM',
          'Daily Sales GM',
          'FGOC',
        ]
      : const [
          'Status List',
          'Daily',
          'Activity',
          'Fleet Detail',
          'Fleet Summary',
          'Activity Recap',
          'KPI Weekly',
          'KPI Monthly',
          'Customer',
          'Incentive',
          'Incentive SPV',
        ];

  List<String> _scopes(UserModel? user) {
    if (_report == 'Customer') {
      return const [
        'Birth Date',
        'BPKB is Ready',
        'Extend STNK',
        'Service Schedule',
        'Religion',
      ];
    }
    if (_report == 'Incentive') return const ['Sales'];
    if (_report == 'Incentive SPV') return const ['SPV'];
    switch (user?.userStatus) {
      case 'Sales':
        return const ['Sales'];
      case 'SPV':
        return const ['Sales', 'SPV'];
      case 'BM':
        return const ['Sales', 'SPV', 'Branch'];
      default:
        return const ['Sales', 'SPV', 'Branch'];
    }
  }

  List<String> get _findByItems {
    switch (_customerType) {
      case 'BPKB is Ready':
        return const [
          'Customer',
          'Phone',
          'City',
          'BPKBDONE',
          'BPKBNo',
          'BPKBDate',
          'NoPol',
          'Model',
        ];
      case 'Extend STNK':
        return const ['Customer', 'Phone', 'City', 'NoPol', 'STNKExpired', 'Model'];
      case 'Service Schedule':
        return const [
          'Customer',
          'Phone',
          'City',
          'LastService',
          'ServiceSchedule',
          'KM',
          'NoPol',
          'Model',
        ];
      case 'Religion':
        return const ['Customer', 'Phone', 'City', 'Religion'];
      default:
        return const ['Customer', 'Phone', 'City', 'BirthDate', 'Age'];
    }
  }

  bool get _showStatus =>
      !widget.crm &&
      const {'Status List', 'Daily', 'Fleet Detail', 'Fleet Summary'}
          .contains(_report);

  bool get _showBrand => !widget.crm && _report == 'Daily';

  bool get _showActivity => !widget.crm && _report == 'Activity';

  bool get _showFleet =>
      !widget.crm && (_report == 'Fleet Detail' || _report == 'Fleet Summary');

  bool get _showCustomer => !widget.crm && _report == 'Customer';

  @override
  void initState() {
    super.initState();
    _report = _reports.first;
    _date1 = AppDateFormat.mdy(AppDateFormat.monthStart());
    _date2 = AppDateFormat.mdy(AppDateFormat.monthEnd());
    _date = AppDateFormat.mdy(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMaster());
  }

  @override
  void dispose() {
    _findValue.dispose();
    super.dispose();
  }

  Future<void> _loadMaster() async {
    final master = context.read<MasterDataProvider>();
    final brands = [_all, ...await master.getBrands()];
    final types = [_all, ...await master.getTypes()];
    final activities = [_all, ...await master.getActivities()];
    final fleets = [_all, ...await master.getFleet()];
    if (!mounted) return;
    setState(() {
      _brands = brands;
      _types = types;
      _activities = activities;
      _fleets = fleets;
      _brand = brands.first;
      _type = types.first;
      _activity = activities.first;
      _fleet1 = fleets.first;
      _fleet2 = fleets.first;
    });
    await _reloadModels();
    await _reloadSubActivities();
  }

  Future<void> _reloadModels() async {
    if (_brand == null || _type == null || _brand!.code.isEmpty || _type!.code.isEmpty) {
      setState(() {
        _models = [_all];
        _model = _all;
      });
      return;
    }
    final models = [
      _all,
      ...await context.read<MasterDataProvider>().getModels(
            brandCode: _brand!.code,
            typeCode: _type!.code,
          ),
    ];
    if (!mounted) return;
    setState(() {
      _models = models;
      _model = models.first;
    });
  }

  Future<void> _reloadSubActivities() async {
    if (_activity == null || _activity!.code.isEmpty) {
      setState(() {
        _subActivities = [_all];
        _subActivity = _all;
      });
      return;
    }
    final items = [
      _all,
      ...await context
          .read<MasterDataProvider>()
          .getSubActivities(_activity!.code),
    ];
    if (!mounted) return;
    setState(() {
      _subActivities = items;
      _subActivity = items.first;
    });
  }

  String get _statusParam => _statuses.join(',');

  String get _prmSp => '$_report$_scope';

  String _reportUser(UserModel user) {
    if (_scope == 'Sales') {
      return user.userGroup.isEmpty ? user.username : user.userGroup;
    }
    return user.username;
  }

  Future<void> _find() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final reports = context.read<ReportProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportTableScreen(
          title: _report,
          columns: reportColumns(_report),
          phoneKey: _report == 'Customer'
              ? 'Pref2'
              : (_report == 'Status List' ? 'Pref4' : null),
          loader: () => _load(reports, user),
        ),
      ),
    );
  }

  Future<List<Map<String, String>>> _load(
    ReportProvider reports,
    UserModel user,
  ) {
    final common = <String, String>{
      'prmSP': _prmSp,
      'prmBusCode': user.busCode,
      'prmUser': _reportUser(user),
    };
    switch (_report) {
      case 'Daily Sales':
        return reports.getDailySales(branchCode: user.busCode, date: _date);
      case 'Daily Sales Detail':
        return reports.getDailySalesDetail(
          branchCode: user.busCode,
          user: user.username,
          date1: _date,
        );
      case 'Weekly Sales':
        // SP: @BranchCode, @Periode (YYYYMM)
        return reports.getWeeklySales(
          branchCode: user.busCode,
          date: AppDateFormat.periodeFromMdy(_date),
        );
      case 'Monthly Activity':
        // SP: @BranchCode, @Periode (YYYYMM)
        return reports.getMonthlyActivity(
          branchCode: user.busCode,
          date: AppDateFormat.periodeFromMdy(_date),
        );
      case 'Monthly Summary SPV':
        return reports.getMonthlySumSPV(branchCode: user.busCode, date: _date);
      case 'Monthly Summary BM':
        return reports.getMonthlySumBM(branchCode: user.busCode, date: _date);
      case 'Monthly Summary GM':
        return reports.getMonthlySumGM(
          branchCode: user.busCode,
          date: _date,
          user: user.username,
          userStatus: user.userStatus,
        );
      case 'Daily Sales GM':
        return reports.getDailySalesGM2(
          branchCode: user.busCode,
          date: _date,
          user: user.username,
          userStatus: user.userStatus,
        );
      case 'FGOC':
        return reports.getMonthlyFGOC(
          branchCode: user.busCode,
          username: user.username,
          date: _date,
        );
      case 'Status List':
        return reports.getStatusList(
          user: user,
          date1: _date1,
          date2: _date2,
          status: _statusParam,
          type: _scope,
        );
      case 'Daily':
        return reports.getReportDailyRows({
          ...common,
          'prmStatus': _statusParam,
          'prmBrand': _brand?.code ?? '',
          'prmType': _type?.code ?? '',
          'prmModel': _model?.code ?? '',
          'prmDate1': _date1,
          'prmDate2': _date2,
        });
      case 'Activity':
        return reports.getReportActivityRows({
          ...common,
          'prmActivity': _activity?.code ?? '',
          'prmSubActivity': _subActivity?.code ?? '',
          'prmDate1': _date1,
          'prmDate2': _date2,
          'prmUserStatus': user.userStatus,
        });
      case 'Fleet Detail':
        return reports.getReportFleetDetail({
          ...common,
          'prmFC1': _fleet1?.code ?? '',
          'prmFC2': _fleet2?.code ?? '',
          'prmDate1': _date1,
          'prmDate2': _date2,
          'prmUserStatus': user.userStatus,
          'prmStatus': _statusParam,
        });
      case 'Fleet Summary':
        return reports.getReportFleetSummary({
          ...common,
          'prmFC1': _fleet1?.code ?? '',
          'prmFC2': _fleet2?.code ?? '',
          'prmDate1': _date1,
          'prmDate2': _date2,
          'prmUserStatus': user.userStatus,
          'prmStatus': _statusParam,
        });
      case 'Activity Recap':
        return reports.getReportActivityRecap({
          ...common,
          'prmDate1': _date1,
          'prmDate2': _date2,
          'prmUserStatus': user.userStatus,
          'prmUserName': user.username,
        });
      case 'KPI Weekly':
      case 'KPI Monthly':
        return reports.getReportKPI({
          ...common,
          'prmDate1': _date1,
          'prmUserStatus': user.userStatus,
          'prmUserName': user.username,
        });
      case 'Customer':
        return reports.getCustomerReport(
          branchCode: user.busCode,
          user: user.username,
          date1: _date1,
          date2: _date2,
          reportType: _customerType,
          filter: _findValue.text.trim().isEmpty
              ? ''
              : '$_findBy=${_findValue.text.trim()}',
        );
      case 'Incentive':
        return reports.getIncentiveReport(
          branchCode: user.busCode,
          user: user.salesCode,
          date1: _date1,
          date2: _date2,
          reportType: _scope,
        );
      case 'Incentive SPV':
        return reports.getIncentiveSPVReport(
          branchCode: user.busCode,
          user: user.salesCode,
          date1: _date1,
          date2: _date2,
          reportType: _scope,
        );
      default:
        throw StateError('Report tidak didukung: $_report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final scopes = _scopes(user);
    return Scaffold(
      appBar: AppBar(title: Text(widget.crm ? 'Report CRM' : 'Report')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parameter report',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                AppDropdown<String>(
                  label: 'Report',
                  value: _report,
                  items: _reports
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _report = value;
                      if (value == 'Customer') {
                        _customerType = 'Birth Date';
                        _findBy = 'Customer';
                      } else {
                        final next = _scopes(user);
                        _scope = next.first;
                      }
                    });
                  },
                ),
                if (!widget.crm) ...[
                  const SizedBox(height: 14),
                  if (_showCustomer)
                    AppDropdown<String>(
                      label: 'Tipe Customer',
                      value: _customerType,
                      items: _scopes(user)
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _customerType = value;
                          _findBy = _findByItems.first;
                        });
                      },
                    )
                  else
                    AppDropdown<String>(
                      label: 'Scope',
                      value: scopes.contains(_scope) ? _scope : scopes.first,
                      items: scopes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _scope = value);
                      },
                    ),
                ],
                const SizedBox(height: 14),
                if (widget.crm) ...[
                  AppDateField(
                    label: 'Date',
                    value: _date,
                    onPicked: (date) =>
                        setState(() => _date = AppDateFormat.mdy(date)),
                  ),
                ] else ...[
                  AppDateField(
                    label: 'Date From',
                    value: _date1,
                    onPicked: (date) =>
                        setState(() => _date1 = AppDateFormat.mdy(date)),
                  ),
                  const SizedBox(height: 14),
                  AppDateField(
                    label: 'Date To',
                    value: _date2,
                    onPicked: (date) =>
                        setState(() => _date2 = AppDateFormat.mdy(date)),
                  ),
                ],
                if (_showBrand) ...[
                  const SizedBox(height: 14),
                  AppDropdown<CodeName>(
                    label: 'Brand',
                    value: _brand,
                    items: _codeItems(_brands),
                    onChanged: (item) {
                      setState(() => _brand = item);
                      _reloadModels();
                    },
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<CodeName>(
                    label: 'Type',
                    value: _type,
                    items: _codeItems(_types),
                    onChanged: (item) {
                      setState(() => _type = item);
                      _reloadModels();
                    },
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<CodeName>(
                    label: 'Model',
                    value: _model,
                    items: _codeItems(_models),
                    onChanged: (item) => setState(() => _model = item),
                  ),
                ],
                if (_showActivity) ...[
                  const SizedBox(height: 14),
                  AppDropdown<CodeName>(
                    label: 'Activity',
                    value: _activity,
                    items: _codeItems(_activities),
                    onChanged: (item) {
                      setState(() => _activity = item);
                      _reloadSubActivities();
                    },
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<CodeName>(
                    label: 'Sub Activity',
                    value: _subActivity,
                    items: _codeItems(_subActivities),
                    onChanged: (item) => setState(() => _subActivity = item),
                  ),
                ],
                if (_showFleet) ...[
                  const SizedBox(height: 14),
                  AppDropdown<CodeName>(
                    label: 'Fleet 1',
                    value: _fleet1,
                    items: _codeItems(_fleets),
                    onChanged: (item) => setState(() => _fleet1 = item),
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<CodeName>(
                    label: 'Fleet 2',
                    value: _fleet2,
                    items: _codeItems(_fleets),
                    onChanged: (item) => setState(() => _fleet2 = item),
                  ),
                ],
                if (_showCustomer) ...[
                  const SizedBox(height: 14),
                  AppDropdown<String>(
                    label: 'Find By',
                    value: _findByItems.contains(_findBy)
                        ? _findBy
                        : _findByItems.first,
                    items: _findByItems
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _findBy = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _findValue,
                    label: 'Nilai filter',
                    prefixIcon: Icons.filter_alt_outlined,
                  ),
                ],
                if (_showStatus) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusChip('PP', AppStatus.prospect),
                      _statusChip('FU', AppStatus.followUp),
                      _statusChip('HP', AppStatus.hotProspect),
                      _statusChip('TP', AppStatus.trueProspect),
                      _statusChip('SPK', AppStatus.spk),
                      _statusChip('DO', 'DO'),
                      _statusChip('Cancel', AppStatus.cancel),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                AppPrimaryButton(label: 'Find', onPressed: _find),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final selected = _statuses.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (on) {
        setState(() {
          if (on) {
            _statuses.add(value);
          } else {
            _statuses.remove(value);
          }
        });
      },
    );
  }

  List<DropdownMenuItem<CodeName>> _codeItems(List<CodeName> items) {
    return items
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(item.name, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();
  }
}
