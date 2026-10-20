import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _password = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await context.read<AuthProvider>().changePassword(
      _password.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Password updated' : 'Failed')),
    );
    if (success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: AppLoadingOverlay(
        visible: _saving,
        message: 'Menyimpan password...',
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update password',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan password baru untuk akun ini.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                AppPasswordField(controller: _password, label: 'New Password'),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: 'Save',
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
