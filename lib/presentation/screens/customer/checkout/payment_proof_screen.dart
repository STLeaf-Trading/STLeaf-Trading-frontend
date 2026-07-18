import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';
import 'dart:typed_data';

/// Screen shown after order is placed for TNG or Maybank Transfer.
/// Displays payment details / QR and lets the user upload a proof screenshot.
class PaymentProofScreen extends StatefulWidget {
  final String orderId;   // Firestore doc ID
  final String orderRef;  // human-readable e.g. ORD-20240101-123
  final String paymentMethod; // 'Touch \'n Go (TNG)' or 'Maybank Transfer'
  final double totalAmount;

  const PaymentProofScreen({
    super.key,
    required this.orderId,
    required this.orderRef,
    required this.paymentMethod,
    required this.totalAmount,
    this.isDeliveryFee = false,
  });

  final bool isDeliveryFee;

  @override
  State<PaymentProofScreen> createState() => _PaymentProofScreenState();
}

class _PaymentProofScreenState extends State<PaymentProofScreen> {
  Uint8List? _imageBytes;
  String? _fileName;
  bool _isUploading = false;
  bool _uploaded = false;

  bool get _isTNG => widget.paymentMethod.contains('TNG') || widget.paymentMethod.contains("Touch");
  bool get _isMaybank => widget.paymentMethod.contains('Maybank');

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName = picked.name;
      });
    }
  }

  Future<void> _uploadProof() async {
    if (_imageBytes == null) return;
    setState(() => _isUploading = true);
    try {
      final ext = _fileName?.split('.').last ?? 'jpg';
      final ref = FirebaseStorage.instance
          .ref('payment_proofs/${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putData(_imageBytes!);
      final url = await ref.getDownloadURL();

      if (widget.isDeliveryFee) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
              'deliveryFeeProofUrl': url,
              'deliveryFeeStatus': 'Under Review',
            });
      } else {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
              'paymentProofUrl': url,
              'paymentStatus': 'Under Review',
            });
      }

      if (mounted) setState(() { _uploaded = true; _isUploading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerLayout(
      currentRoute: '/shop/orders',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.isDeliveryFee ? 'Pay Delivery Fee' : 'Make Payment', style: Theme.of(context).textTheme.headlineMedium),
                Text(widget.orderRef, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ])),
            ]),
            const SizedBox(height: 24),

            // Payment details card
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(_isTNG ? Icons.nfc_rounded : Icons.account_balance_rounded,
                    color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isTNG ? "Touch 'n Go Payment" : 'Maybank Transfer',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ]),
                const SizedBox(height: 16),

                // Amount to pay
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    const Text('Amount to Pay', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    Text(widget.orderRef, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ]),
                ),
                const SizedBox(height: 16),

                if (_isTNG) ...[
                  // TNG QR poster
                  const Text('Scan QR to Pay', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/TNG.jpeg',
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Open your Touch \'n Go eWallet app, tap "Pay", and scan the QR code above.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  ),
                ],

                if (_isMaybank) ...[
                  // Bank account details
                  const Text('Transfer to Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 12),
                  _bankRow('Bank', AppConstants.maybankBankName),
                  const SizedBox(height: 8),
                  _bankRow('Account Name', AppConstants.maybankAccountName),
                  const SizedBox(height: 8),
                  _bankAccountRow(AppConstants.maybankAccountNumber),
                  const SizedBox(height: 12),
                  const Text(
                    'Please use your Order ID as the transfer reference/description.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),

            // Upload proof card
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.upload_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Upload Payment Proof', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Take a screenshot of your payment confirmation and upload it here. Our admin will verify your payment.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),

                if (_uploaded) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text('Payment proof uploaded!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ] else ...[
                  // Preview
                  if (_imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Pick button
                  AppButton(
                    label: _imageBytes == null ? 'Select Screenshot' : 'Change Screenshot',
                    icon: Icons.image_rounded,
                    isOutlined: _imageBytes != null,
                    width: double.infinity,
                    onPressed: _pickImage,
                  ),

                  if (_imageBytes != null) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Submit Payment Proof',
                      icon: Icons.cloud_upload_rounded,
                      isLoading: _isUploading,
                      width: double.infinity,
                      onPressed: _uploadProof,
                    ),
                  ],
                ],
              ]),
            ),
            const SizedBox(height: 20),

            // Skip / Go to orders
            AppButton(
              label: _uploaded ? 'View My Orders' : 'Upload Proof to Proceed',
              icon: Icons.receipt_long_rounded,
              isOutlined: true,
              width: double.infinity,
              onPressed: _uploaded ? () => context.go('/shop/orders') : null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      ],
    );
  }

  Widget _bankAccountRow(String accountNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              accountNumber,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1),
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: accountNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account number copied!'), duration: Duration(seconds: 1)),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
            tooltip: 'Copy',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
