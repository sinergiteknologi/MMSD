import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/launch_util.dart';
import '../widgets/app_widgets.dart';

class ReportColumn {
  const ReportColumn(this.key, this.label);

  final String key;
  final String label;
}

class ReportTableScreen extends StatefulWidget {
  const ReportTableScreen({
    super.key,
    required this.title,
    required this.loader,
    this.columns = const [],
    this.phoneKey,
  });

  final String title;
  final Future<List<Map<String, String>>> Function() loader;
  final List<ReportColumn> columns;
  final String? phoneKey;

  @override
  State<ReportTableScreen> createState() => _ReportTableScreenState();
}

class _ReportTableScreenState extends State<ReportTableScreen> {
  late Future<List<Map<String, String>>> _future;
  final _hScroll = ScrollController();
  final _vScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = Future(widget.loader);
  }

  @override
  void dispose() {
    _hScroll.dispose();
    _vScroll.dispose();
    super.dispose();
  }

  List<ReportColumn> _columns(List<Map<String, String>> rows) {
    if (widget.columns.isNotEmpty) {
      return widget.columns
          .where((column) => rows.any((row) => (row[column.key] ?? '').trim().isNotEmpty))
          .toList();
    }
    if (rows.isEmpty) return const [];
    return rows.first.keys
        .where((key) => rows.any((row) => (row[key] ?? '').trim().isNotEmpty))
        .map((key) => ReportColumn(key, key))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoading(message: 'Memuat laporan...');
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const EmptyState(message: 'No data');
          }
          final columns = _columns(rows);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${rows.length} data · geser kanan/kiri untuk lihat kolom',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Scrollbar(
                            controller: _hScroll,
                            thumbVisibility: true,
                            notificationPredicate: (n) =>
                                n.metrics.axis == Axis.horizontal,
                            child: SingleChildScrollView(
                              controller: _hScroll,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Scrollbar(
                                  controller: _vScroll,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _vScroll,
                                    child: Table(
                                      border: TableBorder.symmetric(
                                        inside: const BorderSide(
                                          color: AppColors.line,
                                        ),
                                      ),
                                      defaultColumnWidth:
                                          const IntrinsicColumnWidth(),
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      children: [
                                        TableRow(
                                          decoration: const BoxDecoration(
                                            color: AppColors.navy,
                                          ),
                                          children: [
                                            _headerCell('No'),
                                            ...columns.map(
                                              (column) =>
                                                  _headerCell(column.label),
                                            ),
                                          ],
                                        ),
                                        ...List.generate(rows.length, (index) {
                                          final row = rows[index];
                                          final odd = index.isOdd;
                                          return TableRow(
                                            decoration: BoxDecoration(
                                              color: odd
                                                  ? AppColors.cream
                                                  : Colors.white,
                                            ),
                                            children: [
                                              _cell(
                                                '${index + 1}',
                                                numeric: true,
                                              ),
                                              ...columns.map(
                                                (column) => _cell(
                                                  row[column.key] ?? '',
                                                  phone:
                                                      widget.phoneKey ==
                                                          column.key
                                                      ? (row[column.key] ?? '')
                                                      : '',
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _cell(String text, {bool numeric = false, String phone = ''}) {
    final value = text.trim().isEmpty ? '-' : text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: phone.trim().isEmpty
          ? Text(
              value,
              textAlign: numeric ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            )
          : InkWell(
              onTap: () => _contact(phone),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
    );
  }

  Future<void> _contact(String phone) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.call_outlined),
              title: const Text('Call'),
              onTap: () => Navigator.pop(context, 'call'),
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('WhatsApp'),
              onTap: () => Navigator.pop(context, 'wa'),
            ),
            ListTile(
              leading: const Icon(Icons.sms_outlined),
              title: const Text('SMS'),
              onTap: () => Navigator.pop(context, 'sms'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Salin nomor'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
          ],
        ),
      ),
    );
    if (action == 'call') await LaunchUtil.call(phone);
    if (action == 'wa') await LaunchUtil.whatsapp(phone);
    if (action == 'sms') await LaunchUtil.sms(phone);
    if (action == 'copy') await LaunchUtil.copy(phone);
  }
}

List<ReportColumn> reportColumns(String report) {
  switch (report) {
    case 'Status List':
      return const [
        ReportColumn('Pref8', 'Status'),
        ReportColumn('Pref3', 'Date'),
        ReportColumn('Pref5', 'Name'),
        ReportColumn('Pref4', 'Phone'),
        ReportColumn('Pref7', 'Model'),
        ReportColumn('Pref6', 'QTY'),
        ReportColumn('Pref9', 'Sales'),
        ReportColumn('Pref12', 'Last Change Status'),
      ];
    case 'Daily':
      return [
        const ReportColumn('User', 'User'),
        const ReportColumn('Status', 'Status'),
        ...List.generate(
          31,
          (index) => ReportColumn('d${index + 1}', '${index + 1}'),
        ),
        const ReportColumn('Total', 'Total'),
      ];
    case 'Activity':
      return const [
        ReportColumn('ActivityName', 'Activity'),
        ReportColumn('SubActivityName', 'Sub Activity'),
        ReportColumn('ACTNumber', 'ACT Number'),
        ReportColumn('ACTName', 'ACT Name'),
        ReportColumn('SPVName', 'SPV'),
        ReportColumn('SalesName', 'Sales'),
        ReportColumn('StartDate', 'Start'),
        ReportColumn('EndDate', 'End'),
        ReportColumn('CityName', 'City'),
        ReportColumn('DistrictName', 'District'),
        ReportColumn('TotalProspect', 'Prospect'),
        ReportColumn('TotalSPK', 'SPK'),
        ReportColumn('TotalDO', 'DO'),
      ];
    case 'Fleet Detail':
      return const [
        ReportColumn('Pref1', 'Branch'),
        ReportColumn('Pref2', 'Sales'),
        ReportColumn('Pref3', 'Fleet'),
        ReportColumn('Pref4', 'Date'),
        ReportColumn('Pref5', 'Name'),
        ReportColumn('Pref6', 'Model'),
        ReportColumn('Pref7', 'QTY'),
        ReportColumn('Pref8', 'Status'),
      ];
    case 'Fleet Summary':
      return const [
        ReportColumn('Pref1', 'Sales'),
        ReportColumn('Pref2', 'Date'),
        ReportColumn('Pref3', 'Name'),
        ReportColumn('Pref4', 'Status'),
        ReportColumn('Pref5', 'QTY'),
        ReportColumn('Pref6', 'Pref6'),
        ReportColumn('Pref7', 'Pref7'),
      ];
    case 'Activity Recap':
      return const [
        ReportColumn('Pref1', 'Branch'),
        ReportColumn('Pref2', 'SPV'),
        ReportColumn('Pref3', 'Sales'),
        ReportColumn('Pref4', 'Activity'),
        ReportColumn('Pref5', 'Prospect'),
        ReportColumn('Pref6', 'SPK'),
        ReportColumn('Pref7', 'DO'),
      ];
    case 'KPI Weekly':
    case 'KPI Monthly':
      return const [
        ReportColumn('Pref1', 'Branch'),
        ReportColumn('Pref2', 'SPV'),
        ReportColumn('Pref3', 'Sales'),
        ReportColumn('Pref4', 'Status'),
        ReportColumn('Pref5', 'W1'),
        ReportColumn('Pref6', 'W2'),
        ReportColumn('Pref7', 'W3'),
        ReportColumn('Pref8', 'W4'),
        ReportColumn('Pref9', 'Total'),
      ];
    case 'Customer':
      return const [
        ReportColumn('Pref1', 'Customer'),
        ReportColumn('Pref2', 'Phone'),
        ReportColumn('Pref3', 'City'),
        ReportColumn('Pref4', 'Birth Date'),
        ReportColumn('Pref5', 'Age'),
        ReportColumn('Pref6', 'Model'),
        ReportColumn('Pref7', 'NoPol'),
      ];
    case 'Incentive':
      return const [
        ReportColumn('Pref1', 'Customer'),
        ReportColumn('Pref2', 'Pembayaran'),
        ReportColumn('Pref3', 'No SPK'),
        ReportColumn('Pref4', 'No F.UN'),
        ReportColumn('Pref5', 'Sisa AR'),
        ReportColumn('Pref6', 'Type'),
        ReportColumn('Pref7', 'Jml Unit'),
        ReportColumn('Pref8', 'Ins Retail'),
        ReportColumn('Pref9', 'Ins Fleet'),
        ReportColumn('Pref10', 'Jumlah Ins'),
        ReportColumn('Pref11', 'Ins Progresif'),
        ReportColumn('Pref12', 'Grand Ins'),
      ];
    case 'Incentive SPV':
      return const [
        ReportColumn('Pref1', 'Sales'),
        ReportColumn('Pref2', 'Customer'),
        ReportColumn('Pref3', 'Type'),
        ReportColumn('Pref4', 'QTY'),
        ReportColumn('Pref5', 'Incentive'),
        ReportColumn('Pref6', 'Total'),
      ];
    case 'Daily Sales':
      return const [
        ReportColumn('Pref5', 'Sales'),
        ReportColumn('Pref6', 'OS'),
        ReportColumn('Pref7', 'Target'),
        ReportColumn('Pref8', 'Today'),
        ReportColumn('Pref9', 'Total'),
        ReportColumn('Pref10', 'N-1'),
        ReportColumn('Pref11', 'Potensi DO'),
      ];
    case 'Daily Sales Detail':
      return const [
        ReportColumn('Pref2', 'CAB'),
        ReportColumn('Pref5', 'TDO'),
        ReportColumn('Pref6', 'TUE'),
        ReportColumn('Pref7', 'OS'),
        ReportColumn('Pref8', 'PPTODAY'),
        ReportColumn('Pref9', 'SPKTODAY'),
        ReportColumn('Pref10', 'TSPK'),
        ReportColumn('Pref11', 'TSPK-1'),
        ReportColumn('Pref12', 'DO'),
        ReportColumn('Pref13', 'TUE'),
        ReportColumn('Pref14', 'TBP'),
        ReportColumn('Pref15', 'TPS'),
        ReportColumn('Pref16', 'TOI'),
      ];
    case 'Weekly Sales':
      return const [
        ReportColumn('Pref2', 'Dealer Cabang'),
        ReportColumn('Pref6', 'Target PP'),
        ReportColumn('Pref7', 'Target SPK'),
        ReportColumn('Pref8', 'Target DO'),
        ReportColumn('Pref9', 'OS'),
        ReportColumn('Pref10', 'PP'),
        ReportColumn('Pref11', 'SPK'),
        ReportColumn('Pref12', 'DO'),
        ReportColumn('Pref13', 'Total'),
        ReportColumn('Pref14', 'W1'),
        ReportColumn('Pref15', 'W2'),
        ReportColumn('Pref16', 'W3'),
        ReportColumn('Pref17', 'W4'),
        ReportColumn('Pref18', 'W5'),
        ReportColumn('Pref19', 'Total'),
      ];
    case 'Monthly Activity':
      return const [
        ReportColumn('Pref2', 'Dealer Cabang'),
        ReportColumn('Pref4', 'Target'),
        ReportColumn('Pref5', 'Achievement'),
        ReportColumn('Pref6', '% Ach'),
        ReportColumn('Pref7', 'PP'),
        ReportColumn('Pref8', 'SPK'),
        ReportColumn('Pref9', 'Walk In PP'),
        ReportColumn('Pref10', 'Walk In SPK'),
        ReportColumn('Pref11', 'Digital PP'),
      ];
    case 'Monthly Summary SPV':
      return const [
        ReportColumn('Pref1', 'Kode Cabang'),
        ReportColumn('Pref2', 'SPV Code'),
        ReportColumn('Pref3', 'SPV Name'),
        ReportColumn('Pref4', 'Total PP'),
        ReportColumn('Pref5', 'Total HP'),
        ReportColumn('Pref6', 'Total SPK'),
        ReportColumn('Pref7', 'Total DO'),
      ];
    case 'Monthly Summary BM':
      return const [
        ReportColumn('Pref1', 'Kode Cabang'),
        ReportColumn('Pref2', 'SPV Code'),
        ReportColumn('Pref3', 'SPV Name'),
        ReportColumn('Pref4', 'Sales Code'),
        ReportColumn('Pref5', 'Sales Name'),
        ReportColumn('Pref6', 'Total PP'),
        ReportColumn('Pref7', 'Total HP'),
        ReportColumn('Pref8', 'Total SPK'),
        ReportColumn('Pref9', 'Total DO'),
      ];
    case 'Monthly Summary GM':
      return const [
        ReportColumn('Pref1', 'Kode Cabang'),
        ReportColumn('Pref2', 'Nama Cabang'),
        ReportColumn('Pref3', 'Total PP'),
        ReportColumn('Pref4', 'Total HP'),
        ReportColumn('Pref5', 'Total SPK'),
        ReportColumn('Pref6', 'Total DO'),
      ];
    case 'Daily Sales GM':
      return const [
        ReportColumn('Pref1', 'Cabang'),
        ReportColumn('Pref11', 'T.ATPM'),
        ReportColumn('Pref2', 'OS'),
        ReportColumn('Pref3', 'SPK'),
        ReportColumn('Pref4', 'TSPK'),
        ReportColumn('Pref5', 'TSPK M-1'),
        ReportColumn('Pref6', 'DO'),
        ReportColumn('Pref7', 'UE'),
        ReportColumn('Pref8', 'TUE'),
        ReportColumn('Pref9', 'TPart'),
        ReportColumn('Pref10', 'TBP'),
      ];
    case 'FGOC':
      return const [
        ReportColumn('Pref2', 'CABANG'),
        ReportColumn('Pref4', 'TARGET'),
        ReportColumn('Pref5', 'PP'),
        ReportColumn('Pref6', 'ACH'),
        ReportColumn('Pref7', 'SPK'),
        ReportColumn('Pref9', 'PP M-1'),
        ReportColumn('Pref10', 'SPK M-1'),
        ReportColumn('Pref11', 'DO M-1'),
        ReportColumn('Pref12', 'GROWTH'),
      ];
    default:
      return const [];
  }
}
