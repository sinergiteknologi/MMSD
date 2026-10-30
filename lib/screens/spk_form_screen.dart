import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/code_name.dart';
import '../models/history_row.dart';
import '../providers/auth_provider.dart';
import '../providers/master_data_provider.dart';
import '../providers/prospect_provider.dart';
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

  // Digit 1 IDNo = Personal, digit 2 = FGOC (sama Android T207/T208/T209)
  bool get isPersonal => row.idNo.isNotEmpty && row.idNo.startsWith('1');
  bool get isFgoc => row.idNo.isNotEmpty && row.idNo.startsWith('2');
  bool get isCompany => isFgoc;

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
  String _fgocId = '';
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
      // Jangan default ke item pertama dulu — tunggu data prospect/history
      _brand = null;
      _type = null;
      _model = null;
      _color = null;
      _activity = null;
      _city = null;
      _district = null;
    });
    if (!mounted) return;
    if (user != null) {
      final prospect = context.read<ProspectProvider>();
      // 1) Query khusus SPK Registration (prmSPK=1) + HistoryID
      final prospectRows = await prospect.findProspect2(
        filterTlp: '',
        filterId: widget.row.idNo,
        user: user.username,
        historyId: widget.row.historyId,
        forSpk: true,
      );
      if (mounted && prospectRows.isNotEmpty) {
        await _applyProspect(prospectRows.first);
      }
      // 2) Fallback alamat dari customer jika prospect Address kosong
      if (mounted && _address.text.trim().isEmpty) {
        final custRows = await prospect.getCustomer(
          branchCode: user.busCode,
          idNo: widget.row.idNo,
        );
        if (mounted && custRows.isNotEmpty) {
          await _applyCustomerAddress(custRows.first);
        }
      }
      // 3) Brand/type/model/warna/activity dari history unit prospect
      final hist = await prospect.getHistoryEdit(
        kodeCabang: user.busCode,
        idNo: widget.row.idNo,
        historyId: widget.row.historyId,
        userCreated: user.username,
      );
      final histRow = hist?.toRows(maxPref: 14).firstOrNull;
      if (mounted && histRow != null) {
        await _applyHistoryUnit(histRow);
      }
      if (widget.action != SpkListAction.create) {
        final rows = await context.read<SpkProvider>().getCustomerSPK(
              branchCode: user.busCode,
              idNo: widget.row.idNo,
              historyNo: widget.row.historyId,
              spkNo: widget.row.spkNo,
            );
        if (mounted && rows.isNotEmpty) _applyCustomer(rows.first);
      }
    }
    // Fallback terakhir kalau history/prospect tidak ketemu
    if (mounted) {
      setState(() {
        _brand ??= _brands.isEmpty ? null : _brands.first;
        _type ??= _types.isEmpty ? null : _types.first;
        _color ??= _colors.isEmpty ? null : _colors.first;
        _activity ??= _activities.isEmpty ? null : _activities.first;
        _city ??= _cities.isEmpty ? null : _cities.first;
      });
      if (_models.isEmpty) await _reloadModels();
      if (_district == null) await _reloadDistricts();
      setState(() => _loading = false);
    }
  }

  Future<void> _applyHistoryUnit(Map<String, String> row) async {
    String c(String key) {
      final value = row[key] ?? '';
      return value == '-' ? '' : value;
    }

    final brandCode = c('Pref3');
    var typeCode = c('Pref4');
    final modelCode = c('Pref5');
    final colourCode = c('Pref7');
    final activityCode = c('Pref8');
    if (typeCode.isEmpty && brandCode.isNotEmpty && modelCode.isNotEmpty) {
      typeCode = await context.read<MasterDataProvider>().findTypeCodeForModel(
                brandCode: brandCode,
                modelCode: modelCode,
              ) ??
          '';
    }
    if (!mounted) return;
    setState(() {
      if (brandCode.isNotEmpty) {
        _brand =
            _brands.where((item) => item.code == brandCode).firstOrNull ?? _brand;
      }
      if (typeCode.isNotEmpty) {
        _type =
            _types.where((item) => item.code == typeCode).firstOrNull ?? _type;
      }
      if (colourCode.isNotEmpty) {
        _color =
            _colors.where((item) => item.code == colourCode).firstOrNull ??
            _color;
      }
      if (activityCode.isNotEmpty) {
        _activity = _activities
                .where((item) => item.code == activityCode)
                .firstOrNull ??
            _activity;
      }
    });
    await _reloadModels(preferredModelCode: modelCode);
  }

  Future<void> _applyProspect(Map<String, String> row) async {
    String v(String key) {
      final value = row[key] ?? '';
      return value == '-' ? '' : value;
    }

    // Pref16 Province, Pref17 CityCode, Pref18 DistrictCode
    final provinceCode = v('Pref16');
    final cityCode = v('Pref17');
    final cityName = v('Pref6');
    final districtCode = v('Pref18');
    final districtName = v('Pref7');
    final address = v('Pref4');
    final birth = v('Pref8');
    final religion = v('Pref9');
    CityItem? matchedCity;
    if (cityCode.isNotEmpty) {
      matchedCity = _cities.where((item) {
        if (item.cityCode != cityCode) return false;
        if (provinceCode.isNotEmpty && item.provinceCode != provinceCode) {
          return false;
        }
        return true;
      }).firstOrNull;
    }
    matchedCity ??= cityName.isEmpty
        ? null
        : _cities.where((item) => item.cityName == cityName).firstOrNull;
    setState(() {
      _name.text = v('Pref3').isEmpty ? _name.text : v('Pref3');
      _phone.text = v('Pref2').isEmpty ? _phone.text : v('Pref2');
      if (v('Pref5').isNotEmpty) _phone2.text = v('Pref5');
      if (address.isNotEmpty) _address.text = address;
      if (birth.isNotEmpty && birth != '1/1/1900' && birth != '01/01/1900') {
        _birth = birth;
      }
      if (religion.isNotEmpty) _religion = religion;
      if (v('Pref10').isNotEmpty) _pic.text = v('Pref10');
      // Pref12–15 = FGOC contact (penting untuk IDNo 2.x)
      if (v('Pref12').isNotEmpty) _fgocId = v('Pref12');
      if (v('Pref13').isNotEmpty) _fgocName.text = v('Pref13');
      if (v('Pref14').isNotEmpty) _fgocPhone.text = v('Pref14');
      if (v('Pref15').isNotEmpty) _fgocPosition.text = v('Pref15');
      if (matchedCity != null) _city = matchedCity;
    });
    await _reloadDistricts(
      preferredCode: districtCode,
      preferredName: districtName,
    );
  }

  Future<void> _applyCustomerAddress(Map<String, String> row) async {
    String v(String key) {
      final value = row[key] ?? '';
      return value == '-' ? '' : value;
    }

    final cityName = v('Pref8');
    final districtName = v('Pref9');
    setState(() {
      if (v('Pref5').isNotEmpty) _address.text = v('Pref5');
      if (v('Pref3').isNotEmpty &&
          v('Pref3') != '1/1/1900' &&
          v('Pref3') != '01/01/1900') {
        _birth = v('Pref3');
      }
      if (v('Pref4').isNotEmpty) _religion = v('Pref4');
      if (v('Pref7').isNotEmpty) _phone2.text = v('Pref7');
      if (cityName.isNotEmpty && _city == null) {
        _city =
            _cities.where((item) => item.cityName == cityName).firstOrNull ??
            _city;
      }
    });
    if (_city != null && _district == null) {
      await _reloadDistricts(preferredName: districtName);
    }
  }

  void _applyCustomer(Map<String, String> row) {
    String v(String key) {
      final value = row[key] ?? '';
      return value == '-' ? '' : value;
    }

    setState(() {
      _customerCode = v('Pref1');
      _name.text = v('Pref2').isEmpty ? _name.text : v('Pref2');
      if (v('Pref3').isNotEmpty) _birth = v('Pref3');
      if (v('Pref4').isNotEmpty) _religion = v('Pref4');
      if (v('Pref5').isNotEmpty) _address.text = v('Pref5');
      _phone.text = v('Pref6').isEmpty ? _phone.text : v('Pref6');
      if (v('Pref7').isNotEmpty) _phone2.text = v('Pref7');
      final top = v('Pref8');
      if (top == '1') {
        _payType = 'Cash';
      } else if (top == '0') {
        _payType = 'Credit';
      }
      if (v('Pref9').isNotEmpty) _spkNo = v('Pref9');
      _manual.text = v('Pref10');
      if (v('Pref11').isNotEmpty) _stnk.text = v('Pref11');
      if (v('Pref12').isNotEmpty) _npwp.text = v('Pref12');
      if (v('Pref14').isNotEmpty) _desc.text = v('Pref14');
      _faktur = v('Pref15') == '1';
      if (v('Pref16').isNotEmpty) _fakturName.text = v('Pref16');
      if (v('Pref17').isNotEmpty) {
        _dp.text = v('Pref17').replaceAll(RegExp(r'[^0-9]'), '');
      }
      if (v('Pref18').isNotEmpty) {
        _price.text = v('Pref18').replaceAll(RegExp(r'[^0-9]'), '');
      }
    });
  }

  Future<void> _reloadModels({String preferredModelCode = ''}) async {
    if (_brand == null || _type == null) return;
    final models = await context.read<MasterDataProvider>().getModels(
          brandCode: _brand!.code,
          typeCode: _type!.code,
        );
    if (!mounted) return;
    setState(() {
      _models = models;
      if (preferredModelCode.isNotEmpty) {
        _model =
            models.where((item) => item.code == preferredModelCode).firstOrNull ??
            (models.isEmpty ? null : models.first);
      } else {
        _model = models.isNotEmpty ? models.first : null;
      }
    });
  }

  Future<void> _reloadDistricts({
    String preferredCode = '',
    String preferredName = '',
  }) async {
    if (_city == null) return;
    final items = await context.read<MasterDataProvider>().getDistricts(
          provinceCode: _city!.provinceCode,
          cityCode: _city!.cityCode,
        );
    if (!mounted) return;
    setState(() {
      _districts = items;
      DistrictItem? match;
      if (preferredCode.isNotEmpty) {
        match = items.where((item) => item.districtCode == preferredCode).firstOrNull;
      }
      if (match == null && preferredName.isNotEmpty) {
        match = items.where((item) => item.districtName == preferredName).firstOrNull;
      }
      _district = match ?? (items.isNotEmpty ? items.first : null);
    });
  }

  String _stnkOrName() {
    final stnk = _stnk.text.trim();
    return stnk.isEmpty ? _name.text.trim() : stnk;
  }

  void _toggleFaktur(bool value) {
    setState(() {
      _faktur = value;
      if (value) {
        _fakturName.text = _stnkOrName();
      } else {
        _fakturName.clear();
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final isApprove = SpkListAction.isApproveAction(widget.action);
    if (isApprove) {
      final spkNo = _spkNo.isNotEmpty ? _spkNo : widget.row.spkNo;
      if (spkNo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SPK Number not found')),
        );
        return;
      }
      setState(() => _saving = true);
      final provider = context.read<SpkProvider>();
      final branch = widget.row.branchCode.isNotEmpty
          ? widget.row.branchCode
          : user.busCode;
      final success = await provider.createSPK({
        'prmIDNo': widget.row.idNo,
        'prmUserCreated': user.username,
        'prmHistoryID': widget.row.historyId,
        'prmBranchCode': branch,
        'prmSPKNo': spkNo,
        'prmAction': widget.action,
        'prmModelCode': 'XX',
        'prmBrandCode': '',
        'prmTypeCode': '',
        'prmColourCode': '',
        'prmQty': '1',
        'prmTOP': '',
        'prmTOP2': '',
        'prmMName': _name.text,
        'prmMAddress': '',
        'prmMPhone2': '',
        'prmMKTPNo': '',
        'prmMBirthDate': '1/1/1900',
        'prmMReligion': '',
        'prmMPIC': '',
        'prmMJobCode': '',
        'prmMLOBCode': '',
        'prmMUserLevel': user.userGroup,
        'prmSalesCode': user.salesCode,
        'prmMProvinceCode': '',
        'prmMCityCode': '',
        'prmMDistrictCode': '',
        'prmCustomerCode': '',
        'prmSPKManual': '',
        'prmSTNK': '',
        'prmNPWP': '',
        'prmDescription': '',
        'prmIsFaktur': '0',
        'prmFaktur': '',
        'prmDPInfo': '0',
        'prmSPKPrice': '0',
        'prmHPDate': _date,
        'prmSPKDate': _date,
        'prmFGOCContectId': '',
        'prmFGOCContectName': '',
        'prmFGOCContectPhone': '',
        'prmFGOCContectPosition': '',
        'prmActivityCode': '',
      });
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'SPK successfully approved'
                : provider.errorMessage.isEmpty
                ? 'Failed to approve SPK'
                : provider.errorMessage,
          ),
        ),
      );
      if (success) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill the blank field')),
      );
      return;
    }
    if (_ktp.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill KTP No')),
      );
      return;
    }
    if (_npwp.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill NPWP')),
      );
      return;
    }
    if (_price.text.trim().isEmpty ||
        _price.text.replaceAll(',', '').trim() == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill SPK Price')),
      );
      return;
    }
    if (_dp.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill DP')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.action == SpkListAction.create
              ? (widget.isFgoc ? 'SPK Company' : 'SPK Personal')
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
                AppAutoText<CityItem>(
                  key: ValueKey('spk-city-${_city?.cityCode ?? ''}'),
                  label: 'City',
                  value: _city,
                  items: _cities,
                  displayString: (item) => item.cityName,
                  prefixIcon: Icons.location_city_outlined,
                  onSelected: (item) {
                    setState(() {
                      _city = item;
                      _district = null;
                    });
                    _reloadDistricts();
                  },
                ),
                const SizedBox(height: 14),
                AppAutoText<DistrictItem>(
                  key: ValueKey(
                    'spk-district-${_city?.cityCode ?? ''}-${_district?.districtCode ?? ''}',
                  ),
                  label: 'District',
                  value: _district,
                  items: _districts,
                  displayString: (item) => item.districtName,
                  prefixIcon: Icons.map_outlined,
                  onSelected: (item) => setState(() => _district = item),
                ),
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
                  controller: _stnk,
                  label: 'STNK Name',
                  prefixIcon: Icons.directions_car_outlined,
                  onChanged: (_) {
                    if (_faktur) {
                      _fakturName.text = _stnkOrName();
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _npwp,
                  label: 'NPWP',
                  prefixIcon: Icons.receipt_long_outlined,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Is Faktur'),
                  value: _faktur,
                  onChanged: _toggleFaktur,
                ),
                AppTextField(
                  controller: _fakturName,
                  label: 'Faktur An',
                  readOnly: _faktur,
                  prefixIcon: Icons.assignment_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _price,
                  label: 'SPK Price',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  prefixIcon: Icons.payments_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _dp,
                  label: 'DP',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
