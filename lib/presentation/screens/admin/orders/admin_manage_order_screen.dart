import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/data/models/order_model.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/admin_layout.dart';

class AdminManageOrderScreen extends StatefulWidget {
  const AdminManageOrderScreen({super.key});

  @override
  State<AdminManageOrderScreen> createState() => _AdminManageOrderScreenState();
}

class _AdminManageOrderScreenState extends State<AdminManageOrderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final activeOrders = orderProvider.allOrders
        .where((o) => o.orderStatus == 'Pending')
        .toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    return AdminLayout(
      currentRoute: '/admin/manage-order',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MANAGE ORDER',
                    style: Theme.of(context).textTheme.displaySmall),
                Text(
                  DateFormat('d MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: orderProvider.isLoading
                ? const LoadingWidget()
                : activeOrders.isEmpty
                    ? const EmptyState(
                        title: 'No active orders',
                        icon: Icons.receipt_long_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
                        itemCount: activeOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) =>
                            _CustomerOrderCard(order: activeOrders[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-Customer Order Card ──────────────────────────────────────────────────
class _CustomerOrderCard extends StatefulWidget {
  final OrderModel order;
  const _CustomerOrderCard({required this.order});

  @override
  State<_CustomerOrderCard> createState() => _CustomerOrderCardState();
}

class _CustomerOrderCardState extends State<_CustomerOrderCard> {
  late final List<TextEditingController> _priceControllers;
  late final List<String> _selectedUnits;
  late final TextEditingController _feeCtrl;
  bool _isSaving = false;
  late bool _isEditing;

  bool get _isDelivery =>
      widget.order.deliveryAddress != null &&
      widget.order.deliveryAddress != 'Pickup' &&
      widget.order.deliveryAddress!.isNotEmpty;

  List<String> get _availableUnits {
    final set = Set<String>.from(AppConstants.productUnitTypes);
    set.addAll(_selectedUnits);
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    final hasSavedPrices = widget.order.finalSubtotal != null && widget.order.finalSubtotal! > 0;
    _isEditing = !hasSavedPrices;

    _priceControllers = widget.order.items.map((item) {
      final ctrl = TextEditingController(
        text: item.price > 0 ? item.price.toStringAsFixed(2) : '',
      );
      ctrl.addListener(() => setState(() {}));
      return ctrl;
    }).toList();
    
    _selectedUnits = widget.order.items.map((item) => item.packType).toList();

    _feeCtrl = TextEditingController(
      text: widget.order.deliveryFee > 0
          ? widget.order.deliveryFee.toStringAsFixed(2)
          : '',
    );
    _feeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in _priceControllers) {
      c.removeListener(() {});
      c.dispose();
    }
    _feeCtrl.removeListener(() {});
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final orderProvider = context.read<OrderProvider>();
      double newSubtotal = 0;
      final updatedItems = widget.order.items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final price =
            double.tryParse(_priceControllers[i].text.trim()) ?? item.price;
        final subtotal = price * item.quantity;
        newSubtotal += subtotal;
        return {
          'productId': item.productId,
          'productName': item.productName,
          'itemCode': item.itemCode,
          'packType': _selectedUnits[i],
          'quantity': item.quantity,
          'price': price,
          'subtotal': subtotal,
          if (item.remarks != null && item.remarks!.isNotEmpty)
            'remarks': item.remarks,
        };
      }).toList();

      final fee =
          _isDelivery ? (double.tryParse(_feeCtrl.text.trim()) ?? 0.0) : 0.0;

      await orderProvider.updateOrderFields(widget.order.id, {
        'items': updatedItems,
        'finalSubtotal': newSubtotal,
        'deliveryFee': fee,
        'totalAmount': newSubtotal + fee,
      });

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final customers = context.watch<CustomerProvider>().customers;
    final customer = customers.where((c) => c.id == order.customerId).firstOrNull;
    final phone = customer?.phoneNumber ?? '';
    final address = _isDelivery ? (order.deliveryAddress ?? '') : '';
    
    double calculatedSubtotal = 0;
    for (int i = 0; i < order.items.length; i++) {
      final price = double.tryParse(_priceControllers[i].text.trim()) ?? 0.0;
      calculatedSubtotal += price * order.items[i].quantity;
    }
    final calculatedFee = _isDelivery ? (double.tryParse(_feeCtrl.text.trim()) ?? 0.0) : 0.0;
    final calculatedGrandTotal = calculatedSubtotal + calculatedFee;

    return AppCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Customer header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.person_rounded,
                            size: 14, color: AppColors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Customer: ${order.customerName ?? '-'}',
                          style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                        ),
                      ]),
                      if (phone.isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.phone_rounded,
                              size: 13, color: AppColors.white),
                          const SizedBox(width: 4),
                          Text('Phone No: $phone',
                              style: const TextStyle(
                                  color: AppColors.white, fontSize: 13)),
                        ]),
                      if (address.isNotEmpty)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.location_on_rounded,
                              size: 13, color: AppColors.white),
                          const SizedBox(width: 4),
                          Text('Address: $address',
                              style: const TextStyle(
                                  color: AppColors.white, fontSize: 13)),
                        ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isDelivery
                            ? Icons.local_shipping_rounded
                            : Icons.store_rounded,
                        size: 12,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isDelivery ? 'Delivery' : 'Pickup',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Today's Order Price label ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              const Icon(Icons.price_change_rounded,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text("Today's Order Price",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 8),

          // ── Table ───────────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: constraints.maxWidth > 560 ? constraints.maxWidth : 560,
                  child: Column(
                    children: [
                      // ── Table header ───────────────────────────────────────────────
                      Container(
                        color: AppColors.mint,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('Product',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.primary)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('Total Qty',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.primary)),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text("Today's Price",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.primary)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text("Total Price",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.primary),
                                  textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      ),

                      // ── Item rows ─────────────────────────────────────────────────
                      ...order.items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final isEven = i % 2 == 0;
                        
                        final price = double.tryParse(_priceControllers[i].text.trim()) ?? 0.0;
                        final subtotal = price * item.quantity;
                        
                        return Container(
                          color: isEven ? Colors.transparent : AppColors.surface,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(item.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${item.quantity == item.quantity.truncate() ? item.quantity.toInt() : item.quantity.toStringAsFixed(2)} ${item.packType}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Row(
                                  children: [
                                    const Text('RM ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.primary)),
                                    Expanded(
                                      child: _isEditing 
                                        ? TextField(
                                            controller: _priceControllers[i],
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                    decimal: true),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700, fontSize: 13),
                                            decoration: InputDecoration(
                                              hintText: '0.00',
                                              hintStyle: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 12),
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 7),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide:
                                                    const BorderSide(color: AppColors.border),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                    color: AppColors.primary, width: 2),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            _priceControllers[i].text.isEmpty ? '0.00' : _priceControllers[i].text,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('/',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.textSecondary)),
                                    const SizedBox(width: 4),
                                    _isEditing 
                                      ? DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedUnits[i],
                                            isDense: true,
                                            icon: const Icon(Icons.arrow_drop_down, size: 18),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary),
                                            items: _availableUnits.map((u) {
                                              return DropdownMenuItem(
                                                value: u,
                                                child: Text(u),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() => _selectedUnits[i] = val);
                                              }
                                            },
                                          ),
                                        )
                                      : Text(
                                          _selectedUnits[i],
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'RM ${subtotal.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1),

          // ── Delivery fee (delivery orders only) ───────────────────────
          if (_isDelivery)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 15, color: AppColors.info),
                  const SizedBox(width: 6),
                  const Text('Delivery Fee:',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.info)),
                  const Spacer(),
                  const Text('RM ',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.info)),
                  SizedBox(
                    width: 100,
                    child: _isEditing
                      ? TextField(
                          controller: _feeCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.info, width: 2),
                            ),
                          ),
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _feeCtrl.text.isEmpty ? '0.00' : _feeCtrl.text,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          
          // ── Grand Total ────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Total Price:',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.primary)),
                const SizedBox(width: 16),
                Text(
                  'RM ${calculatedGrandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Action buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isEditing)
                  AppButton(
                    label: 'Save',
                    icon: Icons.save_rounded,
                    isLoading: _isSaving,
                    onPressed: _save,
                  )
                else
                  AppButton(
                    label: 'Edit',
                    icon: Icons.edit_rounded,
                    isOutlined: true,
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
