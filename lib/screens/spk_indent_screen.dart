import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_row.dart';
import '../providers/auth_provider.dart';
import '../providers/spk_provider.dart';
import '../theme/app_theme.dart';
import '../utils/launch_util.dart';
import '../widgets/app_widgets.dart';

class SpkIndentScreen extends StatefulWidget {
  const SpkIndentScreen({super.key, required this.row});

  final HistoryRow row;

  @override
  State<SpkIndentScreen> createState() => _SpkIndentScreenState();
}

class _SpkIndentScreenState extends State<SpkIndentScreen> {
  Map<String, String> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final rows = await context.read<SpkProvider>().getSPKIndent(
          branchCode: widget.row.branchCode.isNotEmpty
              ? widget.row.branchCode
              : user.busCode,
          spkNo: widget.row.spkNo,
        );
    if (!mounted) return;
    setState(() {
      _data = rows.isEmpty ? {} : rows.first;
      _loading = false;
    });
  }

  String _v(int index) => _data['Pref$index'] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SPK Form')),
      body: _loading
          ? const AppLoading(message: 'Memuat SPK...')
          : _data.isEmpty
          ? const EmptyState(message: 'SPK tidak ditemukan')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _v(8).isEmpty ? widget.row.spkNo : _v(8),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _v(2),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const Divider(height: 28),
                      _row('Tanggal', _v(9)),
                      _row('No Manual', _v(10)),
                      _row('Customer', _v(12)),
                      _row('Alamat Kirim', _v(13)),
                      _row('Telepon', _v(14)),
                      _row('Sales', _v(19)),
                      _row('Faktur An', _v(22)),
                      _row('NPWP', _v(23)),
                      _row('Alamat', _v(24)),
                      _row('Brand', _v(26)),
                      _row('Model', _v(28)),
                      _row('Warna', _v(30)),
                      _row('Harga', _v(31)),
                      _row('Total', _v(32)),
                      _row('Net Total', _v(37)),
                      _row('Produk', _v(39)),
                      _row('Leasing', _v(42)),
                      _row('DP', _v(43)),
                      _row('Terbilang', _v(47)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'Share WhatsApp',
                  onPressed: () {
                    final text = [
                      'SPK ${_v(8)}',
                      _v(12),
                      '${_v(26)} ${_v(28)} ${_v(30)}',
                      'Total ${_v(32)}',
                    ].where((item) => item.trim().isNotEmpty).join('\n');
                    LaunchUtil.whatsapp(_v(14).isEmpty ? widget.row.phone : _v(14), text);
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => LaunchUtil.copy(
                    '${_v(8)} ${_v(12)} ${_v(28)} ${_v(32)}',
                  ),
                  child: const Text('Salin ringkasan'),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value) {
    if (value.trim().isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
