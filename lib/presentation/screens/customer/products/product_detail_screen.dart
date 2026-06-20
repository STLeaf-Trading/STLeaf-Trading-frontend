import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().allProducts;
    final cart = context.read<CartProvider>();
    final p = products.isNotEmpty
        ? products.firstWhere((p) => p.id == widget.productId, orElse: () => products.first)
        : null;

    if (p == null) {
      return CustomerLayout(currentRoute: '/shop', child: const LoadingWidget());
    }

    return CustomerLayout(
      currentRoute: '/shop',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ProductImage(product: p)),
                  const SizedBox(width: 32),
                  Expanded(child: _ProductInfo(
                    product: p, quantity: _quantity,
                    onIncrease: () => setState(() => _quantity++),
                    onDecrease: () => setState(() { if (_quantity > 1) _quantity--; }),
                    onAddToCart: () {
                      cart.addToCart(p, quantity: _quantity);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${p.name} x$_quantity added to cart!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));
                    },
                  )),
                ],
              );
            }
            return Column(
              children: [
                _ProductImage(product: p),
                const SizedBox(height: 20),
                _ProductInfo(
                  product: p, quantity: _quantity,
                  onIncrease: () => setState(() => _quantity++),
                  onDecrease: () => setState(() { if (_quantity > 1) _quantity--; }),
                  onAddToCart: () {
                    cart.addToCart(p, quantity: _quantity);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${p.name} x$_quantity added to cart!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final product;
  const _ProductImage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(20),
        image: product.imageUrl != null ? DecorationImage(
          image: NetworkImage(product.imageUrl!), fit: BoxFit.cover
        ) : null,
      ),
      child: Stack(
        children: [
          if (product.imageUrl == null)
            Center(child: Icon(Icons.eco_rounded, size: 120, color: AppColors.primary.withOpacity(0.25))),
          if (product.hasPromotion)
            Positioned(top: 16, left: 16, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${((1 - product.promotionPrice / product.price) * 100).toStringAsFixed(0)}% OFF',
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
              ),
            )),
        ],
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final product;
  final int quantity;
  final VoidCallback onIncrease, onDecrease, onAddToCart;

  const _ProductInfo({
    required this.product, required this.quantity,
    required this.onIncrease, required this.onDecrease, required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          FreshnessBadge(level: p.freshnessLevel),
          const SizedBox(width: 8),
          StatusBadge(status: p.isOutOfStock ? 'Out of Stock' : p.isLowStock ? 'Low Stock' : 'In Stock'),
        ]),
        const SizedBox(height: 12),
        Text(p.name, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(p.category, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('RM ${p.effectivePrice.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(width: 8),
          if (p.hasPromotion) Text('RM ${p.price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, color: AppColors.textMuted, decoration: TextDecoration.lineThrough)),
          const Spacer(),
          Text('/${p.packType} · ${p.weightKg}kg', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ]),
        const SizedBox(height: 20),

        // Description
        AppCard(
          color: AppColors.mint,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Product Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
            const SizedBox(height: 8),
            Text(p.description, style: const TextStyle(fontSize: 14, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 12),
        if (p.precaution.isNotEmpty) AppCard(
          color: AppColors.warningLight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
              SizedBox(width: 6),
              Text('Precaution & Storage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning)),
            ]),
            const SizedBox(height: 8),
            Text(p.precaution, style: const TextStyle(fontSize: 13, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 24),

        // Qty selector
        Row(children: [
          const Text('Quantity:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              IconButton(
                onPressed: onDecrease,
                icon: const Icon(Icons.remove_rounded),
                style: IconButton.styleFrom(foregroundColor: AppColors.primary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: onIncrease,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ]),
          ),
          const Spacer(),
          Text(
            'Total: RM ${(p.effectivePrice * quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ]),
        const SizedBox(height: 20),

        Row(children: [
          Expanded(child: AppButton(
            label: 'Add to Cart',
            icon: Icons.shopping_basket_rounded,
            onPressed: p.isOutOfStock ? null : onAddToCart,
            width: double.infinity,
          )),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => context.go('/shop/cart'),
            icon: const Icon(Icons.shopping_cart_checkout_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.mint,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ]),
      ],
    );
  }
}
