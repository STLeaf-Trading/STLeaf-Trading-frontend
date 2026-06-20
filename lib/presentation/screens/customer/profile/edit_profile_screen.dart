import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isLoading = false;
  bool _loaded = false;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loadProfile();
      _loaded = true;
    }
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    final uid = auth.currentUser?.id;
    _email = auth.currentUser?.email ?? '';
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('customers').doc(uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _companyCtrl.text = data['companyName'] ?? '';
          _contactCtrl.text = data['contactPerson'] ?? '';
          _phoneCtrl.text = data['phoneNumber'] ?? '';
          _addressCtrl.text = data['address'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.currentUser?.id;
      if (uid == null) return;

      await context.read<CustomerProvider>().updateCustomerProfile(
        uid: uid,
        companyName: _companyCtrl.text.trim(),
        contactPerson: _contactCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomerLayout(
      currentRoute: '/shop/profile',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppColors.mint, foregroundColor: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text('Edit Profile', style: Theme.of(context).textTheme.headlineMedium),
              ]),
              const SizedBox(height: 24),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 20),

                    // Email (read-only)
                    AppTextField(
                      label: 'Email Address',
                      controller: TextEditingController(text: _email ?? ''),
                      enabled: false,
                      suffix: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Company / Business Name *',
                      hint: 'Your company or trading name',
                      controller: _companyCtrl,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Contact Person Name *',
                      hint: 'Your full name',
                      controller: _contactCtrl,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Phone Number *',
                      hint: '011-XXXX XXXX',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      label: 'Delivery Address',
                      hint: 'Enter your full delivery address...',
                      controller: _addressCtrl,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                label: 'Save Changes',
                icon: Icons.save_rounded,
                isLoading: _isLoading,
                width: double.infinity,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
