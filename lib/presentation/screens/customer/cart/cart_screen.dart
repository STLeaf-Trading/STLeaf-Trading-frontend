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
                    itemBuilder: (ctx, i) => _CartItemCard(item: cart.items[i]),
                  ),
                ),
                _CartSummary(cart: cart),
              ],
            ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('RM ${item.product.effectivePrice.toStringAsFixed(2)} / ${item.product.packType}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(4)),
                    child: Text('Note: ${item.remarks}', style: const TextStyle(fontSize: 10, color: AppColors.warning)),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('RM ${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
              const SizedBox(height: 8),
              Row(children: [
                _qtyBtn(Icons.remove_rounded, () => cart.updateQuantity(item.product.id, item.quantity - 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                _qtyBtn(Icons.add_rounded, () => cart.updateQuantity(item.product.id, item.quantity + 1)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppColors.mint, borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;
  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
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
            label: 'Proceed to Checkout',
            icon: Icons.arrow_forward_rounded,
            width: double.infinity,
            onPressed: () => context.go('/shop/checkout'),
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
