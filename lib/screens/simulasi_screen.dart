import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class SimulasiScreen extends StatefulWidget {
  const SimulasiScreen({super.key});

  @override
  State<SimulasiScreen> createState() => _SimulasiScreenState();
}

class _SimulasiScreenState extends State<SimulasiScreen> {
  final _otr = TextEditingController();
  final _dp = TextEditingController();
  final _interest = TextEditingController(text: '0');
  final _insurance = TextEditingController(text: '0');
  final _provisi = TextEditingController(text: '0');
  final _adm = TextEditingController(text: '0');
  int _tenor = 12;
  bool _credit = true;
  String _hutang = '';
  String _nInterest = '';
  String _nInsurance = '';
  String _total = '';
  String _instalment = '';
  String _nProvisi = '';
  String _tdp = '';

  @override
  void dispose() {
    _otr.dispose();
    _dp.dispose();
    _interest.dispose();
    _insurance.dispose();
    _provisi.dispose();
    _adm.dispose();
    super.dispose();
  }

  double _n(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;

  String _rp(num value) {
    final negative = value < 0;
    final grouped = value.abs().round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp ${negative ? '-' : ''}$grouped';
  }

  void _calc() {
    final otr = _n(_otr);
    final dp = _n(_dp);
    final hutang = otr - dp;
    final interestPct = _n(_interest);
    final nInterest = hutang * interestPct / 100 * (_tenor / 12);
    final nInsurance = otr * _n(_insurance) / 100;
    final total = _credit
        ? hutang +
              (hutang * (interestPct * _tenor / 12) / 100) +
              nInsurance +
              (nInsurance * (interestPct * _tenor / 12) / 100)
        : hutang + (hutang * (interestPct * _tenor / 12) / 100);
    final instalment = _tenor == 0 ? 0 : total / _tenor;
    final nProvisi = hutang * _n(_provisi) / 100;
    final tdp = dp + nProvisi + _n(_adm) + (_credit ? nInsurance : 0);
    setState(() {
      _hutang = _rp(hutang);
      _nInterest = _rp(nInterest);
      _nInsurance = _rp(nInsurance);
      _total = _rp(total);
      _instalment = _rp(instalment);
      _nProvisi = _rp(nProvisi);
      _tdp = _rp(tdp);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  controller: _otr,
                  label: 'OTR',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.sell_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _dp,
                  label: 'DP',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.savings_outlined,
                ),
                const SizedBox(height: 14),
                AppDropdown<int>(
                  label: 'Tenor',
                  value: _tenor,
                  items: const [12, 24, 36, 48, 60]
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text('$item bulan'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _tenor = value ?? 12),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _interest,
                  label: 'Interest %',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _insurance,
                  label: 'Asuransi %',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _provisi,
                  label: 'Provisi %',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _adm,
                  label: 'Admin',
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Credit / include asuransi'),
                  value: _credit,
                  onChanged: (value) => setState(() => _credit = value),
                ),
                AppPrimaryButton(label: 'Hitung', onPressed: _calc),
                if (_instalment.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _line('Hutang', _hutang),
                  _line('Bunga', _nInterest),
                  _line('Asuransi', _nInsurance),
                  _line('Total Hutang', _total),
                  _line('Angsuran', _instalment),
                  _line('Provisi', _nProvisi),
                  _line('TDP', _tdp),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
