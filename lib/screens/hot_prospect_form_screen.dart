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

void _hpLog(String message) {
  debugPrint('[HP-CITY] $message');
  // ignore: avoid_print
  print('[HP-CITY] $message');
}

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
  /// Teks Autocomplete City/District — diisi HANYA setelah match berhasil
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  String _birth = '';
  String _top = 'Cash';
  final _tops = const [
    CodeName(code: 'Cash', name: 'Cash'),
    CodeName(code: 'Credit', name: 'Credit'),
  ];
  List<CodeName> _lobs = [];

  /// Master dari API — dipakai untuk looping/match, BUKAN ditampilkan mentah
  List<CityItem> _allCities = [];
  List<DistrictItem> _allDistricts = [];

  /// Hasil MATCH saja yang jadi value Autocomplete
  CityItem? _city;
  DistrictItem? _district;

  /// District options = hasil filter by city yang sudah di-match
  List<DistrictItem> _districtItems = [];

  CodeName? _lob;
  bool _loading = true;
  bool _cityReady = false;
  bool _districtReady = false;

  @override
  void initState() {
    super.initState();
    _name.text = widget.row.name;
    _phone.text = widget.row.phone;
    _pic.text = widget.row.pic;
    _birth = AppDateFormat.mdy(
      DateTime(DateTime.now().year, DateTime.now().month, 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _phone2.dispose();
    _address.dispose();
    _pic.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
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

  String _v(Map<String, String> row, String key) {
    final value = (row[key] ?? '').trim();
    return value == '-' ? '' : value;
  }

  Future<void> _showFailPopup(List<String> failures, String logDump) async {
    if (!mounted || failures.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Gagal memuat data'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                [
                  'IDNo: ${widget.row.idNo}',
                  'HistoryID: ${widget.row.historyId}',
                  '',
                  'Detail kegagalan:',
                  ...failures.map((e) => '• $e'),
                  '',
                  '--- Log ---',
                  logDump,
                ].join('\n'),
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _boot() async {
    final user = context.read<AuthProvider>().user;
    final master = context.read<MasterDataProvider>();
    final prospectApi = context.read<ProspectProvider>();
    final debugLines = <String>[];
    final failures = <String>[];

    void note(String msg) {
      _hpLog(msg);
      debugLines.add(msg);
    }

    void fail(String msg) {
      note('FAIL: $msg');
      failures.add(msg);
    }

    note('BOOT start idNo=${widget.row.idNo} historyId=${widget.row.historyId}');

    // =========================================================
    // STEP 1: ambil SEMUA data City & District dari API (untuk matching)
    // =========================================================
    final cityResult = await master.fetchAllCitiesFromApiDetailed();
    var allCities = cityResult.items;
    note('STEP1 GetDataCity fromApi=${cityResult.fromApi} count=${allCities.length}');
    if (!cityResult.fromApi) {
      fail('GetDataCity gagal/fallback lokal. ${cityResult.error}');
    }
    if (allCities.isEmpty) {
      allCities = await master.getCities();
      note('STEP1 fallback getCities(local) count=${allCities.length}');
      if (allCities.isEmpty) {
        fail('Master City kosong (API & lokal).');
      }
    } else {
      final sample = allCities
          .take(3)
          .map((c) => '${c.provinceCode}|${c.cityCode}|${c.cityName}')
          .join(' || ');
      note('STEP1 city sample: $sample');
    }

    final districtResult = await master.fetchAllDistrictsFromApiDetailed();
    var allDistricts = districtResult.items;
    note('STEP1 GetDataDistrict fromApi=${districtResult.fromApi} count=${allDistricts.length}');
    if (!districtResult.fromApi) {
      fail('GetDataDistrict gagal/fallback lokal. ${districtResult.error}');
    }
    if (allDistricts.isEmpty) {
      fail('Master District kosong (API & lokal).');
    }

    final lobs = await master.getLOB();
    if (!mounted) return;

    _allCities = allCities;
    _allDistricts = allDistricts;
    _lobs = lobs;

    if (user == null) {
      fail('User login null — tidak bisa GetFindProspect2.');
      setState(() => _loading = false);
      await _showFailPopup(failures, debugLines.join('\n'));
      return;
    }

    // =========================================================
    // STEP 2: ambil data form Hot Prospect (GetFindProspect2)
    // =========================================================
    final historyId = widget.row.historyId.trim();
    note('STEP2 call GetFindProspect2 filterId=${widget.row.idNo} historyId=$historyId user=${user.username}');
    final rows = await prospectApi.findProspect2(
      filterTlp: '',
      filterId: widget.row.idNo,
      user: user.username,
      historyId: historyId == '-' ? '' : historyId,
    );
    if (!mounted) return;
    note('STEP2 rows.length=${rows.length} err=${prospectApi.errorMessage}');

    String provinceCode = '';
    String cityCode = '';
    String cityNameApi = '';
    String districtCode = '';
    String districtNameApi = '';

    if (rows.isEmpty) {
      fail(
        'GetFindProspect2 gagal/kosong. '
        '${prospectApi.errorMessage} '
        '${prospectApi.lastApiDetail}',
      );
    } else {
      final hp = rows.first;
      note('STEP2 raw Prefs: ${hp.entries.map((e) => '${e.key}=${e.value}').join(' | ')}');
      _fillBasicFields(hp);

      provinceCode = _v(hp, 'Pref16');
      cityCode = _v(hp, 'Pref17');
      cityNameApi = _v(hp, 'Pref6');
      districtCode = _v(hp, 'Pref18');
      districtNameApi = _v(hp, 'Pref7');
      note('STEP2 parse Pref6(CityName)=$cityNameApi Pref7(DistrictName)=$districtNameApi');
      note('STEP2 parse Pref16(Prov)=$provinceCode Pref17(CityCode)=$cityCode Pref18(DistCode)=$districtCode');

      if (provinceCode.isEmpty && cityCode.isEmpty && cityNameApi.isEmpty) {
        fail(
          'GetFindProspect2 OK tapi Pref16/Pref17/Pref6 kosong '
          '(ProvinceCode/CityCode/CityName tidak ada).',
        );
      }

      // =========================================================
      // STEP 3: LOOP data city API → MATCH ProvinceCode + CityCode
      // =========================================================
      CityItem? matchedCity;
      var scanned = 0;
      for (final c in _allCities) {
        scanned++;
        final okCity = cityCode.isNotEmpty && _codeEq(c.cityCode, cityCode);
        final okProv = provinceCode.isEmpty ||
            _codeEq(c.provinceCode, provinceCode);
        if (okCity && okProv) {
          matchedCity = c;
          note('STEP3 MATCH by code at#$scanned → ${c.provinceCode}|${c.cityCode}|${c.cityName}');
          break;
        }
      }
      if (matchedCity == null) {
        note('STEP3 no match by code after scan=$scanned (need Prov=$provinceCode City=$cityCode)');
      }
      if (matchedCity == null && cityNameApi.isNotEmpty) {
        final want = cityNameApi.toLowerCase();
        for (final c in _allCities) {
          if (c.cityName.trim().toLowerCase() == want) {
            matchedCity = c;
            note('STEP3 MATCH by name → ${c.provinceCode}|${c.cityCode}|${c.cityName}');
            break;
          }
        }
        if (matchedCity == null) {
          note('STEP3 no match by name "$cityNameApi"');
        }
      }

      if (matchedCity != null) {
        _city = matchedCity;
        _cityCtrl.text = matchedCity.cityName;
        _cityReady = true;
        note('STEP3 SET cityCtrl="${_cityCtrl.text}" cityReady=$_cityReady');

        // =========================================================
        // STEP 4: filter district → MATCH DistrictCode
        // =========================================================
        var districtPool = _allDistricts
            .where(
              (d) =>
                  _codeEq(d.provinceCode, matchedCity!.provinceCode) &&
                  _codeEq(d.cityCode, matchedCity.cityCode),
            )
            .toList();
        note('STEP4 district filter from API pool=${districtPool.length}');
        if (districtPool.isEmpty) {
          districtPool = await master.getDistricts(
            provinceCode: matchedCity.provinceCode,
            cityCode: matchedCity.cityCode,
          );
          note('STEP4 district fallback local pool=${districtPool.length}');
        }
        if (!mounted) return;
        _districtItems = districtPool;

        DistrictItem? matchedDistrict;
        for (final d in districtPool) {
          if (districtCode.isNotEmpty &&
              _codeEq(d.districtCode, districtCode)) {
            matchedDistrict = d;
            note('STEP4 MATCH district by code → ${d.districtCode}|${d.districtName}');
            break;
          }
        }
        if (matchedDistrict == null && districtNameApi.isNotEmpty) {
          final want = districtNameApi.toLowerCase();
          for (final d in districtPool) {
            if (d.districtName.trim().toLowerCase() == want) {
              matchedDistrict = d;
              note('STEP4 MATCH district by name → ${d.districtCode}|${d.districtName}');
              break;
            }
          }
        }
        if (matchedDistrict == null) {
          fail(
            'District tidak match. '
            'Cari DistrictCode=$districtCode / DistrictName=$districtNameApi '
            'untuk Prov=${matchedCity.provinceCode} City=${matchedCity.cityCode}. '
            'Pool=${districtPool.length}',
          );
        }

        if (matchedDistrict != null) {
          _district = matchedDistrict;
          _districtCtrl.text = matchedDistrict.districtName;
          _districtReady = true;
          note('STEP4 SET districtCtrl="${_districtCtrl.text}"');
        }
      } else {
        fail(
          'City tidak match. '
          'Cari ProvinceCode=$provinceCode CityCode=$cityCode '
          'CityName=$cityNameApi dari ${_allCities.length} data city.',
        );
      }
    }

    note('DONE city="${_cityCtrl.text}" district="${_districtCtrl.text}" ready=$_cityReady/$_districtReady');
    if (mounted) {
      setState(() => _loading = false);
      if (failures.isNotEmpty) {
        await _showFailPopup(failures, debugLines.join('\n'));
      }
    }
  }

  void _fillBasicFields(Map<String, String> hp) {
    final phone = _v(hp, 'Pref2');
    final phone2 = _v(hp, 'Pref5');
    if (_v(hp, 'Pref3').isNotEmpty) _name.text = _v(hp, 'Pref3');
    if (phone.isNotEmpty) {
      _phone.text = phone;
    } else if (phone2.isNotEmpty && _phone.text.trim().isEmpty) {
      _phone.text = phone2;
    }
    _phone2.text = phone2;
    final addr = _v(hp, 'Pref4');
    if (addr.isNotEmpty && !addr.contains(',')) _address.text = addr;
    final birth = _v(hp, 'Pref8');
    if (birth.isNotEmpty && birth != '01/01/1900' && birth != '1/1/1900') {
      _birth = birth;
    }
    if (_v(hp, 'Pref10').isNotEmpty) _pic.text = _v(hp, 'Pref10');
    final lobCode = _v(hp, 'Pref19');
    final lobName = _v(hp, 'Pref11');
    if (lobCode.isNotEmpty) {
      _lob = _lobs.where((e) => e.code == lobCode).firstOrNull;
    } else if (lobName.isNotEmpty) {
      _lob = _lobs.where((e) => e.name == lobName).firstOrNull;
    }
  }

  Future<void> _onCityChanged(CityItem? item) async {
    if (item == null) {
      setState(() {
        _city = null;
        _cityCtrl.clear();
        _cityReady = false;
        _district = null;
        _districtCtrl.clear();
        _districtItems = [];
        _districtReady = false;
      });
      return;
    }
    // City diganti manual → filter ulang district dari data API yang sudah di-load
    var pool = _allDistricts
        .where(
          (d) =>
              _codeEq(d.provinceCode, item.provinceCode) &&
              _codeEq(d.cityCode, item.cityCode),
        )
        .toList();
    if (pool.isEmpty) {
      pool = await context.read<MasterDataProvider>().getDistricts(
            provinceCode: item.provinceCode,
            cityCode: item.cityCode,
          );
    }
    if (!mounted) return;
    setState(() {
      _city = item;
      _cityCtrl.text = item.cityName;
      _cityReady = true;
      _districtItems = pool;
      _district = null;
      _districtCtrl.clear();
      _districtReady = false;
    });
  }

  void _next() {
    if (_top == '-' || _top.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isPersonal ? 'Please PY Type' : 'Please fill TOP',
          ),
        ),
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
      return const Scaffold(
        body: AppLoading(message: 'Memuat data customer...'),
      );
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
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _top = value ?? ''),
                ),
                const SizedBox(height: 14),
                AppDateField(
                  label: 'Birth Date',
                  value: _birth,
                  onPicked: (date) =>
                      setState(() => _birth = AppDateFormat.mdy(date)),
                ),
                const SizedBox(height: 14),

                // City Autocomplete — value = HASIL MATCH (bukan dump semua city)
                // items = master API agar user bisa ganti manual
                AppAutoText<CityItem>(
                  key: ValueKey(
                    'city-match-$_cityReady-${_city?.provinceCode}-${_city?.cityCode}',
                  ),
                  controller: _cityCtrl,
                  label: 'City',
                  value: _city,
                  items: _allCities,
                  displayString: (item) => item.cityName,
                  prefixIcon: Icons.location_city_outlined,
                  onSelected: _onCityChanged,
                ),
                const SizedBox(height: 14),

                // District Autocomplete — value = HASIL MATCH by DistrictCode
                // items = district yang sudah di-filter by city match
                AppAutoText<DistrictItem>(
                  key: ValueKey(
                    'district-match-$_districtReady-${_city?.cityCode}-${_district?.districtCode}',
                  ),
                  controller: _districtCtrl,
                  label: 'District',
                  value: _district,
                  items: _districtItems,
                  displayString: (item) => item.districtName,
                  prefixIcon: Icons.map_outlined,
                  onSelected: (item) {
                    setState(() {
                      _district = item;
                      _districtCtrl.text = item?.districtName ?? '';
                      _districtReady = item != null;
                    });
                  },
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
