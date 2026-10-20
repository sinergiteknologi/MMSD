import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/master_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SyncLoadingScreen extends StatefulWidget {
  const SyncLoadingScreen({super.key});

  @override
  State<SyncLoadingScreen> createState() => _SyncLoadingScreenState();
}

class _SyncLoadingScreenState extends State<SyncLoadingScreen> {
  static const _steps = [
    'Menghubungkan ke server',
    'Mengunduh Brand',
    'Mengunduh Type',
    'Mengunduh Color',
    'Mengunduh Model',
    'Mengunduh Activity',
    'Mengunduh Sub Activity',
    'Mengunduh City',
    'Mengunduh District',
    'Menyimpan data',
    'Data siap',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  int _stepIndex(String message) {
    final index = _steps.indexOf(message);
    return index < 0 ? 0 : index;
  }

  Future<void> _sync() async {
    final auth = context.read<AuthProvider>();
    final master = context.read<MasterDataProvider>();
    final synced = await master.syncAllMasterData();
    if (!mounted) return;
    if (!synced) {
      final messenger = ScaffoldMessenger.of(context);
      final message = master.syncError.isEmpty
          ? 'Sinkronisasi master data gagal.'
          : master.syncError;
      await auth.logout();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final master = context.watch<MasterDataProvider>();
    final progress = master.syncProgress.clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final current = master.syncMessage.isEmpty
        ? _steps.first
        : master.syncMessage;
    final active = _stepIndex(current);

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: MeshBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  children: [
                    const AppLogo(size: 68),
                    const SizedBox(height: 22),
                    const Text(
                      'Menyiapkan data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mohon tunggu, aplikasi sedang mengunduh data master.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.sand, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: AppColors.gold,
                            value: progress == 0 ? null : progress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            current,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress == 0 ? null : progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: AppCard(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        child: ListView.separated(
                          itemCount: _steps.length - 1,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final done = index < active;
                            final running = index == active;
                            return Row(
                              children: [
                                _StepMark(done: done, running: running),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _steps[index],
                                    style: TextStyle(
                                      fontWeight: running
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: done
                                          ? AppColors.sage
                                          : running
                                          ? AppColors.navy
                                          : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepMark extends StatelessWidget {
  const _StepMark({required this.done, required this.running});

  final bool done;
  final bool running;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return const Icon(
        Icons.check_circle_rounded,
        size: 20,
        color: AppColors.sage,
      );
    }
    if (running) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: AppColors.terracotta,
        ),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line, width: 2),
      ),
    );
  }
}
