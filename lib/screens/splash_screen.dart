import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/version_check.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_config.dart';
import '../utils/xml_parser.dart';
import '../widgets/app_widgets.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _rise;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _rise = Tween<double>(
      begin: 18,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _boot();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    final versionResponse = await auth.apiService.getVersi();
    final versionCheck = versionResponse == null
        ? null
        : VersionCheck.parse(
            XmlParser.parseVersi(versionResponse),
            currentVersionCode: AppConfig.currentVersionCode,
          );
    final results = await Future.wait([
      auth.restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;
    if (versionCheck?.isUpgradeRequired ?? false) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => UpdateRequiredScreen(version: versionCheck!),
        ),
      );
      return;
    }
    final loggedIn = results.first as bool;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            loggedIn ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: MeshBackground(
          child: FadeTransition(
            opacity: _fade,
            child: AnimatedBuilder(
              animation: _rise,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _rise.value),
                  child: child,
                );
              },
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogo(size: 84),
                    SizedBox(height: 24),
                    Text(
                      'MMSD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 6,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mobile Sales Desk',
                      style: TextStyle(
                        color: AppColors.sand,
                        fontSize: 14,
                        letterSpacing: 1.4,
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

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, required this.version});

  final VersionCheck version;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.system_update_alt_rounded,
                      size: 56,
                      color: AppColors.navy,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pembaruan wajib tersedia',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Versi ${version.serverVersionName} harus dipasang '
                      'sebelum aplikasi dapat digunakan.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AppPrimaryButton(
                      label: 'Salin tautan Play Store',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: AppConfig.playStoreUrl),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tautan Play Store telah disalin.'),
                          ),
                        );
                      },
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
