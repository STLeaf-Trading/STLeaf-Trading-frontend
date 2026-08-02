import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/data/models/product_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/common/cached_product_image.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return AdminLayout(
      currentRoute: '/admin/products',
      child: Column(
        children: [
          _ProductsHeader(
            onAdd: () => context.go('/admin/products/new'),
            onManageCategories: () => _showCategoryManager(context),
          ),
          _FilterRow(provider: provider),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget(message: 'Loading products...')
                : provider.products.isEmpty
                    ? EmptyState(
                        title: 'No products found',
                        subtitle: 'Add your first product to get started',
                        icon: Icons.inventory_2_outlined,
                        action: AppButton(
                          label: 'Add Product',
                          icon: Icons.add_rounded,
                          onPressed: () => context.go('/admin/products/new'),
                        ),
                      )
                    : _ProductGrid(products: provider.products),
          ),
        ],
      ),
    );
  }

  void _showCategoryManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CategoryManagerSheet(),
    );
  }
}

class _ProductsHeader extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onManageCategories;
  const _ProductsHeader({required this.onAdd, required this.onManageCategories});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        spacing: 8,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Products', style: Theme.of(context).textTheme.displaySmall),
              const Text('Manage your product catalog', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.category_rounded, size: 16),
              label: const Text('Categories'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: onManageCategories,
            ),
            AppButton(label: 'Add Product', icon: Icons.add_rounded, onPressed: onAdd),
          ]),
        ],
      ),
    );
  }
}

// ─── Category Manager Bottom Sheet ────────────────────────────────────────────
class _CategoryManagerSheet extends StatefulWidget {
  const _CategoryManagerSheet();
  @override
  State<_CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<_CategoryManagerSheet> {
  final _addCtrl = TextEditingController();
  String? _editingCategory; // category currently being renamed
  final _editCtrl = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _addCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _addCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isBusy = true);
    await context.read<CategoryProvider>().addCategory(name);
    _addCtrl.clear();
    setState(() => _isBusy = false);
  }

  Future<void> _rename(String oldName) async {
    final newName = _editCtrl.text.trim();
    if (newName.isEmpty || newName == oldName) {
      setState(() => _editingCategory = null);
      return;
    }
    setState(() => _isBusy = true);
    await context.read<CategoryProvider>().renameCategory(oldName, newName);
    setState(() { _isBusy = false; _editingCategory = null; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Renamed "$oldName" → "$newName" and updated all products'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _delete(BuildContext ctx, String name) async {
    // Confirm first
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category'),
        content: Text(
          'Delete "$name"?\n\nAll products in this category will be moved to "Uncategorised".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    final count = await context.read<CategoryProvider>().deleteCategory(name);
    setState(() => _isBusy = false);

    if (!mounted) return;
    if (count > 0) {
      await showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: const [
            Icon(Icons.info_outline_rounded, color: AppColors.warning),
            SizedBox(width: 10),
            Text('Products Moved'),
          ]),
          content: Text(
            '$count product${count == 1 ? '' : 's'} '
            'had the "$name" category and '
            '${count == 1 ? 'has' : 'have'} been moved to "Uncategorised".\n\n'
            'Please reassign them to the correct category.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('OK, Got It'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final prodProvider = context.watch<ProductProvider>();
    
    // Merge managed categories and any currently used in products
    final Set<String> merged = {};
    merged.addAll(catProvider.categories);
    merged.addAll(prodProvider.dynamicCategories.where((c) => c != 'All'));
    final categories = merged.toList()..sort();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Manage Categories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text('Edit, rename or remove product categories', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ),
                  if (_isBusy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),

            // Category list
            Expanded(
              child: categories.isEmpty && !catProvider.isLoading
                  ? const Center(child: Text('No categories yet', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final cat = categories[i];
                        final isEditing = _editingCategory == cat;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.label_rounded, color: AppColors.primary, size: 18),
                          ),
                          title: isEditing
                              ? TextField(
                                  controller: _editCtrl,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                  ),
                                  onSubmitted: (_) => _rename(cat),
                                )
                              : Text(cat, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          trailing: isEditing
                              ? Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
                                    onPressed: () => _rename(cat),
                                    tooltip: 'Save rename',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                                    onPressed: () => setState(() => _editingCategory = null),
                                    tooltip: 'Cancel',
                                  ),
                                ])
                              : Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                                    onPressed: () => setState(() {
                                      _editingCategory = cat;
                                      _editCtrl.text = cat;
                                    }),
                                    tooltip: 'Rename',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                    onPressed: _isBusy ? null : () => _delete(ctx, cat),
                                    tooltip: 'Delete',
                                  ),
                                ]),
                        );
                      },
                    ),
            ),

            // Add new category input
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'New category name...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    ),
                    onPressed: _isBusy ? null : _add,
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

class _FilterRow extends StatelessWidget {
  final ProductProvider provider;
  const _FilterRow({required this.provider});

  static const _sortOptions = [
    ('itemCode', 'Item Code'),
    ('name', 'Name'),
    ('price', 'Price (RM)'),
    ('stock', 'Stock Qty'),
    ('category', 'Category'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final searchField = TextField(
      onChanged: provider.setSearch,
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
        filled: true, fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    final categoryDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: isMobile,
          value: provider.dynamicCategories.contains(provider.selectedCategory)
              ? provider.selectedCategory
              : (provider.dynamicCategories.isNotEmpty ? provider.dynamicCategories.first : null),
          items: provider.dynamicCategories.map((c) =>
            DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) {
            if (v != null) provider.setCategory(v);
          },
        ),
      ),
    );

    final sortDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: isMobile,
          value: provider.sortField,
          items: _sortOptions.map(((String, String) opt) =>
            DropdownMenuItem(
              value: opt.$1,
              child: Text(opt.$2, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            )).toList(),
          onChanged: (v) {
            if (v != null) provider.setSorting(v, provider.sortAscending);
          },
        ),
      ),
    );

    final sortBtn = IconButton(
      tooltip: provider.sortAscending ? 'Sort Ascending' : 'Sort Descending',
      onPressed: () => provider.setSorting(provider.sortField, !provider.sortAscending),
      icon: Icon(
        provider.sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
        color: AppColors.primary, size: 20,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 20, isMobile ? 16 : 28, 12),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 12),
                categoryDropdown,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: sortDropdown),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: sortBtn,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                categoryDropdown,
                const SizedBox(width: 8),
                sortDropdown,
                const SizedBox(width: 4),
                sortBtn,
              ],
            ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 700 ? 3 : (constraints.maxWidth > 500 ? 2 : 1));
        final itemWidth = (constraints.maxWidth - 56 - (crossCount - 1) * 16) / crossCount;
        const itemHeight = 130 + 225.0; // 130px for image + 225px for content
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemCount: products.length,
          itemBuilder: (ctx, i) => _ProductCard(product: products[i]),
        );
      },
    );
  }
}

class _ProductCard extends StatefulWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? AppColors.primary.withOpacity(0.3) : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: _hovered ? AppColors.primary.withOpacity(0.1) : Colors.black.withOpacity(0.04),
              blurRadius: _hovered ? 20 : 8, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 130,
              child: Stack(
                children: [
                  CachedProductImage(
                    imageUrl: p.imageUrl,
                    width: double.infinity,
                    height: 130,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    iconSize: 52,
                  ),
                  if (p.hasPromotion)
                    Positioned(top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '${((1 - p.defaultSize!.promotionPrice! / p.defaultSize!.price) * 100).toStringAsFixed(0)}% OFF',
                          style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  if (p.isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38, borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Center(child: Text('OUT OF STOCK',
                          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 12))),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.itemCode, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    FreshnessBadge(level: p.freshnessLevel),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.hasPromotion) Text('RM ${p.defaultSize!.price.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
                              Text('${p.sizes.length > 1 ? 'From ' : ''}RM ${p.effectivePrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        StatusBadge(status: !p.isActive ? 'Unavailable' : p.isOutOfStock ? 'Out of Stock' : p.isLowStock ? 'Low Stock' : 'In Stock'),
                      ],
                    ),
                    if (!p.isActive && p.disabledReason != null) ...[
                      const SizedBox(height: 4),
                      Text('Reason: ${p.disabledReason}', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
                    ],
                    const SizedBox(height: 10),
                    Text('Stock: ${p.stockQuantity} units',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/admin/products/${p.id}/edit'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Edit', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _toggleStatus(context, p),
                          icon: Icon(p.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, size: 18),
                          tooltip: p.isActive ? 'Make Unavailable' : 'Make Active',
                          style: IconButton.styleFrom(
                            foregroundColor: p.isActive ? AppColors.warning : AppColors.success,
                            backgroundColor: p.isActive ? AppColors.warningLight : AppColors.successLight,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _confirmDelete(context, p),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          style: IconButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            backgroundColor: AppColors.dangerLight,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(p.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product deleted'), backgroundColor: AppColors.danger),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(BuildContext context, ProductModel p) {
    if (!p.isActive) {
      // Make active
      final updated = ProductModel(
        id: p.id, itemCode: p.itemCode, name: p.name, category: p.category, description: p.description, precaution: p.precaution, freshnessLevel: p.freshnessLevel, sizes: p.sizes, stockQuantity: p.stockQuantity, lowStockLevel: p.lowStockLevel, imageUrl: p.imageUrl,
        status: 'Active',
        disabledReason: null,
      );
      context.read<ProductProvider>().updateProduct(updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product marked as Active')));
      return;
    }

    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Make Product Unavailable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a reason for disabling this product. This will be shown to customers.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Recalled, Season Ended',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              final updated = ProductModel(
                id: p.id, itemCode: p.itemCode, name: p.name, category: p.category, description: p.description, precaution: p.precaution, freshnessLevel: p.freshnessLevel, sizes: p.sizes, stockQuantity: p.stockQuantity, lowStockLevel: p.lowStockLevel, imageUrl: p.imageUrl,
                status: 'Inactive',
                disabledReason: reason.isEmpty ? 'Unavailable' : reason,
              );
              context.read<ProductProvider>().updateProduct(updated);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product marked as Unavailable')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }
}
