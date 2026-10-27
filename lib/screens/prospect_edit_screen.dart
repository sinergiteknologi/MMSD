import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_row.dart';
import '../providers/auth_provider.dart';
import '../providers/prospect_provider.dart';
import '../theme/app_theme.dart';
import '../utils/launch_util.dart';
import '../widgets/app_widgets.dart';
import 'change_status_screen.dart';
import 'spk_form_screen.dart';

class ProspectEditScreen extends StatefulWidget {
  const ProspectEditScreen({super.key, required this.row});

  final HistoryRow row;

  @override
  State<ProspectEditScreen> createState() => _ProspectEditScreenState();
}

class _ProspectEditScreenState extends State<ProspectEditScreen> {
  bool _loading = true;
  Map<String, String> _customer = {};
  List<Map<String, String>> _units = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final prospect = context.read<ProspectProvider>();
    final customer = await prospect.getCustomer(
          branchCode: user.historyBranch,
          idNo: widget.row.idNo,
        );
    if (!mounted) return;
    final cabang = [
      user.busCode,
      if (user.historyBranch.isNotEmpty) user.historyBranch,
    ].where((v) => v.trim().isNotEmpty).join('|');
    final unit = await prospect.getHistoryEdit(
          kodeCabang: cabang,
          idNo: widget.row.idNo,
          historyId: widget.row.historyId,
          userCreated: user.username,
        );
    if (!mounted) return;
    setState(() {
      _customer = customer.isEmpty ? {} : customer.first;
      _units = unit?.toRows(maxPref: 8) ?? [];
      _loading = false;
    });
  }

  String _c(String key) => _customer[key] ?? '';

  @override
  Widget build(BuildContext context) {
    final phone = _c('Pref2').isEmpty ? widget.row.phone : _c('Pref2');
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Prospect')),
      body: _loading
          ? const AppLoading(message: 'Memuat prospect...')
          : ListView(
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
                        '$phone  ·  ${widget.row.status}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const Divider(height: 28),
                      _row('ID', widget.row.idNo),
                      _row('History', widget.row.historyId),
                      _row('Customer', _c('Pref1')),
                      _row('Phone', phone),
                      _row('Alamat', _c('Pref3')),
                      _row('Kota', _c('Pref4')),
                      _row('Model', widget.row.model),
                      _row('Qty', widget.row.qty),
                      _row('Sales', widget.row.salesName),
                    ],
                  ),
                ),
                if (_units.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ..._units.map(
                          (unit) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              [
                                unit['Pref1'],
                                unit['Pref2'],
                                unit['Pref3'],
                                unit['Pref4'],
                              ]
                                  .where(
                                    (item) =>
                                        (item ?? '').trim().isNotEmpty &&
                                        item != '-',
                                  )
                                  .join('  ·  '),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'Change Status',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeStatusScreen(row: widget.row),
                    ),
                  ),
                ),
                if (widget.row.status.toUpperCase() == 'TRUEPROSPECT') ...[
                  const SizedBox(height: 10),
                  AppPrimaryButton(
                    label: 'Create SPK',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpkFormScreen(row: widget.row),
                      ),
                    ),
                  ),
                ],
                if (phone.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => LaunchUtil.call(phone),
                          child: const Text('Call'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => LaunchUtil.whatsapp(phone),
                          child: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _row(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
