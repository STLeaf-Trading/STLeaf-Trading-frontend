import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/data/models/order_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Cash';
  bool _isPlacing = false;

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    final order = OrderModel(
      id: const Uuid().v4(),
      orderId: 'ORD-${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch % 1000}',
      customerId: auth.currentUser?.id ?? '',
      customerName: auth.currentUser?.name ?? '',
      orderDate: DateTime.now(),
      deliveryDate: DateTime.now().add(const Duration(days: 1)),
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      totalAmount: cart.total,
      paymentMethod: _paymentMethod,
      paymentStatus: 'Pending',
      orderStatus: 'Pending',
      items: cart.items.map((i) => OrderItemModel(
        id: const Uuid().v4(), orderId: '',
        productId: i.product.id, product: i.product,
        quantity: i.quantity, price: i.product.effectivePrice, subtotal: i.subtotal,
      )).toList(),
      createdAt: DateTime.now(),
    );

    await orderProvider.placeOrder(order);
    cart.clear();

    if (mounted) {
      setState(() => _isPlacing = false);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 20),
              Text('Order Placed!', style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(order.orderId, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
              const SizedBox(height: 8),
              const Text('Your order will be delivered tomorrow.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              AppButton(
                label: 'Track My Order',
                icon: Icons.local_shipping_rounded,
                width: double.infinity,
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/shop/orders');
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return CustomerLayout(
      currentRoute: '/shop',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Checkout', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 20),
                _deliveryInfoCard(context),
                const SizedBox(height: 16),
                _paymentMethodCard(),
                const SizedBox(height: 16),
                _orderItemsCard(cart),
              ],
            );
            final summary = _OrderSummary(cart: cart, paymentMethod: _paymentMethod,
              isPlacing: _isPlacing, onPlace: _placeOrder);

            if (isWide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: content),
                const SizedBox(width: 24),
                SizedBox(width: 300, child: summary),
              ]);
            }
            return Column(children: [content, const SizedBox(height: 16), summary]);
          },
        ),
      ),
    );
  }

  Widget _deliveryInfoCard(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Delivery Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(AppConstants.deliveryPolicy,
              style: const TextStyle(fontSize: 13, color: AppColors.primary))),
          ]),
        ),
        const SizedBox(height: 14),
        Text('Recipient: ${auth.currentUser?.name ?? ""}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Delivery: Tomorrow morning', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ]),
    );
  }

  Widget _paymentMethodCard() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Payment Method', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 16),
        ...AppConstants.paymentMethods.map((method) {
          IconData icon = Icons.money_rounded;
          if (method == 'Bank Transfer') icon = Icons.account_balance_rounded;
          if (method == 'Credit Term') icon = Icons.credit_score_rounded;

          return RadioListTile<String>(
            value: method,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
            activeColor: AppColors.primary,
            title: Row(children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(method, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: _paymentMethod == method ? AppColors.mint : null,
          );
        }),
      ]),
    );
  }

  Widget _orderItemsCard(CartProvider cart) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Order Items (${cart.items.length})',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
        const SizedBox(height: 12),
        ...cart.items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            const Icon(Icons.eco_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text('${item.product.name} x${item.quantity}',
              style: const TextStyle(fontSize: 14))),
            Text('RM ${item.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        )),
      ]),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  final String paymentMethod;
  final bool isPlacing;
  final VoidCallback onPlace;

  const _OrderSummary({required this.cart, required this.paymentMethod, required this.isPlacing, required this.onPlace});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Order Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _row('Subtotal', 'RM ${cart.subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _row('Delivery Fee', 'RM ${cart.deliveryFee.toStringAsFixed(2)}'),
        _row('Payment', paymentMethod),
        const Divider(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text('RM ${cart.total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ]),
        const SizedBox(height: 20),
        AppButton(
          label: 'Place Order',
          icon: Icons.check_circle_rounded,
          isLoading: isPlacing,
          width: double.infinity,
          onPressed: cart.isEmpty ? null : onPlace,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Back to Cart', isOutlined: true,
          width: double.infinity,
          onPressed: () => context.go('/shop/cart'),
        ),
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
