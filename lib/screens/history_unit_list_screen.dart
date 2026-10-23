import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_unit.dart';
import '../models/prospect_draft.dart';
import '../providers/auth_provider.dart';
import '../providers/prospect_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'history_unit_form_screen.dart';

class HistoryUnitListScreen extends StatefulWidget {
  const HistoryUnitListScreen({super.key, required this.draft});

  final ProspectDraft draft;

  @override
  State<HistoryUnitListScreen> createState() => _HistoryUnitListScreenState();
}

class _HistoryUnitListScreenState extends State<HistoryUnitListScreen> {
  List<HistoryUnit> _units = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final units = await DatabaseService().getHistoryUnits();
    if (!mounted) return;
    setState(() => _units = units);
    if (units.isEmpty) await _add();
  }

  Future<void> _add() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HistoryUnitFormScreen()),
    );
    if (added == true) await _reload();
  }

  Future<void> _upload() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _units.isEmpty) return;
    setState(() => _saving = true);
    final draft = widget.draft;
    final isCompany = draft.company;
    final payload = <String, String>{
      'prmMBranchCode': emptyStr(user.busCode),
      'prmMUser': emptyStr(user.username),
      'prmMName': isCompany ? '' : emptyStr(draft.name),
      'prmMPhone': isCompany ? '' : emptyStr(draft.phone),
      'prmMPhone2': isCompany ? '' : emptyStr(draft.phone2),
      'prmMIsCompany': isCompany ? '2' : '1',
      'prmMUserLevel': '',
      'prmMSalesCode': emptyStr(user.salesCode),
      'prmMProvince': emptyStr(draft.provinceCode),
      'prmMCity': emptyStr(draft.cityCode),
      'prmBrandCode': UnitJoin.of(_units.map((u) => u.brandCode).toList()),
      'prmTypeCode': UnitJoin.of(_units.map((u) => u.typeCode).toList()),
      'prmModelCode': UnitJoin.of(_units.map((u) => u.modelCode).toList()),
      'prmQty': UnitJoin.of(_units.map((u) => u.qty).toList()),
      'prmColourCode': UnitJoin.of(_units.map((u) => u.colourCode).toList()),
      'prmActivityCode': UnitJoin.of(_units.map((u) => u.activityCode).toList()),
      'prmIDNo': isCompany
          ? emptyStr(draft.fgocDesc.isNotEmpty ? draft.fgocDesc : draft.idNo)
          : emptyStr(draft.idNo),
      'prmProvinceCode': UnitJoin.of(_units.map((u) => u.provinceCode).toList()),
      'prmCityCode': UnitJoin.of(_units.map((u) => u.cityCode).toList()),
      'prmDistrictCode': UnitJoin.of(_units.map((u) => u.districtCode).toList()),
      'prmSubActivityCode':
          UnitJoin.of(_units.map((u) => u.subActivityCode).toList()),
      'prmACTNumber': UnitJoin.of(_units.map((u) => u.actNumber).toList()),
      'prmFleetType': UnitJoin.of(_units.map((u) => u.fleetCode).toList()),
      'prmFGOCContectId': isCompany ? emptyStr(draft.fgocContactId) : '',
      'prmFGOCContectName': isCompany ? emptyStr(draft.fgocName) : '',
      'prmFGOCContectPhone': isCompany ? emptyStr(draft.fgocPhone) : '',
      'prmFGOCContectPosition': isCompany ? emptyStr(draft.fgocPosition) : '',
    };
    final success =
        await context.read<ProspectProvider>().uploadNewData4(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Saved' : 'Failed')),
    );
    if (success) {
      await DatabaseService().clearTable('HISTORYUNIT');
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final title = draft.company
        ? '${draft.name}  ·  ${draft.fgocName}  ·  ${draft.fgocPhone}'
        : '${draft.name}  ·  ${draft.phone}';
    return Scaffold(
      appBar: AppBar(title: const Text('History Unit')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppCard(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: _units.isEmpty
                ? const EmptyState(message: 'Belum ada unit')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _units.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final unit = _units[index];
                      return AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${unit.brandName} ${unit.modelName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${unit.colourName}  ·  Qty ${unit.qty}  ·  ${unit.activityName}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await DatabaseService()
                                    .deleteHistoryUnitAt(index);
                                await _reload();
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  OutlinedButton(
                    onPressed: _add,
                    child: const Text('Tambah Unit'),
                  ),
                  const SizedBox(height: 10),
                  AppPrimaryButton(
                    label: 'Upload',
                    loading: _saving,
                    onPressed: _units.isEmpty ? null : _upload,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
