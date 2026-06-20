import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/data/models/product_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';

class ProductFormScreen extends StatefulWidget {
  final String? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precautionCtrl = TextEditingController();
  final _packTypeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _promoPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  String _selectedCategory = AppConstants.productCategories[1];
  String _selectedFreshness = AppConstants.freshnessLevels[0];
  bool _hasPromo = false;
  bool _isSaving = false;
  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    }
  }

  void _loadProduct() {
    final products = context.read<ProductProvider>().allProducts;
    final p = products.firstWhere((p) => p.id == widget.productId, orElse: () => products.first);
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description;
    _precautionCtrl.text = p.precaution;
    _packTypeCtrl.text = p.packType;
    _priceCtrl.text = p.price.toString();
    _weightCtrl.text = p.weightKg.toString();
    _stockCtrl.text = p.stockQuantity.toString();
    setState(() {
      _selectedCategory = p.category;
      _selectedFreshness = p.freshnessLevel;
      _hasPromo = p.hasPromotion;
      if (p.hasPromotion) _promoPriceCtrl.text = p.promotionPrice.toString();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _precautionCtrl.dispose();
    _packTypeCtrl.dispose(); _priceCtrl.dispose(); _promoPriceCtrl.dispose();
    _stockCtrl.dispose(); _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final product = ProductModel(
      id: widget.productId ?? const Uuid().v4(),
      itemCode: 'VEG-${DateTime.now().millisecondsSinceEpoch % 1000}',
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      description: _descCtrl.text.trim(),
      precaution: _precautionCtrl.text.trim(),
      freshnessLevel: _selectedFreshness,
      packType: _packTypeCtrl.text.trim(),
      weightKg: double.tryParse(_weightCtrl.text) ?? 0,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      promotionPrice: _hasPromo && _promoPriceCtrl.text.isNotEmpty ? double.tryParse(_promoPriceCtrl.text) : null,
      stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
      status: 'Active',
      createdAt: DateTime.now(),
    );

    final provider = context.read<ProductProvider>();
    if (_isEditing) {
      provider.updateProduct(product);
    } else {
      provider.addProduct(product);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Product updated successfully' : 'Product added successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.go('/admin/products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: '/admin/products',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/admin/products'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.mint),
                  ),
                  const SizedBox(width: 16),
                  Text(_isEditing ? 'Edit Product' : 'Add New Product',
                    style: Theme.of(context).textTheme.displaySmall),
                ],
              ),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _FormSection(
                          nameCtrl: _nameCtrl, descCtrl: _descCtrl, precautionCtrl: _precautionCtrl,
                          packTypeCtrl: _packTypeCtrl, priceCtrl: _priceCtrl, promoPriceCtrl: _promoPriceCtrl,
                          stockCtrl: _stockCtrl, weightCtrl: _weightCtrl,
                          selectedCategory: _selectedCategory, selectedFreshness: _selectedFreshness,
                          hasPromo: _hasPromo,
                          onCategoryChanged: (v) => setState(() => _selectedCategory = v!),
                          onFreshnessChanged: (v) => setState(() => _selectedFreshness = v!),
                          onPromoToggled: (v) => setState(() => _hasPromo = v!),
                        )),
                        const SizedBox(width: 24),
                        SizedBox(width: 240, child: _PreviewCard(
                          name: _nameCtrl.text, category: _selectedCategory,
                          freshness: _selectedFreshness, price: _priceCtrl.text,
                          promoPrice: _hasPromo ? _promoPriceCtrl.text : null,
                        )),
                      ],
                    );
                  }
                  return _FormSection(
                    nameCtrl: _nameCtrl, descCtrl: _descCtrl, precautionCtrl: _precautionCtrl,
                    packTypeCtrl: _packTypeCtrl, priceCtrl: _priceCtrl, promoPriceCtrl: _promoPriceCtrl,
                    stockCtrl: _stockCtrl, weightCtrl: _weightCtrl,
                    selectedCategory: _selectedCategory, selectedFreshness: _selectedFreshness,
                    hasPromo: _hasPromo,
                    onCategoryChanged: (v) => setState(() => _selectedCategory = v!),
                    onFreshnessChanged: (v) => setState(() => _selectedFreshness = v!),
                    onPromoToggled: (v) => setState(() => _hasPromo = v!),
                  );
                },
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancel', isOutlined: true,
                    onPressed: () => context.go('/admin/products'),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: _isEditing ? 'Save Changes' : 'Add Product',
                    icon: Icons.save_rounded,
                    onPressed: _save,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final TextEditingController nameCtrl, descCtrl, precautionCtrl, packTypeCtrl,
      priceCtrl, promoPriceCtrl, stockCtrl, weightCtrl;
  final String selectedCategory, selectedFreshness;
  final bool hasPromo;
  final ValueChanged<String?> onCategoryChanged, onFreshnessChanged;
  final ValueChanged<bool?> onPromoToggled;

  const _FormSection({
    required this.nameCtrl, required this.descCtrl, required this.precautionCtrl,
    required this.packTypeCtrl, required this.priceCtrl, required this.promoPriceCtrl,
    required this.stockCtrl, required this.weightCtrl, required this.selectedCategory,
    required this.selectedFreshness, required this.hasPromo,
    required this.onCategoryChanged, required this.onFreshnessChanged, required this.onPromoToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Basic Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 20),
              AppTextField(label: 'Product Name *', hint: 'e.g. Kangkung (Water Spinach)', controller: nameCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: AppConstants.productCategories.skip(1).map((c) =>
                        DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: onCategoryChanged,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Freshness Level *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedFreshness,
                      items: AppConstants.freshnessLevels.map((f) =>
                        DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: onFreshnessChanged,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              AppTextField(label: 'Description', hint: 'Product description...', controller: descCtrl, maxLines: 3),
              const SizedBox(height: 16),
              AppTextField(label: 'Precaution / Storage', hint: 'Storage and handling instructions...', controller: precautionCtrl, maxLines: 2),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pricing & Stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: AppTextField(label: 'Pack Type', hint: 'Bundle / KG / Pack', controller: packTypeCtrl)),
                const SizedBox(width: 16),
                Expanded(child: AppTextField(label: 'Weight (kg)', hint: '0.5', controller: weightCtrl,
                  keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: AppTextField(label: 'Price (RM) *', hint: '3.50', controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Price is required' : null)),
                const SizedBox(width: 16),
                Expanded(child: AppTextField(label: 'Stock Quantity *', hint: '100', controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Stock is required' : null)),
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(value: hasPromo, onChanged: onPromoToggled, activeColor: AppColors.primary),
                  const Text('Enable Promotion Price', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              if (hasPromo) ...[
                const SizedBox(height: 8),
                AppTextField(label: 'Promotion Price (RM)', hint: '2.80', controller: promoPriceCtrl,
                  keyboardType: TextInputType.number),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String name, category, freshness;
  final String price;
  final String? promoPrice;

  const _PreviewCard({required this.name, required this.category, required this.freshness,
    required this.price, this.promoPrice});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Preview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          Container(
            height: 120, width: double.infinity,
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Icon(Icons.eco_rounded, size: 48, color: AppColors.primary)),
          ),
          const SizedBox(height: 12),
          Text(name.isEmpty ? 'Product Name' : name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(category, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          FreshnessBadge(level: freshness),
          const SizedBox(height: 10),
          if (promoPrice != null && promoPrice!.isNotEmpty) ...[
            Text('RM $price', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
            Text('RM $promoPrice', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ] else
            Text('RM ${price.isEmpty ? '0.00' : price}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ],
      ),
    );
  }
}
