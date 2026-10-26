import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/code_name.dart';
import '../models/history_unit.dart';
import '../models/hot_prospect_payload.dart';
import '../providers/auth_provider.dart';
import '../providers/master_data_provider.dart';
import '../providers/prospect_provider.dart';
import '../services/database_service.dart';
import '../widgets/app_widgets.dart';

class HistoryUnitFormScreen extends StatefulWidget {
  const HistoryUnitFormScreen({super.key, this.initial, this.hotProspect});

  final HistoryUnit? initial;
  final HotProspectPayload? hotProspect;

  @override
  State<HistoryUnitFormScreen> createState() => _HistoryUnitFormScreenState();
}

class _HistoryUnitFormScreenState extends State<HistoryUnitFormScreen> {
  final _qty = TextEditingController(text: '1');
  List<CodeName> _brands = [];
  List<CodeName> _types = [];
  List<CodeName> _models = [];
  List<CodeName> _colors = [];
  List<CodeName> _activities = [];
  List<CodeName> _subActivities = [];
  List<CodeName> _fleets = [];
  List<CityItem> _cities = [];
  List<DistrictItem> _districts = [];
  CodeName? _brand;
  CodeName? _type;
  CodeName? _model;
  CodeName? _color;
  CodeName? _activity;
  CodeName? _subActivity;
  CodeName? _fleet;
  CityItem? _city;
  DistrictItem? _district;
  HistoryUnit? _seed;
  bool _saving = false;

  bool get _isHotProspect => widget.hotProspect != null;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final q = widget.initial!.qty.trim();
      _qty.text = q.isEmpty ? '1' : q;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    HistoryUnit? initial = widget.initial;
    final hp = widget.hotProspect;
    if (hp != null) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        // Sama Android: KodeCabang = cabang login (bukan BranchAut pipe)
        final pref = await context.read<ProspectProvider>().getHistoryEdit(
              kodeCabang: user.busCode,
              idNo: hp.row.idNo,
              historyId: hp.row.historyId,
              userCreated: user.username,
            );
        final row = pref?.toRows(maxPref: 14).firstOrNull;
        if (row != null) {
          String c(String key) {
            final value = row[key] ?? '';
            return value == '-' ? '' : value;
          }
          var typeCode = c('Pref4');
          final brandCode = c('Pref3');
          final modelCode = c('Pref5');
          // Jika Type kosong dari API, cari dari master model lokal
          if (typeCode.isEmpty && brandCode.isNotEmpty && modelCode.isNotEmpty) {
            typeCode = await context.read<MasterDataProvider>().findTypeCodeForModel(
                      brandCode: brandCode,
                      modelCode: modelCode,
                    ) ??
                '';
          }
          initial = HistoryUnit(
            brandCode: brandCode,
            typeCode: typeCode,
            modelCode: modelCode,
            qty: c('Pref6').isEmpty ? '1' : c('Pref6'),
            colourCode: c('Pref7'),
            activityCode: c('Pref8'),
            provinceCode: c('Pref9').isNotEmpty ? c('Pref9') : hp.provinceCode,
            cityCode: c('Pref10').isNotEmpty ? c('Pref10') : hp.cityCode,
            districtCode: c('Pref11').isNotEmpty ? c('Pref11') : hp.districtCode,
            subActivityCode: c('Pref12'),
            fleetCode: c('Pref13'),
            actNumber: c('Pref14'),
          );
          _qty.text = initial.qty;
        } else {
          initial = HistoryUnit(
            qty: '1',
            provinceCode: hp.provinceCode,
            cityCode: hp.cityCode,
            districtCode: hp.districtCode,
          );
          _qty.text = '1';
        }
      }
    }
    await _loadMaster(initial);
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  Future<void> _loadMaster([HistoryUnit? seeded]) async {
    final master = context.read<MasterDataProvider>();
    final brands = await master.getBrands();
    final types = await master.getTypes();
    final colors = await master.getColors();
    final activities = await master.getActivities();
    final cities = await master.getCities();
    final fleets = await master.getFleet();
    if (!mounted) return;
    final initial = seeded ?? widget.initial;
    _seed = initial;
    final hasSeed = (initial?.brandCode ?? '').isNotEmpty ||
        (initial?.modelCode ?? '').isNotEmpty;
    setState(() {
      _brands = brands;
      _types = types;
      _colors = colors;
      _activities = activities;
      _cities = cities;
      _fleets = fleets;
      _brand = _pick(brands, initial?.brandCode) ??
          (hasSeed || brands.isEmpty ? null : brands.first);
      _type = _pick(types, initial?.typeCode) ??
          (hasSeed || types.isEmpty ? null : types.first);
      _color = _pick(colors, initial?.colourCode) ??
          (hasSeed || colors.isEmpty ? null : colors.first);
      _activity = _pick(activities, initial?.activityCode) ??
          (hasSeed || activities.isEmpty ? null : activities.first);
      _fleet = _pick(fleets, initial?.fleetCode) ??
          (fleets.isEmpty ? null : fleets.first);
      _city = cities.where((item) => item.cityCode == initial?.cityCode).firstOrNull ??
          cities
              .where((item) =>
                  item.provinceCode == initial?.provinceCode &&
                  (initial?.provinceCode ?? '').isNotEmpty)
              .firstOrNull ??
          (cities.isEmpty ? null : cities.first);
    });
    // Jika type belum ketemu tapi brand+model ada, resolve Type dari master
    if (_type == null &&
        (_seed?.brandCode ?? '').isNotEmpty &&
        (_seed?.modelCode ?? '').isNotEmpty) {
      final resolved = await context.read<MasterDataProvider>().findTypeCodeForModel(
            brandCode: _seed!.brandCode,
            modelCode: _seed!.modelCode,
          );
      if (resolved != null && mounted) {
        setState(() => _type = _pick(types, resolved));
      }
    }
    await _reloadModels();
    await _reloadSub();
    await _reloadDistricts();
  }

  CodeName? _pick(List<CodeName> items, String? code) {
    if (code == null || code.isEmpty) return null;
    for (final item in items) {
      if (item.code == code) return item;
    }
    return null;
  }

  Future<void> _reloadModels() async {
    if (_brand == null || _type == null) return;
    final models = await context.read<MasterDataProvider>().getModels(
          brandCode: _brand!.code,
          typeCode: _type!.code,
        );
    if (!mounted) return;
    final hasSeedModel = (_seed?.modelCode ?? '').isNotEmpty;
    setState(() {
      _models = models;
      _model = _pick(models, _seed?.modelCode) ??
          (hasSeedModel || models.isEmpty ? null : models.first);
    });
  }

  Future<void> _reloadSub() async {
    if (_activity == null) return;
    final items =
        await context.read<MasterDataProvider>().getSubActivities(_activity!.code);
    if (!mounted) return;
    setState(() {
      _subActivities = items;
      _subActivity = _pick(items, _seed?.subActivityCode) ??
          (items.isEmpty ? null : items.first);
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
      _district = items
              .where((item) => item.districtCode == _seed?.districtCode)
              .firstOrNull ??
          (items.isEmpty ? null : items.first);
    });
  }

  Future<void> _save() async {
    if (_qty.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill the blank field')),
      );
      return;
    }
    if ((_model?.code ?? '').length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Model')),
      );
      return;
    }
    setState(() => _saving = true);
    final unit = HistoryUnit(
      brandCode: _brand?.code ?? '',
      brandName: _brand?.name ?? '',
      typeCode: _type?.code ?? '',
      typeName: _type?.name ?? '',
      modelCode: _model?.code ?? '',
      modelName: _model?.name ?? '',
      colourCode: _color?.code ?? '',
      colourName: _color?.name ?? '',
      activityCode: _activity?.code ?? '',
      activityName: _activity?.name ?? '',
      qty: _qty.text.trim().isEmpty ? '1' : _qty.text.trim(),
      provinceCode: _city?.provinceCode ?? '',
      cityCode: _city?.cityCode ?? '',
      districtCode: _district?.districtCode ?? '',
      subActivityCode: _subActivity?.code ?? '',
      fleetType: _fleet?.name ?? '',
      fleetCode: _fleet?.code ?? '',
    );
    if (_isHotProspect) {
      await _uploadHotProspect(unit);
      return;
    }
    await DatabaseService().addHistoryUnit(unit);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _uploadHotProspect(HistoryUnit unit) async {
    final user = context.read<AuthProvider>().user;
    final hp = widget.hotProspect;
    if (user == null || hp == null) {
      setState(() => _saving = false);
      return;
    }
    final success = await context.read<ProspectProvider>().uploadStatusHP({
      'prmIDNo': hp.row.idNo,
      'prmUserCreated': user.username,
      'prmHistoryID': hp.row.historyId,
      'prmHPDate': hp.hpDate,
      'prmMName': hp.name,
      'prmMAddress': hp.address,
      'prmMPhone2': hp.phone2,
      'prmMKTPNo': '',
      'prmMBirthDate': hp.birthDate,
      'prmMReligion': hp.religion,
      'prmTOP': hp.top,
      'prmMPIC': hp.pic,
      'prmMJobCode': '',
      'prmMLOBCode': hp.lobCode,
      'prmMUserLevel': user.userGroup,
      'prmSalesCode': user.salesCode,
      'prmBranchCode': user.busCode,
      'prmBrandCode': unit.brandCode,
      'prmTypeCode': unit.typeCode,
      'prmModelCode': unit.modelCode,
      'prmQty': unit.qty,
      'prmColourCode': unit.colourCode,
      'prmActivityCode': unit.activityCode,
      'prmMProvinceCode': hp.provinceCode,
      'prmMCityCode': hp.cityCode,
      'prmMDistrictCode': hp.districtCode,
      'prmHPDesc': hp.hpDesc,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Data successfully saved' : 'Failed to save data'),
      ),
    );
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Unit')),
      body: AppLoadingOverlay(
        visible: _saving,
        message: 'Menyimpan...',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            AppCard(
              child: Column(
                children: [
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
                  AppTextField(
                    controller: _qty,
                    label: 'Qty',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.pin_outlined,
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<CodeName>(
                    label: 'Activity',
                    value: _activity,
                    items: _codeItems(_activities),
                    onChanged: (item) {
                      setState(() => _activity = item);
                      if (!_isHotProspect) _reloadSub();
                    },
                  ),
                  if (!_isHotProspect) ...[
                    const SizedBox(height: 14),
                    AppDropdown<CodeName>(
                      label: 'Sub Activity',
                      value: _subActivity,
                      items: _codeItems(_subActivities),
                      onChanged: (item) => setState(() => _subActivity = item),
                    ),
                    const SizedBox(height: 14),
                    AppAutoText<CityItem>(
                      key: ValueKey('unit-city-${_city?.cityCode ?? ''}'),
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
                        'unit-district-${_city?.cityCode ?? ''}-${_district?.districtCode ?? ''}',
                      ),
                      label: 'District',
                      value: _district,
                      items: _districts,
                      displayString: (item) => item.districtName,
                      prefixIcon: Icons.map_outlined,
                      onSelected: (item) => setState(() => _district = item),
                    ),
                    const SizedBox(height: 14),
                    AppDropdown<CodeName>(
                      label: 'Fleet Type',
                      value: _fleet,
                      items: _codeItems(_fleets),
                      onChanged: (item) => setState(() => _fleet = item),
                    ),
                  ],
                  const SizedBox(height: 22),
                  AppPrimaryButton(
                    label: 'Save',
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
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
