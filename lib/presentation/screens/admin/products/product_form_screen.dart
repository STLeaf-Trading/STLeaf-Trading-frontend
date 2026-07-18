import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
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

class _ProductSizeRow {
  String unit;
  TextEditingController priceCtrl;
  TextEditingController promoCtrl;

  _ProductSizeRow({required this.unit, String price = '', String promo = ''})
      : priceCtrl = TextEditingController(text: price),
        promoCtrl = TextEditingController(text: promo);

  void dispose() {
    priceCtrl.dispose();
    promoCtrl.dispose();
  }
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: AppConstants.productCategories.first);
  final _descCtrl = TextEditingController();
  final _precautionCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _lowStockCtrl = TextEditingController(text: '10');

  double _freshnessValue = 10;
  bool _isSaving = false;
  
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  
  final List<_ProductSizeRow> _sizes = [];

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProduct());
    } else {
      _itemCodeCtrl.text = 'VEG-${DateTime.now().millisecondsSinceEpoch % 1000}';
      _sizes.add(_ProductSizeRow(unit: 'Kg'));
    }
  }

  void _loadProduct() {
    final products = context.read<ProductProvider>().allProducts;
    final p = products.firstWhere((p) => p.id == widget.productId, orElse: () => products.first);
    _itemCodeCtrl.text = p.itemCode;
    _nameCtrl.text = p.name;
    _categoryCtrl.text = p.category;
    _descCtrl.text = p.description;
    _precautionCtrl.text = p.precaution;
    _stockCtrl.text = p.stockQuantity.toString();
    _lowStockCtrl.text = p.lowStockLevel.toString();
    _existingImageUrl = p.imageUrl;
    _freshnessValue = p.freshnessLevel.toDouble();
    
    for (final s in p.sizes) {
      _sizes.add(_ProductSizeRow(
        unit: s.unit,
        price: s.price.toString(),
        promo: s.promotionPrice?.toString() ?? '',
      ));
    }
    if (_sizes.isEmpty) _sizes.add(_ProductSizeRow(unit: 'Kg'));
    
    setState(() {});
  }

  @override
  void dispose() {
    _itemCodeCtrl.dispose(); _nameCtrl.dispose(); _categoryCtrl.dispose();
    _descCtrl.dispose(); _precautionCtrl.dispose(); 
    _stockCtrl.dispose(); _lowStockCtrl.dispose();
    for (final s in _sizes) { s.dispose(); }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PickerOption(icon: Icons.camera_alt_rounded, label: 'Camera', onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              }),
              _PickerOption(icon: Icons.photo_library_rounded, label: 'Gallery', onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one product size/price')));
      return;
    }
    
    final provider = context.read<ProductProvider>();
    final code = _itemCodeCtrl.text.trim();
    if (!provider.isItemCodeUnique(code, widget.productId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item Code "$code" is already in use.'), backgroundColor: AppColors.danger)
      );
      return;
    }

    setState(() => _isSaving = true);

    String? finalImageUrl = _existingImageUrl;
    if (_selectedImageBytes != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await provider.uploadProductImage(_selectedImageBytes!, fileName);
      if (url != null) finalImageUrl = url;
    }

    final productSizes = _sizes.map((s) => ProductSizeModel(
      unit: s.unit,
      price: double.tryParse(s.priceCtrl.text) ?? 0,
      promotionPrice: s.promoCtrl.text.isNotEmpty ? double.tryParse(s.promoCtrl.text) : null,
    )).toList();

    final product = ProductModel(
      id: widget.productId ?? const Uuid().v4(),
      itemCode: code,
      name: _nameCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      precaution: _precautionCtrl.text.trim(),
      freshnessLevel: _freshnessValue.toInt(),
      sizes: productSizes,
      stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
      lowStockLevel: int.tryParse(_lowStockCtrl.text) ?? 10,
      imageUrl: finalImageUrl,
      status: 'Active',
    );

    if (_isEditing) {
      await provider.updateProduct(product);
    } else {
      await provider.addProduct(product);
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

  void _addSize() {
    setState(() => _sizes.add(_ProductSizeRow(unit: 'Kg')));
  }

  void _removeSize(int index) {
    setState(() {
      _sizes[index].dispose();
      _sizes.removeAt(index);
    });
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
                  final isWide = constraints.maxWidth > 800;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _FormSection(
                          itemCodeCtrl: _itemCodeCtrl, nameCtrl: _nameCtrl, categoryCtrl: _categoryCtrl,
                          descCtrl: _descCtrl, precautionCtrl: _precautionCtrl, 
                          stockCtrl: _stockCtrl, lowStockCtrl: _lowStockCtrl,
                          freshnessValue: _freshnessValue,
                          onFreshnessChanged: (v) => setState(() => _freshnessValue = v),
                          onImagePick: _showImagePickerModal,
                          imageBytes: _selectedImageBytes,
                          existingImageUrl: _existingImageUrl,
                          sizes: _sizes,
                          onAddSize: _addSize,
                          onRemoveSize: _removeSize,
                          onSizeUnitChanged: (index, val) => setState(() => _sizes[index].unit = val),
                        )),
                        const SizedBox(width: 24),
                        SizedBox(width: 260, child: _PreviewCard(
                          name: _nameCtrl.text, category: _categoryCtrl.text,
                          freshnessLevel: _freshnessValue.toInt(),
                          imageBytes: _selectedImageBytes,
                          existingImageUrl: _existingImageUrl,
                          defaultPrice: _sizes.isNotEmpty ? _sizes.first.priceCtrl.text : '0',
                          defaultPromo: _sizes.isNotEmpty ? _sizes.first.promoCtrl.text : '',
                        )),
                      ],
                    );
                  }
                  return _FormSection(
                    itemCodeCtrl: _itemCodeCtrl, nameCtrl: _nameCtrl, categoryCtrl: _categoryCtrl,
                    descCtrl: _descCtrl, precautionCtrl: _precautionCtrl,
                    stockCtrl: _stockCtrl, lowStockCtrl: _lowStockCtrl, 
                    freshnessValue: _freshnessValue,
                    onFreshnessChanged: (v) => setState(() => _freshnessValue = v),
                    onImagePick: _showImagePickerModal,
                    imageBytes: _selectedImageBytes,
                    existingImageUrl: _existingImageUrl,
                    sizes: _sizes,
                    onAddSize: _addSize,
                    onRemoveSize: _removeSize,
                    onSizeUnitChanged: (index, val) => setState(() => _sizes[index].unit = val),
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

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final TextEditingController itemCodeCtrl, nameCtrl, categoryCtrl, descCtrl, precautionCtrl, stockCtrl, lowStockCtrl;
  final double freshnessValue;
  final ValueChanged<double> onFreshnessChanged;
  final VoidCallback onImagePick;
  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final List<_ProductSizeRow> sizes;
  final VoidCallback onAddSize;
  final Function(int) onRemoveSize;
  final Function(int, String) onSizeUnitChanged;

  const _FormSection({
    required this.itemCodeCtrl, required this.nameCtrl, required this.categoryCtrl,
    required this.descCtrl, required this.precautionCtrl, 
    required this.stockCtrl, required this.lowStockCtrl, 
    required this.freshnessValue, required this.onFreshnessChanged,
    required this.onImagePick, this.imageBytes, this.existingImageUrl,
    required this.sizes, required this.onAddSize, required this.onRemoveSize, required this.onSizeUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 500;
      
      Widget responsiveRow(List<Widget> children) {
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.where((w) => w is Expanded).map((w) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: (w as Expanded).child,
              );
            }).toList(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      }

      return Column(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Basic Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 20),
                
                // Image Picker Row
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(12),
                        image: imageBytes != null
                            ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover)
                            : (existingImageUrl != null
                                ? DecorationImage(image: NetworkImage(existingImageUrl!), fit: BoxFit.cover)
                                : null),
                      ),
                      child: (imageBytes == null && existingImageUrl == null)
                          ? const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 32)
                          : null,
                    ),
                    AppButton(
                      label: 'Choose Image',
                      isOutlined: true,
                      icon: Icons.upload_rounded,
                      onPressed: onImagePick,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                responsiveRow([
                  Expanded(child: AppTextField(label: 'Item Code *', hint: 'e.g. VEG-001', controller: itemCodeCtrl,
                    validator: (v) => (v == null || v.isEmpty) ? 'Item code is required' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: AppTextField(label: 'Product Name *', hint: 'e.g. Kangkung', controller: nameCtrl,
                    validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null)),
                ]),
                if (!isNarrow) const SizedBox(height: 16),
                
                responsiveRow([
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      RawAutocomplete<String>(
                        textEditingController: categoryCtrl,
                        focusNode: FocusNode(),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          // Use dynamicCategories so that any categories from existing
                          // products also appear as suggestions — not just the hardcoded list.
                          final allCats = context.read<ProductProvider>().dynamicCategories
                              .where((c) => c != 'All')
                              .toList();
                          if (textEditingValue.text.isEmpty) return allCats;
                          return allCats.where((String option) =>
                              option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Type or select category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              child: SizedBox(
                                height: 200,
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: options.map((opt) => ListTile(
                                    title: Text(opt),
                                    onTap: () => onSelected(opt),
                                  )).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          const Text('Freshness Level *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                          Text('${freshnessValue.toInt()} / 10', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: freshnessValue,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: freshnessValue.toInt().toString(),
                          onChanged: onFreshnessChanged,
                        ),
                      ),
                    ],
                  )),
                ]),
                if (!isNarrow) const SizedBox(height: 16),
                
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sizes & Pricing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    if (sizes.length < 4)
                      TextButton.icon(
                        onPressed: onAddSize, 
                        icon: const Icon(Icons.add_rounded), 
                        label: const Text('Add Size')
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sizes.length,
                  separatorBuilder: (ctx, _) => const Divider(height: 32),
                  itemBuilder: (ctx, i) {
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Unit Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                              if (sizes.length > 1)
                                GestureDetector(
                                  onTap: () => onRemoveSize(i),
                                  child: const Text('Remove', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: sizes[i].unit.isNotEmpty ? sizes[i].unit : 'Kg',
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: AppConstants.productUnitTypes.map((String val) {
                              return DropdownMenuItem(value: val, child: Text(val));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) onSizeUnitChanged(i, val);
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: AppTextField(label: 'Price (RM)', hint: 'Optional', controller: sizes[i].priceCtrl, keyboardType: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: AppTextField(label: 'Promo (RM)', hint: 'Optional', controller: sizes[i].promoCtrl, keyboardType: TextInputType.number)),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Unit Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: sizes[i].unit.isNotEmpty ? sizes[i].unit : 'Kg',
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                items: AppConstants.productUnitTypes.map((String val) {
                                  return DropdownMenuItem(value: val, child: Text(val));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) onSizeUnitChanged(i, val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(label: 'Price (RM)', hint: 'Optional', controller: sizes[i].priceCtrl, keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: AppTextField(label: 'Promo (RM)', hint: 'Optional', controller: sizes[i].promoCtrl, keyboardType: TextInputType.number)),
                        if (sizes.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 28, left: 12),
                            child: IconButton(
                              onPressed: () => onRemoveSize(i),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                
                const Divider(height: 48),
                const Text('Inventory Stock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 16),
                responsiveRow([
                  Expanded(child: AppTextField(label: 'Stock Quantity *', hint: '100', controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Stock is required' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: AppTextField(label: 'Low Stock Level', hint: '10', controller: lowStockCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null)),
                ]),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _PreviewCard extends StatelessWidget {
  final String name, category;
  final int freshnessLevel;
  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final String defaultPrice;
  final String defaultPromo;

  const _PreviewCard({required this.name, required this.category, required this.freshnessLevel,
    this.imageBytes, this.existingImageUrl, required this.defaultPrice, required this.defaultPromo});

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
            decoration: BoxDecoration(
              color: AppColors.mint, 
              borderRadius: BorderRadius.circular(12),
              image: imageBytes != null
                  ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover)
                  : (existingImageUrl != null
                      ? DecorationImage(image: NetworkImage(existingImageUrl!), fit: BoxFit.cover)
                      : null),
            ),
            child: (imageBytes == null && existingImageUrl == null)
                ? const Center(child: Icon(Icons.eco_rounded, size: 48, color: AppColors.primary))
                : null,
          ),
          const SizedBox(height: 12),
          Text(name.isEmpty ? 'Product Name' : name,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(category.isEmpty ? 'Category' : category, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          FreshnessBadge(level: freshnessLevel),
          const SizedBox(height: 10),
          if (defaultPromo.isNotEmpty) ...[
            Text('RM $defaultPrice', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
            Text('RM $defaultPromo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ] else
            Text('RM ${defaultPrice.isEmpty ? '0.00' : defaultPrice}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ],
      ),
    );
  }
}
