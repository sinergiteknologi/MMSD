import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/bisnis_option.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'sync_loading_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  BisnisOption? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadBisnis();
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final selected =
        _selected ??
        (auth.bisnisList.isNotEmpty ? auth.bisnisList.first : null);
    if (selected == null) return;
    final success = await auth.login(
      bisnis: selected,
      username: _userController.text.trim(),
      password: _passController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const SyncLoadingScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final items = auth.bisnisList;
    final value = _selected != null && items.contains(_selected)
        ? _selected
        : (items.isNotEmpty ? items.first : null);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: AppLoadingOverlay(
          visible: auth.isLoading,
          message: auth.loadingMessage.isEmpty
              ? 'Sedang masuk...'
              : auth.loadingMessage,
          child: MeshBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      const AppLogo(size: 72),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in to continue to MMSD',
                        style: TextStyle(color: AppColors.sand, fontSize: 14),
                      ),
                      const SizedBox(height: 28),
                      AppCard(
                        child: Column(
                          children: [
                            DropdownButtonFormField<BisnisOption>(
                              key: ValueKey(
                                items.map((item) => item.code).join('|'),
                              ),
                              initialValue: value,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.muted,
                              ),
                              items: items
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (item) =>
                                  setState(() => _selected = item),
                              decoration: const InputDecoration(
                                labelText: 'Bisnis',
                                prefixIcon: Icon(
                                  Icons.apartment_rounded,
                                  color: AppColors.muted,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            AppTextField(
                              controller: _userController,
                              label: 'User',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 14),
                            AppPasswordField(
                              controller: _passController,
                              label: 'Password',
                            ),
                            const SizedBox(height: 22),
                            AppPrimaryButton(
                              label: 'Login',
                              loading: auth.isLoading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
