import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (mounted) {
      if (success) {
        if (auth.isAdmin) context.go('/admin/dashboard');
        else context.go('/shop');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Login failed'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: isWide ? _WideLayout(
        fade: _fadeAnim, slide: _slideAnim,
        formKey: _formKey, emailCtrl: _emailCtrl, passCtrl: _passCtrl,
        obscurePass: _obscurePass,
        onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
        onLogin: _login, isLoading: auth.isLoading,
      ) : _NarrowLayout(
        fade: _fadeAnim, slide: _slideAnim,
        formKey: _formKey, emailCtrl: _emailCtrl, passCtrl: _passCtrl,
        obscurePass: _obscurePass,
        onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
        onLogin: _login, isLoading: auth.isLoading,
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscurePass, isLoading;
  final VoidCallback onTogglePass, onLogin;

  const _WideLayout({
    required this.fade, required this.slide, required this.formKey,
    required this.emailCtrl, required this.passCtrl, required this.obscurePass,
    required this.onTogglePass, required this.onLogin, required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Hero panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: FadeTransition(
              opacity: fade,
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.eco_rounded, color: AppColors.white, size: 36),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'ST Leaf Trading',
                      style: TextStyle(color: AppColors.white, fontSize: 38, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fresh from Farm to Table',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 18),
                    ),
                    const SizedBox(height: 48),
                    ...[
                      ('🌿', 'Premium Quality Vegetables'),
                      ('🚚', 'Next-Day Delivery'),
                      ('📦', 'Wholesale Pricing'),
                      ('📊', 'Real-time Inventory'),
                    ].map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(e.$1, style: const TextStyle(fontSize: 18))),
                          ),
                          const SizedBox(width: 14),
                          Text(e.$2, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Form panel
        Expanded(
          flex: 4,
          child: _FormPanel(
            fade: fade, slide: slide, formKey: formKey,
            emailCtrl: emailCtrl, passCtrl: passCtrl,
            obscurePass: obscurePass, onTogglePass: onTogglePass,
            onLogin: onLogin, isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscurePass, isLoading;
  final VoidCallback onTogglePass, onLogin;

  const _NarrowLayout({
    required this.fade, required this.slide, required this.formKey,
    required this.emailCtrl, required this.passCtrl, required this.obscurePass,
    required this.onTogglePass, required this.onLogin, required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Column(
                children: [
                  const Icon(Icons.eco_rounded, color: AppColors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text('ST Leaf Trading',
                    style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Fresh from Farm to Table',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
                ],
              ),
            ),
            _FormPanel(
              fade: fade, slide: slide, formKey: formKey,
              emailCtrl: emailCtrl, passCtrl: passCtrl,
              obscurePass: obscurePass, onTogglePass: onTogglePass,
              onLogin: onLogin, isLoading: isLoading, isNarrow: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscurePass, isLoading;
  final VoidCallback onTogglePass, onLogin;
  final bool isNarrow;

  const _FormPanel({
    required this.fade, required this.slide, required this.formKey,
    required this.emailCtrl, required this.passCtrl, required this.obscurePass,
    required this.onTogglePass, required this.onLogin, required this.isLoading,
    this.isNarrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      height: isNarrow ? null : double.infinity,
      child: SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome Back', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  const Text('Sign in to your account', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 40),

                  AppTextField(
                    label: 'Email Address',
                    hint: 'admin@stleaf.com',
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Icon(Icons.email_outlined, size: 18),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: passCtrl,
                    obscureText: obscurePass,
                    prefix: const Icon(Icons.lock_outline_rounded, size: 18),
                    suffix: IconButton(
                      icon: Icon(obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: onTogglePass,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Sign In',
                    onPressed: onLogin,
                    isLoading: isLoading,
                    width: double.infinity,
                    icon: Icons.login_rounded,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/register'),
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(text: 'Register here', style: TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w700,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Demo credentials
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mint, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.mintDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Demo Credentials', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _credRow('Admin', 'admin@stleaf.com', 'Admin123!'),
                        const SizedBox(height: 6),
                        _credRow('Customer', 'john@abcrestaurant.com', 'Customer123!'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _credRow(String role, String email, String pass) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
          child: Text(role, style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text('$email / $pass', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
      ],
    );
  }
}
