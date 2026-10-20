import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navy, Color(0xFF1D3B58)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _blob(220, AppColors.terracotta.withValues(alpha: 0.22)),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child: _blob(260, AppColors.gold.withValues(alpha: 0.16)),
          ),
          Positioned(
            top: 180,
            left: -30,
            child: _blob(140, Colors.white.withValues(alpha: 0.05)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.terracotta, AppColors.gold],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.terracotta.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'M',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color ?? Colors.white,
        elevation: 2,
        shadowColor: AppColors.navy.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.sand),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AppColors.muted, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      obscureText: _hidden,
      prefixIcon: Icons.lock_outline_rounded,
      suffix: IconButton(
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.muted,
          size: 20,
        ),
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message = 'Memuat data...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message = 'Memuat data...',
  });

  final bool visible;
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: AppColors.navyDeep.withValues(alpha: 0.55),
                child: Center(
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.sand.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 32,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.prefixIcon,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: items.any((item) => item.value == value) ? value : null,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.muted,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: AppColors.muted, size: 20),
      ),
    );
  }
}

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final String value;
  final ValueChanged<DateTime> onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: firstDate ?? DateTime(now.year - 5),
          lastDate: lastDate ?? DateTime(now.year + 5),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.event_outlined,
            color: AppColors.muted,
            size: 20,
          ),
        ),
        child: Text(
          value.isEmpty ? 'Pilih tanggal' : value,
          style: TextStyle(
            color: value.isEmpty ? AppColors.muted : AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
