import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';

/// Shows a popup dialog with Login / Register tabs.
/// Only used on web (kIsWeb). Android uses the full-page screens.
void showAuthDialog(BuildContext context, {bool startOnRegister = false}) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing when tapping outside
    builder: (_) => _AuthDialog(startOnRegister: startOnRegister),
  );
}

class _AuthDialog extends StatefulWidget {
  final bool startOnRegister;
  const _AuthDialog({this.startOnRegister = false});

  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startOnRegister ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // On iOS, the keyboard pushes the viewport up. We give the tab views a
    // slightly smaller max height when the keyboard is open so the dialog
    // content stays fully visible without overflow.
    final tabMaxHeight = keyboardHeight > 0
        ? (screenHeight - keyboardHeight - 280).clamp(200.0, 600.0)
        : (screenHeight - 280).clamp(200.0, 600.0);

    // GestureDetector intercepts taps outside text fields and routes them to
    // FocusScope.unfocus() instead of letting the OS dismiss the keyboard
    // (which on iOS Safari causes a viewport resize that visually collapses
    // the dialog).
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('ST Leaf Trading',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const Spacer(),
                    // Close button — the ONLY way to dismiss this dialog
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tab bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Sign In'),
                      Tab(text: 'Register'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tab views — constrained height adjusts when keyboard opens on iOS
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: tabMaxHeight),
                  child: TabBarView(
                    controller: _tabController,
                    // Prevent accidental swipe between tabs while filling the form
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SingleChildScrollView(
                        // Manual dismiss so tapping outside field doesn't collapse dialog on iOS
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                        child: _LoginTab(onSwitchToRegister: () => _tabController.animateTo(1)),
                      ),
                      SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                        child: _RegisterTab(onSwitchToLogin: () => _tabController.animateTo(0)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LOGIN TAB
// ─────────────────────────────────────────────
class _LoginTab extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  const _LoginTab({required this.onSwitchToRegister});

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );
    if (mounted && success) {
      Navigator.of(context).pop(); // close dialog
      if (auth.isAdmin) {
        context.go('/admin/dashboard');
      } else {
        context.go('/shop');
      }
    }
  }

  void _showResetDialog() {
    final resetCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a reset link.'),
            const SizedBox(height: 16),
            AppTextField(label: 'Email', controller: resetCtrl),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (resetCtrl.text.isEmpty) return;
              final res = await context.read<AuthProvider>().resetPassword(resetCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res ? 'Reset email sent!' : 'Failed. Please try again.'),
                ));
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Email Address',
            hint: 'john@company.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefix: const Icon(Icons.email_outlined, size: 18),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Password',
            hint: '••••••••',
            controller: _passCtrl,
            obscureText: _obscure,
            prefix: const Icon(Icons.lock_outline_rounded, size: 18),
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showResetDialog,
              child: const Text('Forgot Password?',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(auth.error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
          AppButton(
            label: 'Sign In',
            onPressed: _login,
            isLoading: auth.isLoading,
            width: double.infinity,
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: widget.onSwitchToRegister,
              child: const Text.rich(TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                children: [TextSpan(text: 'Register here',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))],
              )),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REGISTER TAB
// ─────────────────────────────────────────────
class _RegisterTab extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const _RegisterTab({required this.onSwitchToLogin});

  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _isWaitingForVerification = false;

  @override
  void dispose() {
    _companyCtrl.dispose(); _contactCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      companyName: _companyCtrl.text.trim(),
      contactPerson: _contactCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    if (mounted && success) {
      setState(() {
        _isWaitingForVerification = true;
      });
      // Start waiting for verification
      final verified = await auth.waitForEmailVerification();
      if (mounted && verified) {
        Navigator.of(context).pop(); // close dialog
        context.go('/shop');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWaitingForVerification) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text('Verify Your Email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            const Text(
              'We have sent a verification link to your email.\nPlease click the link to verify your account.\n\nBe sure to check your Spam folder if you don\'t see it.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Cancel',
              onPressed: () {
                context.read<AuthProvider>().logout();
                widget.onSwitchToLogin();
                setState(() => _isWaitingForVerification = false);
              },
              isOutlined: true,
            ),
          ],
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Company Name / Individual',
            hint: 'ABC Restaurant / John Doe',
            controller: _companyCtrl,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AppTextField(
              label: 'Contact Person', hint: 'John Lim',
              controller: _contactCtrl,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(
              label: 'Phone Number', hint: '0123456789',
              controller: _phoneCtrl, keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            )),
          ]),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Email Address', hint: 'john@company.com',
            controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
            prefix: const Icon(Icons.email_outlined, size: 18),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AppTextField(
              label: 'Password', controller: _passCtrl,
              obscureText: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(
              label: 'Confirm Password', controller: _confirmCtrl,
              obscureText: _obscure,
              validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
            )),
          ]),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(auth.error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Create Account',
            onPressed: _register,
            isLoading: auth.isLoading,
            width: double.infinity,
            icon: Icons.person_add_rounded,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: widget.onSwitchToLogin,
              child: const Text.rich(TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                children: [TextSpan(text: 'Sign In',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))],
              )),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
