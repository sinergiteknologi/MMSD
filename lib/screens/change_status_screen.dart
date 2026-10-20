import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/code_name.dart';
import '../models/history_row.dart';
import '../providers/auth_provider.dart';
import '../providers/master_data_provider.dart';
import '../providers/prospect_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_status.dart';
import '../utils/date_format.dart';
import '../widgets/app_widgets.dart';
import 'hot_prospect_form_screen.dart';

class ChangeStatusScreen extends StatefulWidget {
  const ChangeStatusScreen({super.key, required this.row});

  final HistoryRow row;

  @override
  State<ChangeStatusScreen> createState() => _ChangeStatusScreenState();
}

class _ChangeStatusScreenState extends State<ChangeStatusScreen> {
  late String _type;
  String _date = AppDateFormat.mdy(DateTime.now());
  final _desc = TextEditingController();
  final _reason = TextEditingController();
  List<CodeName> _factors = [];
  CodeName? _factor;
  bool _saving = false;

  String get _status => widget.row.status.toUpperCase();

  bool get _hasTrueProspect =>
      context.read<AuthProvider>().hasTranIdx(AppMenuId.trueProspect);

  List<String> get _types {
    if (_status == AppStatus.trueProspect) return ['CA'];
    if (_status == AppStatus.hotProspect) {
      return _hasTrueProspect ? ['FU', 'HP', 'TP', 'CA'] : ['FU', 'HP', 'CA'];
    }
    return ['FU', 'HP', 'CA'];
  }

  String get _defaultType {
    if (_status == AppStatus.followUp) return 'HP';
    if (_status == AppStatus.hotProspect) {
      return _hasTrueProspect ? 'TP' : 'HP';
    }
    if (_status == AppStatus.trueProspect) return 'CA';
    return 'FU';
  }

  @override
  void initState() {
    super.initState();
    _type = _defaultType;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final items = await context.read<MasterDataProvider>().getFactors();
      if (!mounted) return;
      setState(() {
        _factors = items;
        _factor = items.isNotEmpty ? items.first : null;
        if (!_types.contains(_type)) _type = _types.first;
      });
    });
  }

  @override
  void dispose() {
    _desc.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    if (_date.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dateMessage())),
      );
      return;
    }
    if (_type == 'CA' && _reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill reason')),
      );
      return;
    }
    if (_type == 'HP') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HotProspectFormScreen(
            row: widget.row,
            hpDate: _date,
            hpDesc: _desc.text,
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final success = await context.read<ProspectProvider>().uploadStatus({
      'prmIDNo': widget.row.idNo,
      'prmUserCreated': user.username,
      'prmHistoryID': widget.row.historyId,
      'prmCancelCode': _type == 'CA' ? (_factor?.code ?? '') : '',
      'prmCancelReason': _type == 'CA' ? _reason.text : '',
      'prmHPDate': '',
      'prmCancelDate': _type == 'CA' ? _date : '',
      'prmLostDate': '',
      'prmFUDate': _type == 'FU' ? _date : '',
      'prmMName': widget.row.name,
      'prmMAddress': '',
      'prmMPhone2': '',
      'prmMKTPNo': '',
      'prmMBirthDate': '',
      'prmMReligion': '',
      'prmTOP': '',
      'prmMPIC': widget.row.pic,
      'prmMJobCode': '',
      'prmMLOBCode': '',
      'prmMUserLevel': user.userGroup,
      'prmSalesCode': user.salesCode,
      'prmBranchCode': user.busCode,
      'prmTPDate': _type == 'TP' ? _date : '',
      'prmFUDesc': _type == 'FU' ? _desc.text : '',
      'prmHPDesc': '',
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Data successfully saved' : 'Failed to save data'),
      ),
    );
    if (success) {
      _goHome();
    }
  }

  String _dateMessage() {
    if (_type == 'FU') return 'Please fill date follow up';
    if (_type == 'HP') return 'Please fill date hot prospect';
    if (_type == 'TP') return 'Please fill date true prospect';
    return 'Please fill reason and date lost or cancel';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Status')),
      body: AppLoadingOverlay(
        visible: _saving,
        message: 'Menyimpan...',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.row.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.row.phone}  ·  ${widget.row.status}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_types.contains('FU')) _chip('FU', 'Follow Up'),
                      if (_types.contains('HP')) _chip('HP', 'Hot Prospect'),
                      if (_types.contains('TP')) _chip('TP', 'True Prospect'),
                      if (_types.contains('CA')) _chip('CA', 'Cancel'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppDateField(
                    label: _type == 'FU'
                        ? 'Follow Up Date'
                        : _type == 'HP'
                        ? 'Hot Prospect Date'
                        : _type == 'TP'
                        ? 'True Prospect Date'
                        : 'Cancel Date',
                    value: _date,
                    onPicked: (date) =>
                        setState(() => _date = AppDateFormat.mdy(date)),
                  ),
                  if (_type == 'FU' || _type == 'HP') ...[
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _desc,
                      label: 'Description',
                      prefixIcon: Icons.notes_outlined,
                    ),
                  ],
                  if (_type == 'CA') ...[
                    const SizedBox(height: 14),
                    AppDropdown<CodeName>(
                      label: 'Factor',
                      value: _factor,
                      items: _factors
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
                      onChanged: (item) => setState(() => _factor = item),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _reason,
                      label: 'Reason',
                      prefixIcon: Icons.report_gmailerrorred_outlined,
                    ),
                  ],
                  const SizedBox(height: 22),
                  AppPrimaryButton(
                    label: _type == 'HP' ? 'Lanjut Data Customer' : 'Save',
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

  Widget _chip(String value, String label) {
    final selected = _type == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.navy,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => setState(() {
        _type = value;
        _desc.clear();
        _reason.clear();
      }),
    );
  }
}
