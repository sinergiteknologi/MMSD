import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class PrefListScreen extends StatefulWidget {
  const PrefListScreen({super.key, required this.title, required this.loader});

  final String title;
  final Future<List<Map<String, String>>> Function() loader;

  @override
  State<PrefListScreen> createState() => _PrefListScreenState();
}

class _PrefListScreenState extends State<PrefListScreen> {
  late Future<List<Map<String, String>>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future(widget.loader);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoading(message: 'Memuat data...');
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const EmptyState(message: 'No data');
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: rows.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final values = rows[index].values
                  .where((value) => value.trim().isNotEmpty)
                  .toList();
              final title = values.isNotEmpty ? values.first : 'Item';
              final subtitle = values.skip(1).take(4).join('  ·  ');
              return AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
