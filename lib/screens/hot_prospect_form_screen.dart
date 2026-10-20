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

  bool get isPersonal => row.idNo.isNotEmpty && row.idNo.startsWith('1');

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
    final tops = await master.getTOP();
    final lobs = await master.getLOB();
    if (!mounted) return;
    setState(() {
      _cities = cities;
      if (tops.isNotEmpty) _tops = tops;
      _lobs = lobs;
      _lob = lobs.isNotEmpty ? lobs.first : null;
      _city = cities.isNotEmpty ? cities.first : null;
    });
    await _reloadDistricts();
    if (!mounted || user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final rows = await context.read<ProspectProvider>().getCustomer(
          branchCode: user.historyBranch,
          idNo: widget.row.idNo,
        );
    if (mounted && rows.isNotEmpty) _applyCustomer(rows.first);
    if (mounted) setState(() => _loading = false);
  }

  void _applyCustomer(Map<String, String> row) {
    String v(String key) {
      final value = row[key] ?? '';
      return value == '-' ? '' : value;
    }

    final cityName = v('Pref8');
    final districtName = v('Pref9');
    final top = v('Pref10');
    setState(() {
      _name.text = v('Pref2').isEmpty ? _name.text : v('Pref2');
      if (v('Pref3').isNotEmpty) _birth = v('Pref3');
      _address.text = v('Pref5');
      _phone.text = v('Pref6').isEmpty ? _phone.text : v('Pref6');
      _phone2.text = v('Pref7');
      if (top.isNotEmpty) {
        final match = _tops.where((item) => item.code == top || item.name == top);
        if (match.isNotEmpty) _top = match.first.code;
      }
      if (cityName.isNotEmpty) {
        _city = _cities.where((item) => item.cityName == cityName).firstOrNull ?? _city;
      }
    });
    _reloadDistricts(preferredName: districtName);
  }

  Future<void> _reloadDistricts({String preferredName = ''}) async {
    if (_city == null) return;
    final items = await context.read<MasterDataProvider>().getDistricts(
          provinceCode: _city!.provinceCode,
          cityCode: _city!.cityCode,
        );
    if (!mounted) return;
    setState(() {
      _districts = items;
      _district = preferredName.isEmpty
          ? (items.isNotEmpty ? items.first : null)
          : items.where((item) => item.districtName == preferredName).firstOrNull ??
              (items.isNotEmpty ? items.first : null);
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
        title: Text(widget.isPersonal ? 'Data Personal' : 'Data Company'),
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
                          child: Text(item.districtName, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (item) => setState(() => _district = item),
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
