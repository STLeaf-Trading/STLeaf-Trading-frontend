import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/data/models/product_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

    return CustomerLayout(
      currentRoute: '/shop',
      child: Column(
        children: [
          _HeroBanner(),
          _CategoryFilter(provider: provider),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget(message: 'Loading products...')
                : provider.products.isEmpty
                    ? const EmptyState(title: 'No products available', icon: Icons.eco_outlined)
                    : _ProductGrid(products: provider.products),
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('🌿 Fresh Daily Delivery', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Premium Fresh\nVegetables',
                  style: TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text('Order today, deliver tomorrow', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
              ],
            ),
          ),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/images/logo.jpeg', width: 40, height: 40, fit: BoxFit.cover)),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final ProductProvider provider;
  const _CategoryFilter({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: provider.setSearch,
            decoration: InputDecoration(
              hintText: 'Search vegetables...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
              filled: true, fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: provider.dynamicCategories.map((cat) {
              final isSelected = provider.selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => provider.setCategory(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? AppColors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
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
        final crossCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
        final itemWidth = (constraints.maxWidth - 32 - (crossCount - 1) * 12) / crossCount;
        final itemHeight = (itemWidth * 0.8) + 195; // dynamic height calculation to prevent overflow
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
    final cart = context.read<CartProvider>();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/shop/products/${p.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _hovered ? AppColors.primary.withOpacity(0.3) : AppColors.border),
            boxShadow: [BoxShadow(
              color: _hovered ? AppColors.primary.withOpacity(0.1) : Colors.black.withOpacity(0.04),
              blurRadius: _hovered ? 20 : 8, offset: const Offset(0, 4),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        image: p.imageUrl != null ? DecorationImage(
                          image: NetworkImage(p.imageUrl!), fit: BoxFit.cover
                        ) : null,
                      ),
                      child: p.imageUrl == null ? Center(child: Icon(Icons.eco_rounded, size: 50, color: AppColors.primary.withOpacity(0.3))) : null,
                    ),
                    if (p.hasPromotion)
                      Positioned(top: 8, left: 8, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '${((1 - p.promotionPrice! / p.price) * 100).toStringAsFixed(0)}% OFF',
                          style: const TextStyle(color: AppColors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      )),
                    if (p.isOutOfStock)
                      Positioned.fill(child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Center(child: Text('OUT OF STOCK',
                          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 10))),
                      )),
                  ],
                ),
              ),
              // Info
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FreshnessBadge(level: p.freshnessLevel),
                      const SizedBox(height: 4),
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      if (p.hasPromotion)
                        Text('RM ${p.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
                      Text('RM ${p.effectivePrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: p.isOutOfStock ? null : () {
                            cart.addToCart(p);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p.name} added to cart'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

