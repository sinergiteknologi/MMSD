import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/code_name.dart';
import '../models/prospect_draft.dart';
import '../providers/auth_provider.dart';
import '../providers/master_data_provider.dart';
import '../providers/prospect_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'history_unit_list_screen.dart';

class ProspectFormScreen extends StatefulWidget {
  const ProspectFormScreen({super.key});

  @override
  State<ProspectFormScreen> createState() => _ProspectFormScreenState();
}

class _FoundCustomer {
  const _FoundCustomer({
    required this.id,
    required this.phone,
    required this.name,
    required this.phone2,
    required this.city,
    required this.district,
  });

  final String id;
  final String phone;
  final String name;
  final String phone2;
  final String city;
  final String district;

  factory _FoundCustomer.fromPref(Map<String, String> row) {
    return _FoundCustomer(
      id: row['Pref1'] ?? '',
      phone: row['Pref2'] ?? '',
      name: row['Pref3'] ?? '',
      phone2: row['Pref5'] ?? '',
      city: row['Pref6'] ?? '',
      district: row['Pref7'] ?? '',
    );
  }

  bool get isValid => id.trim().isNotEmpty;
}

class _ProspectFormScreenState extends State<ProspectFormScreen> {
  final _find = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _phone2 = TextEditingController();
  final _idNo = TextEditingController();
  final _fgocName = TextEditingController();
  final _fgocPhone = TextEditingController();
  final _fgocPosition = TextEditingController();
  bool _company = false;
  bool _saving = false;
  bool _finding = false;
  bool _searched = false;
  bool _showForm = false;
  bool _fgocFinding = false;
  bool _fgocSearched = false;
  bool _fgocShowForm = false;
  List<_FoundCustomer> _customers = [];
  List<Map<String, String>> _fgocHits = [];
  String _selectedId = '';
  String _fgocId = '';
  List<CityItem> _cities = [];
  CityItem? _city;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DatabaseService().clearTable('HISTORYUNIT');
      if (!mounted) return;
      final cities = await context.read<MasterDataProvider>().getCities();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _city = cities.isNotEmpty ? cities.first : null;
      });
    });
  }

  @override
  void dispose() {
    _find.dispose();
    _name.dispose();
    _phone.dispose();
    _phone2.dispose();
    _idNo.dispose();
    _fgocName.dispose();
    _fgocPhone.dispose();
    _fgocPosition.dispose();
    super.dispose();
  }

  Future<void> _findCustomer() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final query = _find.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _finding = true;
      _searched = false;
      _showForm = false;
      _customers = [];
      _selectedId = '';
      _idNo.clear();
      _name.clear();
      _phone.clear();
      _phone2.clear();
    });
    final rows = await context.read<ProspectProvider>().findProspect2(
          filterTlp: query,
          filterId: '',
          user: user.username,
        );
    if (!mounted) return;
    final found = rows
        .map(_FoundCustomer.fromPref)
        .where((item) => item.isValid)
        .toList();
    setState(() {
      _finding = false;
      _searched = true;
      _customers = found;
      if (found.isEmpty) {
        _showForm = true;
        _phone.text = query;
      }
    });
  }

  Future<void> _searchFGOC() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _fgocName.text.trim().isEmpty) return;
    setState(() {
      _fgocFinding = true;
      _fgocSearched = false;
      _fgocShowForm = false;
      _fgocHits = [];
      _fgocId = '';
      _fgocPhone.clear();
      _fgocPosition.clear();
    });
    final rows = await context.read<MasterDataProvider>().searchFGOC(
          branchCode: user.busCode,
          like: _fgocName.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _fgocFinding = false;
      _fgocSearched = true;
      _fgocHits = rows;
      if (rows.isEmpty) _fgocShowForm = true;
    });
  }

  void _selectFGOC(Map<String, String> row) {
    setState(() {
      _fgocId = row['Pref1'] ?? '';
      _fgocName.text = row['Pref2'] ?? _fgocName.text;
      _fgocPhone.text = row['Pref3'] ?? _fgocPhone.text;
      _fgocPosition.text = row['Pref4'] ?? _fgocPosition.text;
      _fgocHits = [];
      _fgocShowForm = true;
    });
  }

  void _onFGOCNameChanged(String _) {
    if (_fgocId.isEmpty &&
        !_fgocSearched &&
        _fgocHits.isEmpty &&
        !_fgocShowForm) {
      return;
    }
    setState(() {
      _fgocId = '';
      _fgocHits = [];
      _fgocSearched = false;
      _fgocShowForm = false;
      _fgocPhone.clear();
      _fgocPosition.clear();
    });
  }

  Future<void> _selectCustomer(_FoundCustomer customer) async {
    setState(() {
      _showForm = true;
      _selectedId = customer.id;
      _idNo.text = customer.id;
      _name.text = customer.name;
      _phone.text = customer.phone;
      _phone2.text = customer.phone2;
    });
    final cityName = customer.city.trim();
    if (cityName.isEmpty || cityName == '-') return;
    for (final item in _cities) {
      if (item.cityName.toLowerCase() == cityName.toLowerCase()) {
        setState(() => _city = item);
        break;
      }
    }
  }

  Future<void> _next() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    if (_company) {
      if (_fgocId.isEmpty && !_fgocSearched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cari FGOC terlebih dahulu')),
        );
        return;
      }
      if (_fgocName.text.trim().isEmpty ||
          _fgocPhone.text.trim().isEmpty ||
          _fgocPosition.text.trim().isEmpty ||
          _city == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi FGOC Name, Phone, Position, dan City'),
          ),
        );
        return;
      }
      if (_fgocId.isEmpty) {
        final exists = await context.read<ProspectProvider>().checkPhoneFGOC(
              tlp: _fgocPhone.text,
              user: user.username,
            );
        if (!mounted) return;
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number already exists')),
          );
          return;
        }
      }
    } else {
      if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill name and phone')),
        );
        return;
      }
      if (_selectedId.isEmpty) {
        final exists = await context.read<ProspectProvider>().checkPhone(
              tlp: _phone.text,
              user: user.username,
            );
        if (!mounted) return;
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number already exists')),
          );
          return;
        }
      }
    }
    if (!mounted) return;
    setState(() => _saving = true);
    await DatabaseService().clearTable('HISTORYUNIT');
    if (!mounted) return;
    setState(() => _saving = false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryUnitListScreen(
          draft: ProspectDraft(
            company: _company,
            name: _company ? _fgocName.text : _name.text,
            phone: _company ? _fgocPhone.text : _phone.text,
            phone2: _phone2.text,
            idNo: _idNo.text,
            provinceCode: _city?.provinceCode ?? '',
            cityCode: _city?.cityCode ?? '',
            fgocId: _fgocId,
            fgocName: _fgocName.text,
            fgocPhone: _fgocPhone.text,
            fgocPosition: _fgocPosition.text,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prospect')),
      body: AppLoadingOverlay(
        visible: _finding || _fgocFinding || _saving,
        message: _fgocFinding
            ? 'Mencari FGOC...'
            : _finding
                ? 'Mencari customer...'
                : 'Menyimpan...',
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer', style: Theme.of(context).textTheme.titleLarge),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Company / FGOC'),
                  value: _company,
                  onChanged: (value) {
                    setState(() {
                      _company = value;
                      _searched = false;
                      _showForm = false;
                      _customers = [];
                      _selectedId = '';
                      _fgocSearched = false;
                      _fgocShowForm = false;
                      _fgocHits = [];
                      _fgocId = '';
                    });
                  },
                ),
                if (!_company) ...[
                  AppTextField(
                    controller: _find,
                    label: 'Find Phone',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.search,
                  ),
                  const SizedBox(height: 10),
                  AppPrimaryButton(
                    label: _finding ? 'Finding...' : 'Find Customer',
                    loading: _finding,
                    onPressed: _findCustomer,
                  ),
                  if (_searched && _customers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih customer',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ..._customers.map((customer) {
                      final selected = _selectedId == customer.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: selected
                              ? const Color(0xFFE8F0E9)
                              : const Color(0xFFF6F1E8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.navy
                                  : AppColors.line,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            title: Text(customer.name),
                            subtitle: Text(
                              '${customer.phone}  •  ${customer.id}',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _selectCustomer(customer),
                          ),
                        ),
                      );
                    }),
                  ],
                  if (_showForm) ...[
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _name,
                      label: 'Name',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _phone,
                      label: 'Phone',
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
                    if (_selectedId.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _idNo,
                        label: 'ID No',
                        prefixIcon: Icons.credit_card_outlined,
                        readOnly: true,
                      ),
                    ],
                  ],
                ] else ...[
                  AppTextField(
                    controller: _fgocName,
                    label: 'FGOC Name',
                    prefixIcon: Icons.apartment_outlined,
                    onChanged: _onFGOCNameChanged,
                  ),
                  const SizedBox(height: 10),
                  AppPrimaryButton(
                    label: _fgocFinding ? 'Mencari...' : 'Cari FGOC',
                    loading: _fgocFinding,
                    onPressed: _searchFGOC,
                  ),
                  if (_fgocSearched && _fgocHits.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih FGOC',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ..._fgocHits.map((row) {
                      final selected = _fgocId == (row['Pref1'] ?? '');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: selected
                              ? const Color(0xFFE8F0E9)
                              : const Color(0xFFF6F1E8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.navy
                                  : AppColors.line,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            title: Text(row['Pref2'] ?? ''),
                            subtitle: Text(row['Pref1'] ?? ''),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _selectFGOC(row),
                          ),
                        ),
                      );
                    }),
                  ],
                  if (_fgocSearched &&
                      _fgocHits.isEmpty &&
                      _fgocShowForm) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'FGOC tidak ditemukan. Lengkapi data di bawah untuk membuat prospect FGOC baru tanpa ID.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                  if (_fgocShowForm) ...[
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
                      label: 'Position',
                      prefixIcon: Icons.work_outline,
                    ),
                  ],
                ],
                if (_company ? _fgocShowForm : _showForm) ...[
                  const SizedBox(height: 14),
                  AppDropdown<CityItem>(
                    label: 'City',
                    value: _city,
                    items: _cities
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              item.cityName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (item) => setState(() => _city = item),
                  ),
                  const SizedBox(height: 22),
                  AppPrimaryButton(
                    label: 'Lanjut Unit',
                    loading: _saving,
                    onPressed: _next,
                  ),
                ],
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
