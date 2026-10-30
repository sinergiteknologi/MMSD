import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/code_name.dart';
import '../models/history_row.dart';
import '../models/hot_prospect_payload.dart';
import '../providers/auth_provider.dart';
import '../providers/master_data_provider.dart';
import '../providers/prospect_provider.dart';
import '../utils/date_format.dart';
import '../widgets/app_widgets.dart';
import 'history_unit_form_screen.dart';

class HotProspectFormScreen extends StatefulWidget {
  const HotProspectFormScreen({
    super.key,
    required this.row,
    required this.hpDate,
    this.hpDesc = '',
  });

  final HistoryRow row;
  final String hpDate;
  final String hpDesc;

  // Digit 1 IDNo = Personal, selain itu (2.x) = FGOC
  bool get isPersonal => row.idNo.isNotEmpty && row.idNo.startsWith('1');
  bool get isFgoc => row.idNo.isNotEmpty && row.idNo.startsWith('2');

  @override
  State<HotProspectFormScreen> createState() => _HotProspectFormScreenState();
}

class _HotProspectFormScreenState extends State<HotProspectFormScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _phone2 = TextEditingController();
  final _address = TextEditingController();
  final _pic = TextEditingController();
  String _birth = '';
  String _top = 'Cash';
  List<CodeName> _tops = const [
    CodeName(code: 'Cash', name: 'Cash'),
    CodeName(code: 'Credit', name: 'Credit'),
  ];
  List<CodeName> _lobs = [];
  List<CityItem> _cities = [];
  List<DistrictItem> _districts = [];
  CodeName? _lob;
  CityItem? _city;
  DistrictItem? _district;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _name.text = widget.row.name;
    _phone.text = widget.row.phone;
    _pic.text = widget.row.pic;
    _birth = AppDateFormat.mdy(DateTime(DateTime.now().year, DateTime.now().month, 1));
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _phone2.dispose();
    _address.dispose();
    _pic.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final user = context.read<AuthProvider>().user;
    final master = context.read<MasterDataProvider>();
    final cities = await master.getCities();
    final lobs = await master.getLOB();
    if (!mounted) return;
    setState(() {
      _cities = cities;
      _lobs = lobs;
      _lob = null;
      _city = null;
      _district = null;
      _districts = [];
    });
    if (!mounted || user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final prospect = context.read<ProspectProvider>();
    // Query beda Personal (1.x) vs FGOC (2.x) di API berdasarkan digit pertama IDNo
    final prospectRows = await prospect.findProspect2(
      filterTlp: '',
      filterId: widget.row.idNo,
      user: user.username,
      historyId: widget.row.historyId,
    );
    if (mounted && prospectRows.isNotEmpty) {
      await _applyProspect(prospectRows.first);
    }
    // Overlay dari master customer jika sudah ada (setelah SPK)
    final custRows = await prospect.getCustomer(
      branchCode: user.busCode,
      idNo: widget.row.idNo,
    );
    if (mounted && custRows.isNotEmpty) await _applyCustomer(custRows.first);
    if (mounted) setState(() => _loading = false);
  }

  String _v(Map<String, String> row, String key) {
    final value = row[key] ?? '';
    return value == '-' ? '' : value;
  }

  CityItem? _matchCity({
    String provinceCode = '',
    String cityCode = '',
    String cityName = '',
  }) {
    if (cityCode.isNotEmpty) {
      final byCode = _cities.where((item) {
        if (item.cityCode != cityCode) return false;
        if (provinceCode.isNotEmpty && item.provinceCode != provinceCode) {
          return false;
        }
        return true;
      });
      final match = byCode.firstOrNull;
      if (match != null) return match;
    }
    if (cityName.isNotEmpty) {
      return _cities.where((item) => item.cityName == cityName).firstOrNull;
    }
    return null;
  }

  bool _codeEq(String a, String b) {
    final x = a.trim();
    final y = b.trim();
    if (x.isEmpty || y.isEmpty) return false;
    if (x == y) return true;
    final nx = int.tryParse(x);
    final ny = int.tryParse(y);
    return nx != null && ny != null && nx == ny;
  }

  Future<void> _applyProspect(Map<String, String> row) async {
    final provinceCode = _v(row, 'Pref16');
    final cityCode = _v(row, 'Pref17');
    final cityName = _v(row, 'Pref6');
    final districtCode = _v(row, 'Pref18');
    final districtName = _v(row, 'Pref7');
    final lobCode = _v(row, 'Pref19');
    final lobName = _v(row, 'Pref11');
    final matchedCity = _matchCity(
      provinceCode: provinceCode,
      cityCode: cityCode,
      cityName: cityName,
    );
    setState(() {
      _name.text = _v(row, 'Pref3').isEmpty ? _name.text : _v(row, 'Pref3');
      _phone.text = _v(row, 'Pref2').isEmpty ? _phone.text : _v(row, 'Pref2');
      _phone2.text = _v(row, 'Pref5');
      // Pref4 = CRM_M_Prospect.Address saja (jangan ambil CityName/dll)
      final addr = _v(row, 'Pref4');
      if (addr.isNotEmpty && !addr.contains(',')) {
        _address.text = addr;
      }
      if (_v(row, 'Pref8').isNotEmpty && _v(row, 'Pref8') != '01/01/1900') {
        _birth = _v(row, 'Pref8');
      }
      if (_v(row, 'Pref10').isNotEmpty) _pic.text = _v(row, 'Pref10');
      if (lobCode.isNotEmpty) {
        _lob = _lobs.where((item) => item.code == lobCode).firstOrNull ?? _lob;
      } else if (lobName.isNotEmpty) {
        _lob = _lobs.where((item) => item.name == lobName).firstOrNull ?? _lob;
      }
      if (matchedCity != null) _city = matchedCity;
    });
    await _reloadDistricts(
      preferredName: districtName,
      preferredCode: districtCode,
      provinceCode: matchedCity?.provinceCode ?? provinceCode,
      cityCode: matchedCity?.cityCode ?? cityCode,
    );
  }

  Future<void> _applyCustomer(Map<String, String> row) async {
    final cityName = _v(row, 'Pref8');
    final districtName = _v(row, 'Pref9');
    final top = _v(row, 'Pref10');
    // Jangan overwrite kota/district dari ProspectHistory
    final keepCity = _city != null;
    setState(() {
      _name.text = _v(row, 'Pref2').isEmpty ? _name.text : _v(row, 'Pref2');
      if (_v(row, 'Pref3').isNotEmpty) _birth = _v(row, 'Pref3');
      if (_v(row, 'Pref5').isNotEmpty) _address.text = _v(row, 'Pref5');
      _phone.text = _v(row, 'Pref6').isEmpty ? _phone.text : _v(row, 'Pref6');
      if (_v(row, 'Pref7').isNotEmpty) _phone2.text = _v(row, 'Pref7');
      if (top == 'Cash' || top == 'Credit') _top = top;
      if (!keepCity && cityName.isNotEmpty) {
        _city = _matchCity(cityName: cityName) ?? _city;
      }
    });
    if (!keepCity) {
      await _reloadDistricts(preferredName: districtName);
    }
  }

  Future<void> _reloadDistricts({
    String preferredName = '',
    String preferredCode = '',
    String provinceCode = '',
    String cityCode = '',
  }) async {
    final prov = provinceCode.isNotEmpty
        ? provinceCode
        : (_city?.provinceCode ?? '');
    final city = cityCode.isNotEmpty ? cityCode : (_city?.cityCode ?? '');
    if (prov.isEmpty || city.isEmpty) return;
    final items = await context.read<MasterDataProvider>().getDistricts(
          provinceCode: prov,
          cityCode: city,
        );
    if (!mounted) return;
    setState(() {
      _districts = items;
      DistrictItem? match;
      if (preferredCode.isNotEmpty) {
        match = items
            .where((item) => _codeEq(item.districtCode, preferredCode))
            .firstOrNull;
      }
      if (match == null && preferredName.isNotEmpty) {
        final want = preferredName.trim().toLowerCase();
        match = items
            .where((item) => item.districtName.trim().toLowerCase() == want)
            .firstOrNull;
      }
      // Jangan fallback ke items.first jika ada preferred — biar tidak salah district
      if (match != null) {
        _district = match;
      } else if (preferredCode.isEmpty && preferredName.isEmpty) {
        _district = items.isNotEmpty ? items.first : null;
      } else {
        _district = null;
      }
    });
  }

  void _next() {
    if (_top == '-' || _top.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isPersonal ? 'Please PY Type' : 'Please fill TOP')),
      );
      return;
    }
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill the blank field')),
      );
      return;
    }
    if (!widget.isPersonal && _pic.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill the blank field')),
      );
      return;
    }
    if (_city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid city')),
      );
      return;
    }
    if (_district == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid district')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryUnitFormScreen(
          hotProspect: HotProspectPayload(
            row: widget.row,
            hpDate: widget.hpDate,
            hpDesc: widget.hpDesc,
            name: _name.text,
            address: _address.text,
            phone2: _phone2.text,
            birthDate: _birth,
            top: _top,
            pic: _pic.text,
            lobCode: _lob?.code ?? '',
            provinceCode: _city!.provinceCode,
            cityCode: _city!.cityCode,
            districtCode: _district!.districtCode,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: AppLoading(message: 'Memuat data customer...'));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFgoc ? 'Data Company' : 'Data Personal'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  controller: _name,
                  label: 'Name',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phone,
                  label: 'Phone',
                  readOnly: true,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phone2,
                  label: 'Phone 2',
                  prefixIcon: Icons.phone_android_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _address,
                  label: 'Address',
                  prefixIcon: Icons.home_outlined,
                ),
                if (!widget.isPersonal) ...[
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _pic,
                    label: 'PIC',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),
                  AppDropdown<CodeName>(
                    label: 'LOB',
                    value: _lob,
                    items: _lobs
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (item) => setState(() => _lob = item),
                  ),
                ],
                const SizedBox(height: 14),
                AppDropdown<String>(
                  label: 'PY Type',
                  value: _tops.any((item) => item.code == _top) ? _top : null,
                  items: _tops
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.code,
                          child: Text(item.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _top = value ?? ''),
                ),
                const SizedBox(height: 14),
                AppDateField(
                  label: 'Birth Date',
                  value: _birth,
                  onPicked: (date) => setState(() => _birth = AppDateFormat.mdy(date)),
                ),
                const SizedBox(height: 14),
                AppAutoText<CityItem>(
                  key: ValueKey(
                    'hp-city-${_city?.provinceCode ?? ''}-${_city?.cityCode ?? ''}',
                  ),
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
                    _reloadDistricts(
                      provinceCode: item.provinceCode,
                      cityCode: item.cityCode,
                    );
                  },
                ),
                const SizedBox(height: 14),
                AppAutoText<DistrictItem>(
                  key: ValueKey(
                    'hp-district-${_city?.provinceCode ?? ''}-${_city?.cityCode ?? ''}-${_district?.districtCode ?? ''}',
                  ),
                  label: 'District',
                  value: _district,
                  items: _districts,
                  displayString: (item) => item.districtName,
                  prefixIcon: Icons.map_outlined,
                  onSelected: (item) => setState(() => _district = item),
                ),
                const SizedBox(height: 22),
                AppPrimaryButton(label: 'Lanjut Unit', onPressed: _next),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
