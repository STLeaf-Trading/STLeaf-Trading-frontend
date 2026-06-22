import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/data/models/order_model.dart';
import 'package:stleaf_trading/data/models/instalment_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/providers/auth_provider.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';
import 'package:stleaf_trading/providers/settings_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Cash / COD';
  String _deliveryMethod = 'Deliver by Company';
  bool _isPlacing = false;
  final _commentCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _dbAddress = '';
  bool _isLoadingAddress = true;

  // Instalment config
  String _instalmentPreset = '3 Months';
  int _customPeriods = 3;
  String _customUnit = 'months';

  final _customPeriodsCtrl = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddress());
  }

  Future<void> _loadAddress() async {
    final uid = context.read<AuthProvider>().currentUser?.id;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('customers').doc(uid).get();
        if (mounted) {
          final address = doc.data()?['address'] as String? ?? '';
          _dbAddress = address;
          _addressCtrl.text = address;
          setState(() => _isLoadingAddress = false);
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingAddress = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _customPeriodsCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  int get _effectivePeriods {
    switch (_instalmentPreset) {
      case '1 Month': return 1;
      case '3 Months': return 3;
      case '6 Months': return 6;
      default: return _customPeriods;
    }
  }

  String get _effectiveUnit {
    if (_instalmentPreset != 'Custom') return 'months';
    return _customUnit;
  }

  DateTime _dueDate(int periodIndex) {
    final now = DateTime.now();
    switch (_effectiveUnit) {
      case 'weeks':
        return now.add(Duration(days: 7 * (periodIndex + 1)));
      case 'years':
        return DateTime(now.year + (periodIndex + 1), now.month, now.day);
      default: // months
        final m = now.month + (periodIndex + 1);
        return DateTime(now.year + (m - 1) ~/ 12, ((m - 1) % 12) + 1, now.day);
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final instalmentProvider = context.read<InstalmentProvider>();
    final settings = context.read<SettingsProvider>();

    final double actualDeliveryFee = _deliveryMethod == 'Pickup' ? 0.0 : settings.deliveryFee;
    final double actualTotalAmount = cart.subtotal + actualDeliveryFee;

    // Address validation
    String finalAddress = '';
    if (_deliveryMethod == 'Deliver by Company') {
      final uid = auth.currentUser?.id;
      if (uid == null) { setState(() => _isPlacing = false); return; }
      
      finalAddress = _addressCtrl.text.trim();
      if (finalAddress.isEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Address Required'),
            content: const Text('Please enter a delivery address to proceed.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
        setState(() => _isPlacing = false);
        return;
      }

      if (finalAddress != _dbAddress && _dbAddress.isNotEmpty) {
        if (!mounted) return;
        final bool? shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Update Profile Address?'),
            content: const Text('You have entered a different delivery address. Would you like to save this new address to your profile for future orders?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, Just for this order')),
              AppButton(label: 'Yes, Update Profile', onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        );
        
        if (shouldUpdate == null) {
          setState(() => _isPlacing = false);
          return; // User dismissed the dialog
        }
        
        if (shouldUpdate) {
          try {
            await FirebaseFirestore.instance.collection('customers').doc(uid).update({'address': finalAddress});
          } catch (e) {
            debugPrint('Failed to update address: $e');
          }
        }
      } else if (_dbAddress.isEmpty && finalAddress.isNotEmpty) {
         try {
            await FirebaseFirestore.instance.collection('customers').doc(uid).update({'address': finalAddress});
         } catch (e) {
            debugPrint('Failed to update address: $e');
         }
      }
    }

    final orderId = 'ORD-${DateFormat('yyyyMMdd').format(DateTime.now())}-${DateTime.now().millisecondsSinceEpoch % 1000}';
    final order = OrderModel(
      id: const Uuid().v4(),
      orderId: orderId,
      customerId: auth.currentUser?.id ?? '',
      customerName: auth.currentUser?.name ?? '',
      orderDate: DateTime.now(),
      deliveryDate: DateTime.now().add(const Duration(days: 1)),
      subtotal: cart.subtotal,
      deliveryFee: actualDeliveryFee,
      totalAmount: actualTotalAmount,
      paymentMethod: _paymentMethod,
      paymentStatus: 'Pending',
      orderStatus: 'Pending',
      deliveryAddress: _deliveryMethod == 'Pickup' ? 'Pickup' : finalAddress,
      customerComment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      items: cart.items.map((i) => OrderItemModel(
        productId: i.product.id,
        productName: i.product.name,
        itemCode: i.product.itemCode,
        packType: i.product.packType,
        product: i.product,
        quantity: i.quantity,
        price: i.product.effectivePrice,
        subtotal: i.subtotal,
        remarks: i.remarks,
      )).toList(),
    );
    OrderModel? placedOrder;
    try {
      placedOrder = await orderProvider.placeOrder(order);
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.danger),
        );
      }
      return;
    }

    // Create instalment plan if selected
    if (_paymentMethod == 'Instalment' && placedOrder != null) {
      final periods = _effectivePeriods;
      final amtPerPeriod = actualTotalAmount / periods;
      final entries = List.generate(periods, (i) => InstalmentEntry(
        periodNumber: i + 1,
        dueDate: _dueDate(i),
        amountDue: amtPerPeriod,
        status: 'Pending',
      ));

      final plan = InstalmentPlanModel(
        id: '',
        orderId: placedOrder.id,
        customerId: auth.currentUser?.id ?? '',
        customerName: auth.currentUser?.name ?? '',
        totalAmount: actualTotalAmount,
        numberOfPeriods: periods,
        periodUnit: _effectiveUnit,
        amountPerPeriod: amtPerPeriod,
        perPeriodPaymentMethod: 'Decided per phase',
        createdAt: DateTime.now(),
        entries: entries,
      );

      final planId = await instalmentProvider.createPlan(plan);
      // Update order with instalmentPlanId
      await FirebaseFirestore.instance.collection('orders').doc(placedOrder.id).update({
        'instalmentPlanId': planId,
      });
    }

    await cart.clear();

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
              Text(orderId, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
              const SizedBox(height: 8),
              const Text('Your order will be delivered tomorrow.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              AppButton(
                label: 'Track My Order',
                icon: Icons.local_shipping_rounded,
                width: double.infinity,
                onPressed: () { Navigator.pop(ctx); context.go('/shop/orders'); },
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
    final settings = context.watch<SettingsProvider>();
    final double actualDeliveryFee = _deliveryMethod == 'Pickup' ? 0.0 : settings.deliveryFee;
    final double actualTotalAmount = cart.subtotal + actualDeliveryFee;

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
                if (_paymentMethod == 'Instalment') ...[
                  _instalmentConfigCard(actualTotalAmount),
                  const SizedBox(height: 16),
                ],
                _orderItemsCard(cart),
                const SizedBox(height: 16),
                _orderCommentCard(),
              ],
            );
            final summary = _OrderSummary(
              cart: cart,
              paymentMethod: _paymentMethod,
              deliveryFee: actualDeliveryFee,
              totalAmount: actualTotalAmount,
              isPlacing: _isPlacing,
              onPlace: _placeOrder,
            );

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
        Row(children: [
          Expanded(child: RadioListTile<String>(
            value: 'Pickup', groupValue: _deliveryMethod,
            onChanged: (v) => setState(() => _deliveryMethod = v!),
            activeColor: AppColors.primary,
            title: const Text('Pickup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: _deliveryMethod == 'Pickup' ? AppColors.mint : null,
          )),
          const SizedBox(width: 10),
          Expanded(child: RadioListTile<String>(
            value: 'Deliver by Company', groupValue: _deliveryMethod,
            onChanged: (v) => setState(() => _deliveryMethod = v!),
            activeColor: AppColors.primary,
            title: const Text('Deliver by Company', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            tileColor: _deliveryMethod == 'Deliver by Company' ? AppColors.mint : null,
          )),
        ]),
        if (_deliveryMethod == 'Deliver by Company') ...[
          const SizedBox(height: 16),
          const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          if (_isLoadingAddress)
            const CircularProgressIndicator()
          else
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter your full delivery address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
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
        ],
        const SizedBox(height: 14),
        Text('Recipient: ${auth.currentUser?.name ?? ""}', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${_deliveryMethod == 'Pickup' ? 'Pickup' : 'Delivery'}: Tomorrow morning',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
          if (method == 'FPX (Online Banking)') icon = Icons.language_rounded;
          if (method == 'Touch \'n Go (TNG)') icon = Icons.nfc_rounded;
          if (method == 'Instalment') icon = Icons.calendar_month_rounded;

          return RadioListTile<String>(
            value: method, groupValue: _paymentMethod,
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

  Widget _instalmentConfigCard(double totalAmount) {
    final periods = _effectivePeriods;
    final amtPerPeriod = periods > 0 ? totalAmount / periods : totalAmount;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Instalment Plan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 16),

        // Period presets
        const Text('Period', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: AppConstants.instalmentPresets.map((preset) {
            final isSelected = _instalmentPreset == preset;
            return ChoiceChip(
              label: Text(preset),
              selected: isSelected,
              onSelected: (_) => setState(() => _instalmentPreset = preset),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Custom period input
        if (_instalmentPreset == 'Custom') ...[
          Row(children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _customPeriodsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Number of periods',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null && parsed > 0) setState(() => _customPeriods = parsed);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _customUnit,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: ['weeks', 'months', 'years'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _customUnit = v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),
        ],


        // Preview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontSize: 13, color: AppColors.primary)),
              Text('RM ${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$periods × per ${_effectiveUnit.replaceAll('s', '')}',
                style: const TextStyle(fontSize: 13, color: AppColors.primary)),
              Text('RM ${amtPerPeriod.toStringAsFixed(2)} each',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
            const Divider(height: 16, color: AppColors.primaryLight),
            Text('First payment due: ${DateFormat('d MMM yyyy').format(_dueDate(0))}',
              style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ]),
        ),
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
            Expanded(child: Text(
              '${item.product.name} × ${item.quantity == item.quantity.truncate() ? item.quantity.toInt() : item.quantity.toStringAsFixed(2)} ${item.product.packType}',
              style: const TextStyle(fontSize: 14))),
            Text('RM ${item.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        )),
      ]),
    );
  }

  Widget _orderCommentCard() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Order Notes (Optional)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(
            hintText: 'Any special instructions, delivery notes, or comments for the admin...',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ]),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  final String paymentMethod;
  final double deliveryFee;
  final double totalAmount;
  final bool isPlacing;
  final VoidCallback onPlace;

  const _OrderSummary({
    required this.cart,
    required this.paymentMethod,
    required this.deliveryFee,
    required this.totalAmount,
    required this.isPlacing,
    required this.onPlace,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Order Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _row('Subtotal', 'RM ${cart.subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _row('Delivery Fee', 'RM ${deliveryFee.toStringAsFixed(2)}'),
        _row('Payment', paymentMethod),
        const Divider(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text('RM ${totalAmount.toStringAsFixed(2)}',
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
