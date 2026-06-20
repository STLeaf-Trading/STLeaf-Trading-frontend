import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _companyCtrl.dispose(); _contactCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    _addressCtrl.dispose();
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
    if (mounted && success) context.go('/shop');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Row(
        children: [
          // Side panel
          if (MediaQuery.of(context).size.width > 768)
            Container(
              width: 280,
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white.withOpacity(0.5), width: 2),
                        color: AppColors.white,
                      ),
                      child: ClipOval(
                        child: Transform.scale(
                          scale: 1.4,
                          child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Join ST Leaf\nTrading',
                      style: TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 16),
                    const Text('Register as a wholesale customer and start ordering fresh vegetables today.',
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ),
          // Form
          Expanded(
            child: Container(
              color: AppColors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Account', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 8),
                      const Text('Fill in your business details below',
                        style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 32),

                      const Text('Business Information',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const SizedBox(height: 16),

                      AppTextField(label: 'Company Name', hint: 'ABC Restaurant Sdn Bhd',
                        controller: _companyCtrl,
                        validator: (v) => (v == null || v.isEmpty) ? 'Company name is required' : null),
                      const SizedBox(height: 16),

                      Row(children: [
                        Expanded(child: AppTextField(label: 'Contact Person', hint: 'John Lim',
                          controller: _contactCtrl,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                        const SizedBox(width: 16),
                        Expanded(child: AppTextField(label: 'Phone Number', hint: '0123456789',
                          controller: _phoneCtrl, keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                      ]),
                      const SizedBox(height: 16),

                      AppTextField(label: 'Business Address', hint: 'No. 12, Jalan...',
                        controller: _addressCtrl, maxLines: 2),
                      const SizedBox(height: 24),

                      const Text('Login Credentials',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      const SizedBox(height: 16),

                      AppTextField(label: 'Email Address', hint: 'john@company.com',
                        controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        }),
                      const SizedBox(height: 16),

                      Row(children: [
                        Expanded(child: AppTextField(label: 'Password', controller: _passCtrl,
                          obscureText: _obscurePass,
                          suffix: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 8) return 'Min 8 characters';
                            return null;
                          })),
                        const SizedBox(width: 16),
                        Expanded(child: AppTextField(label: 'Confirm Password', controller: _confirmCtrl,
                          obscureText: _obscurePass,
                          validator: (v) {
                            if (v != _passCtrl.text) return 'Passwords do not match';
                            return null;
                          })),
                      ]),
                      const SizedBox(height: 32),

                      AppButton(
                        label: 'Create Account',
                        onPressed: _register,
                        isLoading: auth.isLoading,
                        width: double.infinity,
                        icon: Icons.person_add_rounded,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text.rich(TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            children: [TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))],
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

