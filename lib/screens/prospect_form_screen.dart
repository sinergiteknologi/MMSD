import 'dart:async';

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
  final _fgocPicName = TextEditingController();
  final _fgocPhone = TextEditingController();
  final _fgocPosition = TextEditingController();
  bool _company = false;
  bool _saving = false;
  bool _finding = false;
  bool _searched = false;
  bool _showForm = false;
  bool _fgocFinding = false;
  bool _fgocDropdownOpen = false;
  bool _fgocSearched = false;
  bool _fgocApplying = false;
  bool _picFinding = false;
  bool _picDropdownOpen = false;
  bool _picLocked = false;
  List<_FoundCustomer> _customers = [];
  List<Map<String, String>> _fgocHits = [];
  List<Map<String, String>> _picHits = [];
  List<CodeName> _fgocTypes = [];
  CodeName? _fgocType;
  String _selectedId = '';
  String _fgocCode = '';
  String _fgocDesc = '';
  String _fgocContactId = '';
  List<CityItem> _cities = [];
  CityItem? _city;
  Timer? _fgocDebounce;
  Timer? _picDebounce;
  int _fgocRequestId = 0;
  int _picRequestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DatabaseService().clearTable('HISTORYUNIT');
      if (!mounted) return;
      final master = context.read<MasterDataProvider>();
      final cities = await master.getCities();
      final fleets = await master.getFleet();
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _city = cities.isNotEmpty ? cities.first : null;
        _fgocTypes = fleets;
        _fgocType = fleets.isNotEmpty ? fleets.first : null;
      });
    });
  }

  @override
  void dispose() {
    _fgocDebounce?.cancel();
    _picDebounce?.cancel();
    _find.dispose();
    _name.dispose();
    _phone.dispose();
    _phone2.dispose();
    _idNo.dispose();
    _fgocName.dispose();
    _fgocPicName.dispose();
    _fgocPhone.dispose();
    _fgocPosition.dispose();
    super.dispose();
  }

  void _clearFGOCSelection({bool keepName = false}) {
    _fgocCode = '';
    _fgocDesc = '';
    _fgocContactId = '';
    _fgocHits = [];
    _picHits = [];
    _fgocDropdownOpen = false;
    _fgocSearched = false;
    _picDropdownOpen = false;
    _picLocked = false;
    if (!keepName) _fgocName.clear();
    _fgocPicName.clear();
    _fgocPhone.clear();
    _fgocPosition.clear();
  }

  void _onFGOCNameChanged(String value) {
    if (_fgocApplying) return;
    _fgocDebounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _fgocFinding = false;
        _fgocDropdownOpen = false;
        _fgocSearched = false;
        _fgocHits = [];
        _fgocCode = '';
        _fgocDesc = '';
        _fgocContactId = '';
        _picHits = [];
        _picLocked = false;
        _fgocPicName.clear();
        _fgocPhone.clear();
        _fgocPosition.clear();
      });
      return;
    }
    if (_fgocCode.isNotEmpty ||
        _fgocContactId.isNotEmpty ||
        _fgocPicName.text.isNotEmpty ||
        _fgocPhone.text.isNotEmpty ||
        _fgocPosition.text.isNotEmpty) {
      setState(() {
        _fgocCode = '';
        _fgocDesc = '';
        _fgocContactId = '';
        _picHits = [];
        _picLocked = false;
        _fgocPicName.clear();
        _fgocPhone.clear();
        _fgocPosition.clear();
      });
    }
    
    setState(() {
      _fgocFinding = true;
      _fgocDropdownOpen = true;
      _fgocSearched = false;
      _fgocHits = [];
    });
    _fgocDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchFGOC(query);
    });
  }

  Future<void> _searchFGOC(String query) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final requestId = ++_fgocRequestId;
    final rows = await context.read<MasterDataProvider>().searchFGOC(
          branchCode: user.busCode,
          like: query,
        );
    if (!mounted || requestId != _fgocRequestId) return;
    if (_fgocName.text.trim() != query) return;
    setState(() {
      _fgocFinding = false;
      _fgocSearched = true;
      _fgocDropdownOpen = true;
      _fgocHits = rows;
    });
  }

  Future<void> _selectFGOC(Map<String, String> row) async {
    _fgocApplying = true;
    final cityName = (row['Pref6'] ?? '').trim();
    CityItem? matchedCity;
    if (cityName.isNotEmpty && cityName != '-') {
      for (final item in _cities) {
        if (item.cityName.toLowerCase() == cityName.toLowerCase()) {
          matchedCity = item;
          break;
        }
      }
    }
    setState(() {
      _fgocCode = row['Pref1'] ?? '';
      _fgocDesc = row['Pref3'] ?? '';
      _fgocName.text = row['Pref2'] ?? _fgocName.text;
      _fgocPhone.text = row['Pref5'] ?? '';
      _fgocHits = [];
      _fgocDropdownOpen = false;
      _fgocSearched = false;
      _fgocFinding = false;
      _fgocContactId = '';
      _picLocked = false;
      _fgocPicName.clear();
      _fgocPosition.clear();
      _picHits = [];
      if (matchedCity != null) _city = matchedCity;
    });
    _fgocApplying = false;
    await _loadPicContacts();
  }

  Future<void> _loadPicContacts({String like = ''}) async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _fgocCode.isEmpty) return;
    final requestId = ++_picRequestId;
    setState(() {
      _picFinding = true;
      _picDropdownOpen = true;
    });
    final rows = await context.read<MasterDataProvider>().getFGOCContact(
          branchCode: user.busCode,
          custCode: _fgocCode,
        );
    if (!mounted || requestId != _picRequestId) return;
    final filtered = like.trim().isEmpty
        ? rows
        : rows.where((row) {
            final name = (row['Pref3'] ?? '').toLowerCase();
            return name.contains(like.trim().toLowerCase());
          }).toList();
    setState(() {
      _picFinding = false;
      _picHits = filtered;
      _picDropdownOpen = true;
      if (like.isEmpty && filtered.length == 1) {
        _applyPic(filtered.first);
      }
    });
  }

  void _onPicNameChanged(String value) {
    if (_picLocked || _fgocApplying) return;
    _picDebounce?.cancel();
    if (_fgocCode.isEmpty) return;
    setState(() {
      _fgocContactId = '';
      _picDropdownOpen = true;
      _picFinding = true;
    });
    _picDebounce = Timer(const Duration(milliseconds: 300), () {
      _loadPicContacts(like: value);
    });
  }

  void _applyPic(Map<String, String> row) {
    _fgocApplying = true;
    setState(() {
      _fgocContactId = row['Pref1'] ?? '';
      _fgocPicName.text = row['Pref3'] ?? '';
      _fgocPhone.text = row['Pref4'] ?? _fgocPhone.text;
      _fgocPosition.text = row['Pref5'] ?? '';
      _picHits = [];
      _picDropdownOpen = false;
      _picFinding = false;
      _picLocked = true;
    });
    _fgocApplying = false;
  }

  void _clearPic() {
    setState(() {
      _fgocContactId = '';
      _fgocPicName.clear();
      _fgocPhone.clear();
      _fgocPosition.clear();
      _picLocked = false;
      _picHits = [];
      _picDropdownOpen = false;
    });
    if (_fgocCode.isNotEmpty) _loadPicContacts();
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
      if (_fgocName.text.trim().isEmpty ||
          _fgocPicName.text.trim().isEmpty ||
          _fgocPhone.text.trim().isEmpty ||
          _fgocType == null ||
          _city == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill the blank field')),
        );
        return;
      }
      if (_fgocContactId.isEmpty) {
        final exists = await context.read<ProspectProvider>().checkPhoneFGOC(
              tlp: _fgocPhone.text,
              user: user.username,
            );
        if (!mounted) return;
        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone Number already exist !')),
          );
          return;
        }
      }
    } else {
      if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill the blank field')),
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
            const SnackBar(content: Text('Phone Number already exist !')),
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
            name: _company ? _fgocName.text.trim() : _name.text.trim(),
            phone: _company ? _fgocPhone.text.trim() : _phone.text.trim(),
            phone2: _company ? '' : _phone2.text.trim(),
            idNo: _company ? _fgocDesc : _idNo.text.trim(),
            provinceCode: _city?.provinceCode ?? '',
            cityCode: _city?.cityCode ?? '',
            fgocCode: _company ? _fgocCode : '',
            fgocDesc: _company ? _fgocDesc : '',
            fgocType: _company ? (_fgocType?.name ?? '') : '',
            fgocContactId: _company ? _fgocContactId : '',
            fgocName: _company ? _fgocPicName.text.trim() : '',
            fgocPhone: _company ? _fgocPhone.text.trim() : '',
            fgocPosition: _company ? _fgocPosition.text.trim() : '',
          ),
        ),
      ),
    );
  }

  Widget _suggestionBox({
    required bool visible,
    required bool loading,
    required bool searched,
    required List<Widget> items,
    String emptyText = 'Tidak ditemukan. Lanjut isi manual.',
  }) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            )
          : searched && items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    emptyText,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: items,
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prospect')),
      body: AppLoadingOverlay(
        visible: _finding || _saving,
        message: _finding ? 'Mencari customer...' : 'Menyimpan...',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prospect Type',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Personal'),
                        selected: !_company,
                        onSelected: (_) {
                          setState(() {
                            _company = false;
                            _searched = false;
                            _showForm = false;
                            _customers = [];
                            _selectedId = '';
                            _clearFGOCSelection();
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('FGOC'),
                        selected: _company,
                        onSelected: (_) {
                          setState(() {
                            _company = true;
                            _searched = false;
                            _showForm = false;
                            _customers = [];
                            _selectedId = '';
                            _name.clear();
                            _phone.clear();
                            _phone2.clear();
                            _idNo.clear();
                            _clearFGOCSelection();
                          });
                        },
                      ),
                    ],
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
                              trailing:
                                  const Icon(Icons.chevron_right_rounded),
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
                        label: 'No Phone',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _phone2,
                        label: 'No Phone 2',
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
                      suffix: IconButton(
                        onPressed: () => setState(_clearFGOCSelection),
                        icon: const Icon(Icons.clear, size: 18),
                      ),
                    ),
                    _suggestionBox(
                      visible: _fgocDropdownOpen,
                      loading: _fgocFinding,
                      searched: _fgocSearched,
                      items: _fgocHits
                          .map(
                            (row) => ListTile(
                              dense: true,
                              title: Text(row['Pref2'] ?? ''),
                              subtitle: Text(
                                [
                                  if ((row['Pref5'] ?? '').isNotEmpty)
                                    row['Pref5'],
                                  if ((row['Pref6'] ?? '').isNotEmpty)
                                    row['Pref6'],
                                  if ((row['Pref3'] ?? '').isNotEmpty)
                                    row['Pref3'],
                                ].whereType<String>().join('  •  '),
                              ),
                              onTap: () => _selectFGOC(row),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    AppDropdown<CodeName>(
                      label: 'FGOC Type',
                      value: _fgocType,
                      items: _fgocTypes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (item) => setState(() => _fgocType = item),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _fgocPicName,
                      label: 'Name PIC',
                      prefixIcon: Icons.person_outline,
                      readOnly: _picLocked,
                      onChanged: _onPicNameChanged,
                      suffix: IconButton(
                        onPressed: _clearPic,
                        icon: const Icon(Icons.clear, size: 18),
                      ),
                    ),
                    _suggestionBox(
                      visible: _picDropdownOpen && !_picLocked,
                      loading: _picFinding,
                      searched: !_picFinding,
                      emptyText: 'PIC tidak ditemukan. Isi manual.',
                      items: _picHits
                          .map(
                            (row) => ListTile(
                              dense: true,
                              title: Text(row['Pref3'] ?? ''),
                              subtitle: Text(
                                '${row['Pref5'] ?? ''}  •  ${row['Pref4'] ?? ''}',
                              ),
                              onTap: () => _applyPic(row),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _fgocPosition,
                      label: 'Position PIC',
                      prefixIcon: Icons.work_outline,
                      readOnly: _picLocked,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _fgocPhone,
                      label: 'Phone PIC',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      readOnly: _picLocked,
                    ),
                  ],
                  if (_company || _showForm) ...[
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
