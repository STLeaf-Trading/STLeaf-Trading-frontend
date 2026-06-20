import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/data/models/product_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
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
          _ProductsHeader(onAdd: () => context.go('/admin/products/new')),
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
}

class _ProductsHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const _ProductsHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Products', style: Theme.of(context).textTheme.displaySmall),
              const Text('Manage your product catalog', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          AppButton(label: 'Add Product', icon: Icons.add_rounded, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final ProductProvider provider;
  const _FilterRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
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
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.selectedCategory,
                items: AppConstants.productCategories.map((c) =>
                  DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => provider.setCategory(v!),
              ),
            ),
          ),
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
        final crossCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 700 ? 3 : 2);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.72,
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
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.mint, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(Icons.eco_rounded, size: 52, color: AppColors.primary.withOpacity(0.3))),
                  if (p.hasPromotion)
                    Positioned(top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '${((1 - p.promotionPrice! / p.price) * 100).toStringAsFixed(0)}% OFF',
                          style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  if (p.isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (p.hasPromotion) Text('RM ${p.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
                            Text('RM ${p.effectivePrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                        StatusBadge(status: p.isOutOfStock ? 'Out of Stock' : p.isLowStock ? 'Low Stock' : 'In Stock'),
                      ],
                    ),
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
}
