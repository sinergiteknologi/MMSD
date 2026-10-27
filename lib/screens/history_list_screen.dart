import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/history_row.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_status.dart';
import '../utils/spk_list_action.dart';
import '../widgets/app_widgets.dart';

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({
    super.key,
    required this.title,
    required this.loader,
    required this.onSelect,
    this.actionLabel = 'Select',
    this.isSpk = false,
  });

  final String title;
  final Future<List<Map<String, String>>> Function() loader;
  final void Function(HistoryRow row) onSelect;
  final String actionLabel;
  final bool isSpk;

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  late Future<List<HistoryRow>> _future;
  final _query = TextEditingController();
  HistoryRow? _selected;

  @override
  void initState() {
    super.initState();
    _future = Future(_load);
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<List<HistoryRow>> _load() async {
    final rows = await widget.loader();
    return rows
        .map((row) => HistoryRow.fromPref(row, isSpk: widget.isSpk))
        .toList();
  }

  String _buttonLabel() {
    if (!widget.isSpk || _selected == null) return widget.actionLabel;
    final userStatus =
        context.read<AuthProvider>().user?.userStatus ?? '';
    return SpkListAction.listActionLabel(
      userStatus: userStatus,
      spkStatus: _selected!.status,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<HistoryRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoading(message: 'Memuat daftar...');
          }
          final all = snapshot.data ?? [];
          final rows = all.where((row) => row.matches(_query.text)).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  children: [
                    AppTextField(
                      controller: _query,
                      label: 'Find Data',
                      prefixIcon: Icons.search_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CountChip(
                          icon: Icons.inventory_2_outlined,
                          label: 'Total ${rows.length}',
                        ),
                        if (_query.text.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _CountChip(
                            icon: Icons.filter_alt_outlined,
                            label: 'dari ${all.length}',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? const EmptyState(message: 'Data not found')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          final selected =
                              identical(_selected, row) ||
                              (_selected?.historyId == row.historyId &&
                                  _selected?.idNo == row.idNo);
                          return _HistoryCard(
                            row: row,
                            selected: selected,
                            isSpk: widget.isSpk,
                            onTap: () => setState(() => _selected = row),
                          );
                        },
                      ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: AppPrimaryButton(
                    label: _buttonLabel(),
                    onPressed: _selected == null
                        ? null
                        : () => widget.onSelect(_selected!),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sand),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.terracotta),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.row,
    required this.selected,
    required this.isSpk,
    required this.onTap,
  });

  final HistoryRow row;
  final bool selected;
  final bool isSpk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = row.name.isEmpty ? row.idNo : row.name;
    final status = _statusStyle(row.status);
    return Material(
      color: selected ? const Color(0xFFF4EDE3) : Colors.white,
      elevation: selected ? 0 : 1,
      shadowColor: AppColors.navy.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.terracotta : AppColors.sand,
                width: selected ? 1.5 : 1,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border(
                left: BorderSide(
                  color: selected ? AppColors.terracotta : status.color,
                  width: 5,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(name: title, color: status.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                color: AppColors.ink,
                              ),
                            ),
                            if (row.phone.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              _MetaLine(
                                icon: Icons.phone_outlined,
                                text: row.phone,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _StatusChip(style: status),
                          if (selected)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.terracotta,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (row.model.isNotEmpty ||
                      row.qty.isNotEmpty ||
                      (isSpk && row.spkNo.isNotEmpty)) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (row.model.isNotEmpty)
                          _InfoPill(
                            icon: Icons.directions_car_outlined,
                            text: row.model,
                          ),
                        if (row.qty.isNotEmpty)
                          _InfoPill(
                            icon: Icons.pin_outlined,
                            text: 'Qty ${row.qty}',
                          ),
                        if (isSpk && row.spkNo.isNotEmpty)
                          _InfoPill(
                            icon: Icons.receipt_long_outlined,
                            text: row.spkNo,
                          ),
                      ],
                    ),
                  ],
                  if (row.date.isNotEmpty || row.salesName.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (row.date.isNotEmpty)
                            Expanded(
                              child: _MetaLine(
                                icon: Icons.event_outlined,
                                text: row.date,
                              ),
                            ),
                          if (row.salesName.isNotEmpty)
                            Expanded(
                              child: _MetaLine(
                                icon: Icons.person_outline_rounded,
                                text: row.salesName,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '-';
    if (parts.length == 1) {
      final text = parts.first;
      return text.substring(0, text.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.style});

  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.sand.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.navy),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusStyle {
  const _StatusStyle({required this.label, required this.color});

  final String label;
  final Color color;
}

_StatusStyle _statusStyle(String status) {
  switch (status.toUpperCase()) {
    case AppStatus.prospect:
      return const _StatusStyle(label: 'Prospect', color: AppColors.navy);
    case AppStatus.followUp:
      return const _StatusStyle(label: 'Follow Up', color: AppColors.gold);
    case AppStatus.hotProspect:
      return const _StatusStyle(label: 'Hot', color: AppColors.terracotta);
    case AppStatus.trueProspect:
      return const _StatusStyle(label: 'True', color: AppColors.sage);
    case AppStatus.spk:
      return const _StatusStyle(label: 'SPK', color: AppColors.navyDeep);
    case 'WAITING APP 1':
      return const _StatusStyle(label: 'Waiting App 1', color: AppColors.gold);
    case 'WAITING APP 2':
      return const _StatusStyle(label: 'Waiting App 2', color: AppColors.terracotta);
    case 'APPROVED':
      return const _StatusStyle(label: 'Approved', color: AppColors.sage);
    case AppStatus.cancel:
      return const _StatusStyle(label: 'Cancel', color: Color(0xFFB42318));
    default:
      return _StatusStyle(
        label: status.isEmpty ? 'Unknown' : status,
        color: AppColors.muted,
      );
  }
}
