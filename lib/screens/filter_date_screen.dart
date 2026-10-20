import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/app_widgets.dart';

class FilterDateScreen extends StatefulWidget {
  const FilterDateScreen({
    super.key,
    required this.title,
    required this.onSubmit,
  });

  final String title;
  final Future<void> Function(String date1, String date2) onSubmit;

  @override
  State<FilterDateScreen> createState() => _FilterDateScreenState();
}

class _FilterDateScreenState extends State<FilterDateScreen> {
  late String _date1;
  late String _date2;

  @override
  void initState() {
    super.initState();
    _date1 = AppDateFormat.mdy(AppDateFormat.monthStart());
    _date2 = AppDateFormat.mdy(AppDateFormat.monthEnd());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter tanggal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih rentang tanggal lalu cari data.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                AppDateField(
                  label: 'Date From',
                  value: _date1,
                  onPicked: (date) =>
                      setState(() => _date1 = AppDateFormat.mdy(date)),
                ),
                const SizedBox(height: 14),
                AppDateField(
                  label: 'Date To',
                  value: _date2,
                  onPicked: (date) =>
                      setState(() => _date2 = AppDateFormat.mdy(date)),
                ),
                const SizedBox(height: 22),
                AppPrimaryButton(
                  label: 'Find',
                  onPressed: () => widget.onSubmit(_date1, _date2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
