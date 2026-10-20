import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/history_row.dart';
import '../providers/auth_provider.dart';
import '../providers/master_data_provider.dart';
import '../providers/prospect_provider.dart';
import '../providers/spk_provider.dart';
import '../services/pref_service.dart';
import '../services/pwa_install.dart';
import '../theme/app_theme.dart';
import '../utils/app_status.dart';
import '../utils/spk_list_action.dart';
import '../widgets/app_widgets.dart';
import 'change_password_screen.dart';
import 'filter_date_screen.dart';
import 'history_list_screen.dart';
import 'login_screen.dart';
import 'change_status_screen.dart';
import 'hot_prospect_form_screen.dart';
import 'prospect_form_screen.dart';
import 'report_filter_screen.dart';
import 'simulasi_screen.dart';
import 'spk_form_screen.dart';
import 'spk_indent_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loggingOut = false;
  bool _showPwaInstall = false;

  @override
  void initState() {
    super.initState();
    _syncPwaInstall();
    PwaInstall.onAvailable(_syncPwaInstall);
  }

  void _syncPwaInstall() {
    if (!mounted) return;
    setState(() => _showPwaInstall = PwaInstall.shouldShowInstall);
  }

  Future<void> _installPwa() async {
    if (PwaInstall.canPrompt) {
      final accepted = await PwaInstall.promptInstall();
      if (!mounted) return;
      if (accepted || PwaInstall.isInstalled) {
        setState(() => _showPwaInstall = false);
        return;
      }
    }
    if (!mounted || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Install Aplikasi'),
        content: const Text(
          'Chrome/Android: ketuk menu ⋮ lalu pilih "Install app" atau '
          '"Add to Home screen".\n\n'
          'Safari/iPhone: ketuk Share lalu pilih "Add to Home Screen".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  Future<void> _refresh(BuildContext context) async {
    await context.read<MasterDataProvider>().syncAllMasterData();
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.pop(context);
    setState(() => _loggingOut = true);
    await context.read<AuthProvider>().logout();
    if (!mounted || !context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openHistory(
    BuildContext context, {
    required String title,
    required String status,
    bool createSpk = false,
    bool isSpk = false,
  }) async {
    final auth = context.read<AuthProvider>();
    final prefs = PrefService();
    await prefs.saveStatusFilter(status);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilterDateScreen(
          title: title,
          onSubmit: (date1, date2) async {
            await prefs.saveFiltering(date1, date2);
            if (!context.mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryListScreen(
                  title: title.endsWith('List') ? title : '$title List',
                  isSpk: isSpk,
                  actionLabel: createSpk
                      ? 'Create SPK'
                      : (isSpk ? 'Select' : 'Select'),
                  loader: () {
                    final user = auth.user;
                    if (isSpk) {
                      return context.read<SpkProvider>().getHistorySPK(
                        kodeCabang: user?.historyBranch ?? '',
                        idNo: '',
                        userCreated: user?.username ?? '',
                        userGroup: user?.userGroup ?? '',
                        date1: date1,
                        date2: date2,
                        status: status,
                      );
                    }
                    return context.read<ProspectProvider>().getHistory(
                      kodeCabang: user?.historyBranch ?? '',
                      idNo: '',
                      userCreated: user?.username ?? '',
                      userGroup: user?.userGroup ?? '',
                      date1: date1,
                      date2: date2,
                      status: status,
                    );
                  },
                  onSelect: (row) => _handleSelect(
                    context,
                    row: row,
                    createSpk: createSpk,
                    isSpk: isSpk,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleSelect(
    BuildContext context, {
    required HistoryRow row,
    required bool createSpk,
    required bool isSpk,
  }) async {
    final prefs = PrefService();
    await prefs.saveDataHistorySelected(
      idNo: row.idNo,
      historyId: row.historyId,
      status: row.status,
      name: row.name,
      tlp: row.phone,
      salesName: row.salesName,
      spkNo: row.spkNo,
    );
    if (!context.mounted) return;
    if (createSpk) {
      _open(context, SpkFormScreen(row: row));
      return;
    }
    if (isSpk) {
      if (SpkListAction.isApprovedStatus(row.status)) {
        _open(context, SpkIndentScreen(row: row));
        return;
      }
      final action = SpkListAction.resolve(
        userStatus: context.read<AuthProvider>().user?.userStatus ?? '',
        spkStatus: row.status,
      );
      _open(context, SpkFormScreen(row: row, action: action));
      return;
    }
    final auth = context.read<AuthProvider>();
    if (row.status.toUpperCase() == AppStatus.trueProspect &&
        !auth.hasTranIdx(AppMenuId.trueProspect)) {
      _open(
        context,
        HotProspectFormScreen(row: row, hpDate: '', hpDesc: ''),
      );
      return;
    }
    _open(context, ChangeStatusScreen(row: row));
  }

  List<_HomeMenu> _menus(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final items = <_HomeMenu>[
      _HomeMenu(
        id: AppMenuId.prospect,
        title: 'Prospect',
        subtitle: 'Input pelanggan baru',
        icon: Icons.person_add_alt_1_rounded,
        tint: AppColors.navy,
        onTap: () => _open(context, const ProspectFormScreen()),
      ),
      _HomeMenu(
        id: AppMenuId.prospectList,
        title: 'Prospect List',
        subtitle: 'Semua prospect',
        icon: Icons.people_alt_outlined,
        tint: const Color(0xFF3D5A80),
        onTap: () => _openHistory(
          context,
          title: 'Prospect',
          status: AppStatus.prospect,
        ),
      ),
      _HomeMenu(
        id: AppMenuId.fuProspect,
        title: 'FU Prospect',
        subtitle: 'Follow up',
        icon: Icons.event_repeat_rounded,
        tint: const Color(0xFF5B7C99),
        onTap: () => _openHistory(
          context,
          title: 'FU Prospect',
          status: AppStatus.followUp,
        ),
      ),
      _HomeMenu(
        id: AppMenuId.hotProspect,
        title: 'Hot Prospect',
        subtitle: 'Prioritas tinggi',
        icon: Icons.local_fire_department_rounded,
        tint: AppColors.terracotta,
        onTap: () => _openHistory(
          context,
          title: 'Hot Prospect',
          status: AppStatus.hotProspect,
        ),
      ),
      _HomeMenu(
        id: AppMenuId.trueProspect,
        title: 'True Prospect',
        subtitle: 'Siap closing',
        icon: Icons.verified_outlined,
        tint: AppColors.sage,
        onTap: () => _openHistory(
          context,
          title: 'True Prospect',
          status: AppStatus.trueProspect,
        ),
      ),
      _HomeMenu(
        id: AppMenuId.spkRegistration,
        title: 'SPK Registration',
        subtitle: 'Buat SPK',
        icon: Icons.assignment_turned_in_outlined,
        tint: const Color(0xFF8C6A3D),
        onTap: () => _openHistory(
          context,
          title: 'SPK Registration',
          status: AppStatus.trueProspect,
          createSpk: true,
        ),
      ),
      _HomeMenu(
        id: AppMenuId.spkList,
        title: 'SPK List',
        subtitle: 'Dokumen pesanan',
        icon: Icons.description_outlined,
        tint: AppColors.gold,
        onTap: () => _openHistory(
          context,
          title: 'SPK List',
          status: AppStatus.spk,
          isSpk: true,
        ),
      ),
      _HomeMenu(
        id: AppMenuId.report,
        title: 'Report',
        subtitle: 'Laporan penjualan',
        icon: Icons.bar_chart_rounded,
        tint: const Color(0xFF6B4E71),
        onTap: () => _open(context, const ReportFilterScreen(crm: false)),
      ),
      _HomeMenu(
        id: AppMenuId.reportCrm,
        title: 'Report CRM',
        subtitle: 'Daily & monthly',
        icon: Icons.insights_rounded,
        tint: const Color(0xFF3F5E46),
        onTap: () => _open(context, const ReportFilterScreen(crm: true)),
      ),
      _HomeMenu(
        id: AppMenuId.simulasi,
        title: 'Simulasi',
        subtitle: 'Kredit kendaraan',
        icon: Icons.calculate_outlined,
        tint: const Color(0xFF4A6670),
        onTap: () => _open(context, const SimulasiScreen()),
      ),
    ];
    return items.where((item) => auth.canAccess(item.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final master = context.watch<MasterDataProvider>();
    final user = auth.user;
    final menus = _menus(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AppLoadingOverlay(
        visible: master.isSyncing || _loggingOut,
        message: _loggingOut
            ? 'Logout...'
            : (master.syncMessage.isEmpty
                ? 'Memuat master data...'
                : master.syncMessage),
        child: Scaffold(
        backgroundColor: AppColors.cream,
        drawer: _HomeDrawer(
          username: user?.username ?? '',
          busName: user?.busName ?? '',
          onChangePassword: () {
            Navigator.pop(context);
            _open(context, const ChangePasswordScreen());
          },
          onLogout: () => _logout(context),
        ),
        body: Column(
          children: [
            _HomeHeader(
              greeting: _greeting,
              username: user?.username ?? 'MMSD',
              busName: user?.busName ?? 'MMSD Application',
              syncing: master.isSyncing,
              progress: master.syncProgress,
              onRefresh: () => _refresh(context),
              showInstall: _showPwaInstall,
              onInstall: _installPwa,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  if (master.isSyncing) ...[
                    _SyncBanner(
                      message: master.syncMessage,
                      progress: master.syncProgress,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Menu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: menus.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.08,
                        ),
                    itemBuilder: (context, index) =>
                        _MenuTile(item: menus[index]),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.username,
    required this.busName,
    required this.syncing,
    required this.progress,
    required this.onRefresh,
    required this.showInstall,
    required this.onInstall,
  });

  final String greeting;
  final String username;
  final String busName;
  final bool syncing;
  final double progress;
  final VoidCallback onRefresh;
  final bool showInstall;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 4,
        8,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navy, Color(0xFF1E3D5C)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                ),
              ),
              const Spacer(),
              if (showInstall)
                IconButton(
                  tooltip: 'Install Aplikasi',
                  onPressed: onInstall,
                  icon: const Icon(
                    Icons.install_mobile_rounded,
                    color: Colors.white,
                  ),
                ),
              IconButton(
                onPressed: onRefresh,
                icon: syncing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                          value: progress == 0 ? null : progress,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                const AppLogo(size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        busName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.sand,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.message, required this.progress});

  final String message;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_rounded, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.isEmpty ? 'Syncing master data' : message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.terracotta,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress == 0 ? null : progress,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _HomeMenu item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.sand),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.tint, size: 22),
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({
    required this.username,
    required this.busName,
    required this.onChangePassword,
    required this.onLogout,
  });

  final String username;
  final String busName;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 24,
              24,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navyDeep, AppColors.navy],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(size: 48),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  busName,
                  style: const TextStyle(color: AppColors.sand, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded, size: 22),
                  title: const Text(
                    'Change Password',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  onTap: onChangePassword,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFB42318),
                    size: 22,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeMenu {
  const _HomeMenu({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
}
