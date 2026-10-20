import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/code_name.dart';
import '../models/history_row.dart';
import '../providers/auth_provider.dart';
import '../providers/master_data_provider.dart';
import '../providers/spk_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../utils/spk_list_action.dart';
import '../widgets/app_widgets.dart';

class SpkFormScreen extends StatefulWidget {
  const SpkFormScreen({
    super.key,
    required this.row,
    this.action = 'NEW',
  });

  final HistoryRow row;
  final String action;

  bool get isCompany => row.idNo.isNotEmpty && !row.idNo.startsWith('1');

  @override
  State<SpkFormScreen> createState() => _SpkFormScreenState();
}

class _SpkFormScreenState extends State<SpkFormScreen> {
  bool get _canEdit => SpkListAction.canEdit(widget.action);
  bool get _canSave => SpkListAction.canSave(widget.action);
  String _date = AppDateFormat.mdy(DateTime.now());
  String _birth = '';
  String _payType = 'Cash';
  String _top = '';
  String _religion = '-';
  bool _faktur = false;
  bool _saving = false;
  bool _loading = true;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _phone2 = TextEditingController();
  final _address = TextEditingController();
  final _ktp = TextEditingController();
  final _stnk = TextEditingController();
  final _npwp = TextEditingController();
  final _dp = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  final _manual = TextEditingController();
  final _fakturName = TextEditingController();
  final _pic = TextEditingController();
  final _fgocName = TextEditingController();
  final _fgocPhone = TextEditingController();
  final _fgocPosition = TextEditingController();
  String _spkNo = '';
  String _customerCode = '';
  final String _fgocId = '';
  List<CodeName> _tops = const [];
  List<CityItem> _cities = [];
  List<DistrictItem> _districts = [];
  List<CodeName> _brands = [];
  List<CodeName> _types = [];
  List<CodeName> _models = [];
  List<CodeName> _colors = [];
  List<CodeName> _activities = [];
  CodeName? _brand;
  CodeName? _type;
  CodeName? _model;
  CodeName? _color;
  CodeName? _activity;
  CityItem? _city;
  DistrictItem? _district;

  @override
  void initState() {
    super.initState();
    _name.text = widget.row.name;
    _phone.text = widget.row.phone;
    _pic.text = widget.row.pic;
    _spkNo = widget.row.spkNo;
    _customerCode = widget.action == SpkListAction.create ? '' : widget.row.idNo;
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _phone2.dispose();
    _address.dispose();
    _ktp.dispose();
    _stnk.dispose();
    _npwp.dispose();
    _dp.dispose();
    _price.dispose();
    _desc.dispose();
    _manual.dispose();
    _fakturName.dispose();
    _pic.dispose();
    _fgocName.dispose();
    _fgocPhone.dispose();
    _fgocPosition.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final user = context.read<AuthProvider>().user;
    final master = context.read<MasterDataProvider>();
    final brands = await master.getBrands();
    final types = await master.getTypes();
    final colors = await master.getColors();
    final activities = await master.getActivities();
    final cities = await master.getCities();
    final tops = await master.getTOP();
    if (!mounted) return;
    setState(() {
      _brands = brands;
      _types = types;
      _colors = colors;
      _activities = activities;
      _cities = cities;
      if (tops.isNotEmpty) {
        _tops = tops;
        if (!_tops.any((item) => item.code == _top)) _top = tops.first.code;
      }
      _brand = brands.isNotEmpty ? brands.first : null;
      _type = types.isNotEmpty ? types.first : null;
      _color = colors.isNotEmpty ? colors.first : null;
      _activity = activities.isNotEmpty ? activities.first : null;
      _city = cities.isNotEmpty ? cities.first : null;
    });
    await _reloadModels();
    await _reloadDistricts();
    if (!mounted) return;
    if (user != null && widget.action != SpkListAction.create) {
      final branch = user.busCode;
      final rows = await context.read<SpkProvider>().getCustomerSPK(
            branchCode: branch,
            idNo: widget.row.idNo,
            historyNo: widget.row.historyId,
            spkNo: widget.row.spkNo,
          );
      if (mounted && rows.isNotEmpty) _applyCustomer(rows.first);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyCustomer(Map<String, String> row) {
    String v(String key) {
      final value = row[key] ?? '';
      return value == '-' ? '' : value;
    }

    setState(() {
      _customerCode = v('Pref1');
      _name.text = v('Pref2').isEmpty ? _name.text : v('Pref2');
      _birth = v('Pref3');
      if (v('Pref4').isNotEmpty) _religion = v('Pref4');
      _address.text = v('Pref5');
      _phone.text = v('Pref6').isEmpty ? _phone.text : v('Pref6');
      _phone2.text = v('Pref7');
      final top = v('Pref8');
      if (top == '1') {
        _payType = 'Cash';
      } else if (top == '0') {
        _payType = 'Credit';
      }
      if (v('Pref9').isNotEmpty) _spkNo = v('Pref9');
      _manual.text = v('Pref10');
      _stnk.text = v('Pref11');
      _npwp.text = v('Pref12');
      _desc.text = v('Pref14');
      _faktur = v('Pref15') == '1';
      _fakturName.text = v('Pref16');
      _dp.text = v('Pref17');
      _price.text = v('Pref18');
    });
  }

  Future<void> _reloadModels() async {
    if (_brand == null || _type == null) return;
    final models = await context.read<MasterDataProvider>().getModels(
          brandCode: _brand!.code,
          typeCode: _type!.code,
        );
    if (!mounted) return;
    setState(() {
      _models = models;
      _model = models.isNotEmpty ? models.first : null;
    });
  }

  Future<void> _reloadDistricts() async {
    if (_city == null) return;
    final items = await context.read<MasterDataProvider>().getDistricts(
          provinceCode: _city!.provinceCode,
          cityCode: _city!.cityCode,
        );
    if (!mounted) return;
    setState(() {
      _districts = items;
      _district = items.isNotEmpty ? items.first : null;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill the blank field')),
      );
      return;
    }
    if (_payType == '-' || _payType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill TOP')),
      );
      return;
    }
    if (_city == null || _district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid city')),
      );
      return;
    }
    if ((_model?.code ?? '').length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid model')),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<SpkProvider>();
    final success = await provider.createSPK({
      'prmIDNo': widget.row.idNo,
      'prmUserCreated': user.username,
      'prmHistoryID': widget.row.historyId,
      'prmHPDate': _date,
      'prmSPKDate': _date,
      'prmMName': _name.text,
      'prmMAddress': _address.text,
      'prmMPhone2': _phone2.text.isEmpty ? _phone.text : _phone2.text,
      'prmMKTPNo': _ktp.text,
      'prmMBirthDate': _birth.isEmpty ? '1/1/1900' : _birth,
      'prmMReligion': _religion == '-' ? '' : _religion,
      'prmTOP': _payType,
      'prmMPIC': _pic.text,
      'prmMJobCode': '',
      'prmMLOBCode': '',
      'prmMUserLevel': user.userGroup,
      'prmSalesCode': user.salesCode,
      'prmBranchCode': user.busCode,
      'prmBrandCode': _brand?.code ?? '',
      'prmTypeCode': _type?.code ?? '',
      'prmModelCode': _model?.code ?? '',
      'prmQty': widget.row.qty.isEmpty ? '1' : widget.row.qty,
      'prmColourCode': _color?.code ?? '',
      'prmActivityCode': _activity?.code ?? '',
      'prmMProvinceCode': _city?.provinceCode ?? '',
      'prmMCityCode': _city?.cityCode ?? '',
      'prmMDistrictCode': _district?.districtCode ?? '',
      'prmCustomerCode': _customerCode,
      'prmTOP2': _top.isEmpty && _tops.isNotEmpty ? _tops.first.code : _top,
      'prmSPKManual': _manual.text,
      'prmSTNK': _stnk.text.trim().isEmpty ? _name.text : _stnk.text,
      'prmNPWP': _npwp.text,
      'prmDescription': _desc.text,
      'prmIsFaktur': _faktur ? '1' : '0',
      'prmFaktur': _fakturName.text,
      'prmDPInfo': _dp.text.replaceAll(',', ''),
      'prmSPKNo': _spkNo,
      'prmAction': widget.action,
      'prmSPKPrice': _price.text.replaceAll(',', ''),
      'prmFGOCContectId': _fgocId,
      'prmFGOCContectName': _fgocName.text,
      'prmFGOCContectPhone': _fgocPhone.text,
      'prmFGOCContectPosition': _fgocPosition.text,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Data successfully saved'
              : provider.errorMessage.isEmpty
              ? 'Failed to save data'
              : provider.errorMessage,
        ),
      ),
    );
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: AppLoading(message: 'Memuat form SPK...'));
    }
    final company = widget.isCompany;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.action == SpkListAction.create
              ? (company ? 'SPK Company' : 'SPK Personal')
              : 'SPK Information',
        ),
      ),
      body: AppLoadingOverlay(
        visible: _saving,
        message: 'Menyimpan SPK...',
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          IgnorePointer(
            ignoring: !_canEdit,
            child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.row.model.isEmpty ? widget.row.name : widget.row.model,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _name,
                  label: 'Name',
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phone,
                  label: 'Phone',
                  readOnly: true,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phone2,
                  label: 'Phone 2',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_iphone_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _address,
                  label: 'Address',
                  prefixIcon: Icons.home_outlined,
                ),
                const SizedBox(height: 14),
                AppDateField(
                  label: 'Birth Date',
                  value: _birth,
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                  onPicked: (date) =>
                      setState(() => _birth = AppDateFormat.mdy(date)),
                ),
                const SizedBox(height: 14),
                AppDropdown<String>(
                  label: 'Religion',
                  value: _religion,
                  items: const [
                    '-',
                    'Islam',
                    'Kristen',
                    'Hindu',
                    'Budha',
                    'Konghucu',
                    'Katolik',
                  ]
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setState(() => _religion = value ?? '-'),
                ),
                const SizedBox(height: 14),
                AppDropdown<CityItem>(
                  label: 'City',
                  value: _city,
                  items: _cities
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.cityName, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (item) {
                    setState(() => _city = item);
                    _reloadDistricts();
                  },
                ),
                const SizedBox(height: 14),
                AppDropdown<DistrictItem>(
                  label: 'District',
                  value: _district,
                  items: _districts
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.districtName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (item) => setState(() => _district = item),
                ),
                if (company) ...[
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _pic,
                    label: 'PIC',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _fgocName,
                    label: 'FGOC Contact',
                    prefixIcon: Icons.apartment_outlined,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _fgocPhone,
                    label: 'FGOC Phone',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _fgocPosition,
                    label: 'FGOC Position',
                    prefixIcon: Icons.work_outline,
                  ),
                ],
              ],
            ),
          ),
          ),
          const SizedBox(height: 14),
          IgnorePointer(
            ignoring: !_canEdit,
            child: AppCard(
            child: Column(
              children: [
                AppDateField(
                  label: 'SPK Date',
                  value: _date,
                  onPicked: (date) =>
                      setState(() => _date = AppDateFormat.mdy(date)),
                ),
                const SizedBox(height: 14),
                AppDropdown<String>(
                  label: 'PY Type',
                  value: _payType,
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Credit', child: Text('Credit')),
                  ],
                  onChanged: (value) => setState(() => _payType = value ?? 'Cash'),
                ),
                const SizedBox(height: 14),
                AppDropdown<String>(
                  label: 'TOP',
                  value: _tops.any((item) => item.code == _top)
                      ? _top
                      : (_tops.isEmpty ? _top : _tops.first.code),
                  items: _tops
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.code,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _top = value ?? ''),
                ),
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
                const SizedBox(height: 14),
                AppDropdown<CodeName>(
                  label: 'Colour',
                  value: _color,
                  items: _codeItems(_colors),
                  onChanged: (item) => setState(() => _color = item),
                ),
                const SizedBox(height: 14),
                AppDropdown<CodeName>(
                  label: 'Activity',
                  value: _activity,
                  items: _codeItems(_activities),
                  onChanged: (item) => setState(() => _activity = item),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _ktp,
                  label: 'KTP No',
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _manual,
                  label: 'SPK Manual No',
                  prefixIcon: Icons.tag_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _stnk,
                  label: 'STNK Name',
                  prefixIcon: Icons.directions_car_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _npwp,
                  label: 'NPWP',
                  prefixIcon: Icons.receipt_long_outlined,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Faktur'),
                  value: _faktur,
                  onChanged: (value) => setState(() => _faktur = value),
                ),
                AppTextField(
                  controller: _fakturName,
                  label: 'Faktur An',
                  prefixIcon: Icons.assignment_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _price,
                  label: 'SPK Price',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.payments_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _dp,
                  label: 'DP',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.savings_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _desc,
                  label: 'Description',
                  prefixIcon: Icons.notes_outlined,
                ),
              ],
            ),
          ),
          ),
          if (_canSave) ...[
            const SizedBox(height: 22),
            AppPrimaryButton(
              label: SpkListAction.saveLabel(widget.action),
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ],
        ),
      ),
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
