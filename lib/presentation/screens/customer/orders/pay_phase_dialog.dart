import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stleaf_trading/core/constants/app_constants.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/presentation/widgets/common/common_widgets.dart';

class PayPhaseDialog extends StatefulWidget {
  final String planId;
  final int entryIndex;
  final double amountDue;

  const PayPhaseDialog({
    super.key,
    required this.planId,
    required this.entryIndex,
    required this.amountDue,
  });

  @override
  State<PayPhaseDialog> createState() => _PayPhaseDialogState();
}

class _PayPhaseDialogState extends State<PayPhaseDialog> {
  String _selectedMethod = 'Cash / COD';
  bool _isLoading = false;
  XFile? _pickedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _pickedImage = file);
    }
  }

  Future<void> _submit() async {
    if (_selectedMethod != 'Cash / COD' && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your payment proof.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? downloadUrl;
      
      if (_pickedImage != null) {
        final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}_${_pickedImage!.name}';
        final storageRef = FirebaseStorage.instance.ref().child('receipts/$fileName');
        
        if (kIsWeb) {
          final bytes = await _pickedImage!.readAsBytes();
          await storageRef.putData(bytes);
        } else {
          await storageRef.putFile(File(_pickedImage!.path));
        }
        
        downloadUrl = await storageRef.getDownloadURL();
      }

      await context.read<InstalmentProvider>().submitPhasePayment(
        planId: widget.planId,
        entryIndex: widget.entryIndex,
        paymentMethod: _selectedMethod,
        paymentProofUrl: downloadUrl,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment submitted for review!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pay Instalment Phase', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount Due: RM ${widget.amountDue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: AppConstants.instalmentPaymentMethods.map((m) {
                final isSel = _selectedMethod == m;
                return ChoiceChip(
                  label: Text(m),
                  selected: isSel,
                  onSelected: (_) => setState(() {
                    _selectedMethod = m;
                    if (m == 'Cash / COD') _pickedImage = null;
                  }),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            if (_selectedMethod != 'Cash / COD') ...[
              const SizedBox(height: 20),
              const Text('Upload Payment Proof', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(_pickedImage == null ? Icons.upload_file_rounded : Icons.check_circle_rounded, 
                           color: _pickedImage == null ? AppColors.primary : AppColors.success, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        _pickedImage == null ? 'Click here to pick an image' : 'Selected: ${_pickedImage!.name}',
                        style: TextStyle(
                          color: _pickedImage == null ? AppColors.primary : AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        AppButton(
          label: 'Submit Payment',
          icon: Icons.check_circle_rounded,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
