import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/app_providers.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../utils/export_utils.dart';
import '../../../widgets/common/common_widgets.dart';

class ExportWizardDialog extends StatefulWidget {
  final String defaultFormat; // 'PDF' or 'CSV'

  const ExportWizardDialog({super.key, this.defaultFormat = 'PDF'});

  @override
  State<ExportWizardDialog> createState() => _ExportWizardDialogState();
}

class _ExportWizardDialogState extends State<ExportWizardDialog> {
  late String _selectedFormat;
  String _selectedMetric = 'All Orders';
  CustomerModel? _selectedCustomer;
  bool _isLoading = false;

  final List<String> _metrics = ['All Orders', 'Specific Customer', 'Today', 'Last 7 Days'];

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.defaultFormat;
  }

  Future<void> _handleExport() async {
    setState(() => _isLoading = true);
    
    try {
      final db = FirebaseFirestore.instance;
      Query query = db.collection('orders').orderBy('createdAt', descending: true);
      
      String fileNamePrefix = 'orders';
      String reportTitle = 'Orders Report';
      
      if (_selectedMetric == 'Specific Customer') {
        if (_selectedCustomer == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a customer first.'), backgroundColor: AppColors.danger),
          );
          setState(() => _isLoading = false);
          return;
        }
        query = query.where('customerId', isEqualTo: _selectedCustomer!.id);
        fileNamePrefix = 'orders_${_selectedCustomer!.companyName.replaceAll(' ', '_')}';
        reportTitle = 'Orders Report: ${_selectedCustomer!.companyName}';
      } else if (_selectedMetric == 'Today') {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay));
        fileNamePrefix = 'orders_today';
        reportTitle = 'Orders Report (Today)';
      } else if (_selectedMetric == 'Last 7 Days') {
        final start = DateTime.now().subtract(const Duration(days: 7));
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
        fileNamePrefix = 'orders_last_7_days';
        reportTitle = 'Orders Report (Last 7 Days)';
      }

      final snap = await query.get();
      final List<OrderModel> orders = snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      if (orders.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data found for the selected criteria.'), backgroundColor: AppColors.warning),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (_selectedFormat == 'CSV') {
        await ExportUtils.exportOrdersCsv(orders, fileNamePrefix: fileNamePrefix);
      } else {
        await ExportUtils.exportOrdersPdf(orders, title: reportTitle, fileNamePrefix: fileNamePrefix);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully exported ${orders.length} orders to $_selectedFormat!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;

    return AlertDialog(
      title: const Text('Export Reports', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('PDF'),
                    value: 'PDF',
                    groupValue: _selectedFormat,
                    onChanged: (v) => setState(() => _selectedFormat = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('CSV'),
                    value: 'CSV',
                    groupValue: _selectedFormat,
                    onChanged: (v) => setState(() => _selectedFormat = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Select Metric', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedMetric,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _metrics.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedMetric = v;
                    if (v != 'Specific Customer') _selectedCustomer = null;
                  });
                }
              },
            ),
            if (_selectedMetric == 'Specific Customer') ...[
              const SizedBox(height: 16),
              const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<CustomerModel>(
                value: _selectedCustomer,
                hint: const Text('Choose a customer...'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.companyName))).toList(),
                onChanged: (v) => setState(() => _selectedCustomer = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        AppButton(
          label: 'Export',
          icon: Icons.download,
          isLoading: _isLoading,
          onPressed: _handleExport,
        ),
      ],
    );
  }
}
