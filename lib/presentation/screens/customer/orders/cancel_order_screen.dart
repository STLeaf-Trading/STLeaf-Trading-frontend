import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class CancelOrderScreen extends StatefulWidget {
  final String orderId;
  const CancelOrderScreen({super.key, required this.orderId});

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  static const _reasons = [
    'Changed my mind',
    'Ordered by mistake',
    'Found a better deal',
    'Delivery taking too long',
    'Duplicate order',
    'Other',
  ];

  String? _selectedReason;
  final _otherCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitCancellation() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a reason for cancellation.'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }
    if (_selectedReason == 'Other' && _otherCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please describe your reason.'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    final reason = _selectedReason == 'Other' ? _otherCtrl.text.trim() : _selectedReason!;

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Order')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await context.read<OrderProvider>().cancelOrder(widget.orderId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order cancelled successfully.'),
          backgroundColor: AppColors.success,
        ));
        context.go('/shop/orders');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerLayout(
      currentRoute: '/shop/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.mint, foregroundColor: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text('Cancel Order', style: Theme.of(context).textTheme.headlineMedium),
            ]),
            const SizedBox(height: 24),

            // Warning Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                SizedBox(width: 12),
                Expanded(child: Text(
                  'Cancellation is only allowed before your order is packed. Once packed, cancellation is not possible.',
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                )),
              ]),
            ),
            const SizedBox(height: 24),

            // Reason selection
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reason for Cancellation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 16),
                  ..._reasons.map((reason) => RadioListTile<String>(
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (v) => setState(() => _selectedReason = v),
                    title: Text(reason, style: const TextStyle(fontSize: 14)),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )),
                  if (_selectedReason == 'Other') ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Please describe your reason',
                      hint: 'Enter your reason here...',
                      controller: _otherCtrl,
                      maxLines: 3,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              label: 'Submit Cancellation',
              icon: Icons.cancel_outlined,
              isDanger: true,
              isLoading: _isLoading,
              width: double.infinity,
              onPressed: _submitCancellation,
            ),
          ],
        ),
      ),
    );
  }
}
