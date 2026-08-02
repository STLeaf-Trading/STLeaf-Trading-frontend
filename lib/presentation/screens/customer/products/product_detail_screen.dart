import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/data/models/product_model.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/common/cached_product_image.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  double _quantity = 1.0;
  ProductSizeModel? _selectedSize;
  final TextEditingController _remarksController = TextEditingController();
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _updateQtyUI() {
    _qtyCtrl.text = _quantity == _quantity.truncate()
        ? _quantity.toInt().toString()
        : _quantity.toStringAsFixed(2);
  }

  void _increment(int maxStock) {
    if (_quantity < maxStock) {
      setState(() {
        _quantity++;
        _updateQtyUI();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Max stock available: $maxStock'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 1)),
      );
    }
  }

  void _decrement() => setState(() {
        if (_quantity > 1) {
          _quantity--;
          _updateQtyUI();
        }
      });

  void _setQuantity(double val, int maxStock) {
    if (val > maxStock) {
      setState(() {
        _quantity = maxStock.toDouble();
        _updateQtyUI();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Max stock available: $maxStock'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 1)),
      );
    } else if (val > 0) {
      setState(() => _quantity = val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().allProducts;
    final cart = context.read<CartProvider>();
    final p = products.isNotEmpty
        ? products.firstWhere((p) => p.id == widget.productId,
            orElse: () => products.first)
        : null;

    if (p == null) {
      return const CustomerLayout(
          currentRoute: '/shop', child: LoadingWidget());
    }

    void addToCart() {
      try {
        final size = _selectedSize ?? p.defaultSize;
        if (size == null)
          throw Exception('No size available for this product.');

        cart.addToCart(p, size,
            quantity: _quantity, remarks: _remarksController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${p.name} (${size.unit}) x$_quantity added to cart!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 1),
        ));
        Future.delayed(const Duration(milliseconds: 800), () {
          if (context.mounted) Navigator.pop(context);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ProductImage(product: p)),
                          const SizedBox(width: 32),
                          Expanded(
                              child: _ProductInfo(
                            product: p,
                            selectedSize: _selectedSize ?? p.defaultSize,
                            onSizeChange: (s) =>
                                setState(() => _selectedSize = s),
                            quantity: _quantity,
                            qtyCtrl: _qtyCtrl,
                            onIncrease: () => _increment(p.stockQuantity),
                            onDecrease: _decrement,
                            onQuantityChange: (val) =>
                                _setQuantity(val, p.stockQuantity),
                            onAddToCart: addToCart,
                            remarksController: _remarksController,
                          )),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _ProductImage(product: p),
                        const SizedBox(height: 20),
                        _ProductInfo(
                          product: p,
                          selectedSize: _selectedSize ?? p.defaultSize,
                          onSizeChange: (s) =>
                              setState(() => _selectedSize = s),
                          quantity: _quantity,
                          qtyCtrl: _qtyCtrl,
                          onIncrease: () => _increment(p.stockQuantity),
                          onDecrease: _decrement,
                          onQuantityChange: (val) =>
                              _setQuantity(val, p.stockQuantity),
                          onAddToCart: addToCart,
                          remarksController: _remarksController,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
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
    return GestureDetector(
      onTap: () {
        if (product.imageUrl != null) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.broken_image, color: Colors.white, size: 80),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            CachedProductImage(
              imageUrl: product.imageUrl,
              width: double.infinity,
              height: 320,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(20),
              iconSize: 120,
            ),
            if (product.hasPromotion)
              Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${((1 - product.defaultSize!.promotionPrice! / product.defaultSize!.price) * 100).toStringAsFixed(0)}% OFF',
                      style: const TextStyle(
                          color: AppColors.white, fontWeight: FontWeight.w800),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final ProductModel product;
  final ProductSizeModel? selectedSize;
  final ValueChanged<ProductSizeModel> onSizeChange;
  final double quantity;
  final TextEditingController qtyCtrl;
  final VoidCallback onIncrease, onDecrease, onAddToCart;
  final ValueChanged<double> onQuantityChange;
  final TextEditingController remarksController;

  const _ProductInfo({
    required this.product,
    required this.selectedSize,
    required this.onSizeChange,
    required this.quantity,
    required this.qtyCtrl,
    required this.onIncrease,
    required this.onDecrease,
    required this.onQuantityChange,
    required this.onAddToCart,
    required this.remarksController,
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
          StatusBadge(
              status: p.isOutOfStock
                  ? 'Out of Stock'
                  : p.isLowStock
                      ? 'Low Stock'
                      : 'In Stock'),
        ]),
        const SizedBox(height: 12),
        Text(p.name, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(p.category,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (selectedSize != null) ...[
            Text('RM ${selectedSize!.effectivePrice.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const SizedBox(width: 8),
            if (selectedSize!.hasPromotion)
              Text('RM ${selectedSize!.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough)),
            const Spacer(),
            Text('/${selectedSize!.unit}',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ]),
        const SizedBox(height: 20),

        if (p.sizes.isNotEmpty) ...[
          const Text('Size / Unit',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.sizes.map((s) {
              final isSelected = selectedSize == s;
              return ChoiceChip(
                label: Text(s.unit,
                    style: TextStyle(
                        color:
                            isSelected ? AppColors.white : AppColors.primary)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.mint,
                side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border),
                onSelected: (_) => onSizeChange(s),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Description
        if (p.description.isNotEmpty) ...[
          AppCard(
            color: AppColors.mint,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text('Product Description',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ]),
              const SizedBox(height: 8),
              Text(p.description,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        if (p.precaution.isNotEmpty)
          AppCard(
            color: AppColors.warningLight,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.warning_amber_rounded,
                    size: 16, color: AppColors.warning),
                SizedBox(width: 6),
                Text('Precaution & Storage',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning)),
              ]),
              const SizedBox(height: 8),
              Text(p.precaution,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
            ]),
          ),
        const SizedBox(height: 24),

        // Qty selector
        LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 350;

          Widget qtySelector = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Quantity:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                    style: IconButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null && parsed > 0) {
                          onQuantityChange(parsed);
                        } else {
                          qtyCtrl.text = quantity == quantity.truncate()
                              ? quantity.toInt().toString()
                              : quantity.toStringAsFixed(2);
                        }
                      },
                      onTapOutside: (_) {
                        final parsed = double.tryParse(qtyCtrl.text);
                        if (parsed != null && parsed > 0) {
                          onQuantityChange(parsed);
                        } else {
                          qtyCtrl.text = quantity == quantity.truncate()
                              ? quantity.toInt().toString()
                              : quantity.toStringAsFixed(2);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: onIncrease,
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                ]),
              ),
            ],
          );

          final currentSize = selectedSize ?? p.defaultSize;
          final currentPrice = currentSize?.effectivePrice ?? p.effectivePrice;
          Widget totalText = Text(
            'Total: RM ${(currentPrice * quantity).toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                qtySelector,
                const SizedBox(height: 12),
                totalText,
              ],
            );
          }

          return Row(
            children: [
              qtySelector,
              const Spacer(),
              totalText,
            ],
          );
        }),
        const SizedBox(height: 16),

        // Remarks
        const Text('Additional Notes (Optional):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: remarksController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'E.g., Please pick the ripest ones...',
            hintStyle:
                const TextStyle(fontSize: 13, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 24),

        Row(children: [
          Expanded(
              child: AppButton(
            label: 'Add to Cart',
            icon: Icons.shopping_basket_rounded,
            onPressed: (!product.isActive || product.isOutOfStock)
                ? null
                : onAddToCart,
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
