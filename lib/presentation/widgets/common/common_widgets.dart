import 'package:flutter/material.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';

// ─── App Button ───────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isDanger;
  final IconData? icon;
  final double? width;
  final Color? color;

  const AppButton({
    super.key, required this.label, this.onPressed,
    this.isLoading = false, this.isOutlined = false,
    this.isDanger = false, this.icon, this.width, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDanger ? AppColors.danger : (color ?? AppColors.primary);
    Widget child = isLoading
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
              Text(label),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: bg,
            side: BorderSide(color: bg, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        child: child,
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  static Color _bg(String s) {
    switch (s.toLowerCase()) {
      case 'active': case 'delivered': case 'paid': case 'in stock': return AppColors.successLight;
      case 'pending': case 'scheduled': return AppColors.pendingLight;
      case 'confirmed': case 'loading': case 'partially paid': return AppColors.infoLight;
      case 'packed': case 'in transit': case 'out for delivery': return Color(0xFFEDE7F6);
      case 'cancelled': case 'failed': case 'inactive': case 'suspended':
      case 'out of stock': case 'overdue': return AppColors.dangerLight;
      case 'low stock': return AppColors.warningLight;
      default: return AppColors.mint;
    }
  }

  static Color _fg(String s) {
    switch (s.toLowerCase()) {
      case 'active': case 'delivered': case 'paid': case 'in stock': return AppColors.success;
      case 'pending': case 'scheduled': return AppColors.pending;
      case 'confirmed': case 'loading': case 'partially paid': return AppColors.info;
      case 'packed': case 'in transit': case 'out for delivery': return Color(0xFF6A1B9A);
      case 'cancelled': case 'failed': case 'inactive': case 'suspended':
      case 'out of stock': case 'overdue': return AppColors.danger;
      case 'low stock': return AppColors.warning;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(status), borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(
        color: _fg(status), fontSize: 11, fontWeight: FontWeight.w600,
      )),
    );
  }
}

// ─── Freshness Badge ──────────────────────────────────
class FreshnessBadge extends StatelessWidget {
  final String level;
  const FreshnessBadge({super.key, required this.level});

  Color get _color {
    switch (level) {
      case 'Premium Fresh': return const Color(0xFF1565C0);
      case 'Very Fresh': return AppColors.primaryLight;
      default: return AppColors.accent;
    }
  }

  IconData get _icon {
    switch (level) {
      case 'Premium Fresh': return Icons.star_rounded;
      case 'Very Fresh': return Icons.eco_rounded;
      default: return Icons.grass_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 11, color: _color),
          const SizedBox(width: 3),
          Text(level, style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── App Card ─────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0A1B6B35), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.mint,
          highlightColor: AppColors.mint.withOpacity(0.5),
          child: Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}

// ─── App Text Field ───────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final Widget? prefix;
  final int? maxLines;
  final bool enabled;

  const AppTextField({
    super.key, required this.label, this.hint, this.controller,
    this.obscureText = false, this.keyboardType, this.validator,
    this.suffix, this.prefix, this.maxLines = 1, this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
        )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix, prefixIcon: prefix),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key, required this.title, this.subtitle,
    this.icon = Icons.inbox_outlined, this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: const TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

// ─── Loading Widget ───────────────────────────────────
class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

// ─── Stat Card (Dashboard KPI) ───────────────────────
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isGradient;

  const StatCard({
    super.key, required this.title, required this.value,
    this.subtitle, required this.icon, required this.color, this.isGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isGradient ? LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ) : null,
        color: isGradient ? null : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isGradient ? null : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isGradient ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isGradient ? AppColors.white : color, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800,
              color: isGradient ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: isGradient ? Colors.white.withOpacity(0.85) : AppColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: isGradient ? Colors.white.withOpacity(0.65) : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
