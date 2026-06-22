import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return CustomerLayout(
      currentRoute: '/shop/cart',
      child: cart.isEmpty
          ? EmptyState(
              title: 'Your cart is empty',
              subtitle: 'Browse our fresh vegetables and add items to your cart.',
              icon: Icons.shopping_basket_outlined,
              action: AppButton(
                label: 'Browse Products',
                icon: Icons.storefront_rounded,
                onPressed: () => context.go('/shop'),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Cart (${cart.itemCount} items)', style: Theme.of(context).textTheme.headlineMedium),
                      TextButton.icon(
                        onPressed: cart.clear,
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) => _CartItemCard(
                      key: ValueKey(cart.items[i].product.id),
                      item: cart.items[i],
                    ),
                  ),
                ),
                _CartSummary(cart: cart),
              ],
            ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  final CartItem item;
  const _CartItemCard({super.key, required this.item});

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    final qty = widget.item.quantity;
    _qtyCtrl = TextEditingController(
      text: qty == qty.truncate() ? qty.toInt().toString() : qty.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final allProducts = context.watch<ProductProvider>().allProducts;
    final p = allProducts.firstWhere((prod) => prod.id == widget.item.product.id, orElse: () => widget.item.product);
    
    final bool isUnavailable = !p.isActive || p.isOutOfStock;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: isUnavailable ? Colors.grey[300] : AppColors.mint, borderRadius: BorderRadius.circular(12)),
            child: Stack(
              children: [
                Center(child: Icon(Icons.eco_rounded, color: isUnavailable ? Colors.grey[500] : AppColors.primary, size: 28)),
                if (isUnavailable)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Center(
                        child: Text(
                          !p.isActive ? (p.disabledReason?.toUpperCase() ?? 'UNAVAILABLE') : 'OUT OF STOCK',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('RM ${widget.item.product.effectivePrice.toStringAsFixed(2)} / ${widget.item.product.packType}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (widget.item.remarks != null && widget.item.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(4)),
                    child: Text('Note: ${widget.item.remarks}', style: const TextStyle(fontSize: 10, color: AppColors.warning)),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RM ${widget.item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
              const SizedBox(height: 8),
              Row(children: [
                // Decrease
                GestureDetector(
                  onTap: () {
                    final newQty = (widget.item.quantity - 1);
                    if (newQty <= 0) {
                      cart.removeItem(widget.item.product.id);
                    } else {
                      cart.updateQuantity(widget.item.product.id, newQty);
                      _qtyCtrl.text = newQty == newQty.truncate()
                          ? newQty.toInt().toString()
                          : newQty.toStringAsFixed(2);
                    }
                  },
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.remove_rounded, size: 16, color: AppColors.primary),
                  ),
                ),
                // Manual quantity input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 52,
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      enabled: !isUnavailable,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onSubmitted: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          cart.updateQuantity(widget.item.product.id, parsed);
                        } else {
                          final qty = widget.item.quantity;
                          _qtyCtrl.text = qty == qty.truncate() ? qty.toInt().toString() : qty.toStringAsFixed(2);
                        }
                      },
                      onTapOutside: (_) {
                        final parsed = double.tryParse(_qtyCtrl.text);
                        if (parsed != null && parsed > 0) {
                          cart.updateQuantity(widget.item.product.id, parsed);
                        } else {
                          final qty = widget.item.quantity;
                          _qtyCtrl.text = qty == qty.truncate() ? qty.toInt().toString() : qty.toStringAsFixed(2);
                        }
                      },
                    ),
                  ),
                ),
                // Increase
                GestureDetector(
                  onTap: isUnavailable ? null : () {
                    final newQty = widget.item.quantity + 1;
                    cart.updateQuantity(widget.item.product.id, newQty);
                    _qtyCtrl.text = newQty.toInt().toString();
                  },
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: isUnavailable ? Colors.grey[300] : AppColors.mint, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.add_rounded, size: 16, color: isUnavailable ? Colors.grey[500] : AppColors.primary),
                  ),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}


class _CartSummary extends StatelessWidget {
  final CartProvider cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    final allProducts = context.watch<ProductProvider>().allProducts;
    bool hasUnavailableItems = false;
    for (var item in cart.items) {
      final p = allProducts.firstWhere((prod) => prod.id == item.product.id, orElse: () => item.product);
      if (!p.isActive || p.isOutOfStock) {
        hasUnavailableItems = true;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: Column(
        children: [
          _row('Subtotal', 'RM ${cart.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _row('Delivery Fee', 'Calculated at checkout'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('RM ${cart.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: hasUnavailableItems ? 'Remove Unavailable Items' : 'Proceed to Checkout',
            icon: Icons.arrow_forward_rounded,
            width: double.infinity,
            onPressed: hasUnavailableItems ? null : () => context.go('/shop/checkout'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
