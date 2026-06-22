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
  bool _isLoading = false;

  // Time Range
  String _selectedTimeRange = 'Today (1 Day)';
  final List<String> _timeRanges = ['Today (1 Day)', 'Last 7 Days', 'Last 30 Days', 'Last Year', 'All Time', 'Custom Range'];
  DateTime? _startDate;
  DateTime? _endDate;

  // Filters
  CustomerModel? _selectedCustomer;
  bool _filterByCustomer = false;

  // Columns
  final Set<String> _selectedColumns = {
    'Order ID', 'Customer Name', 'Order Date', 'Total Amount', 'Order Status'
  };

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.defaultFormat;
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = isStart 
        ? (_startDate ?? DateTime.now()) 
        : (_endDate ?? _startDate ?? DateTime.now());
        
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _handleExport() async {
    if (_selectedColumns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one metric to export.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    if (_selectedTimeRange == 'Custom Range' && (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates for the custom range.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    if (_filterByCustomer && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer to filter by.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final db = FirebaseFirestore.instance;
      Query query = db.collection('orders').orderBy('createdAt', descending: true);
      
      String fileNamePrefix = 'orders';
      String reportTitle = 'Orders Report';
      
      // Apply Customer Filter
      if (_filterByCustomer && _selectedCustomer != null) {
        query = query.where('customerId', isEqualTo: _selectedCustomer!.id);
        fileNamePrefix = 'orders_${_selectedCustomer!.companyName.replaceAll(' ', '_')}';
        reportTitle = 'Orders Report: ${_selectedCustomer!.companyName}';
      }

      // Apply Time Range Filter
      DateTime? filterStart;
      DateTime? filterEnd;
      final now = DateTime.now();

      switch (_selectedTimeRange) {
        case 'Today (1 Day)':
          filterStart = DateTime(now.year, now.month, now.day);
          fileNamePrefix += '_today';
          reportTitle += ' (Today)';
          break;
        case 'Last 7 Days':
          filterStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
          fileNamePrefix += '_last_7_days';
          reportTitle += ' (Last 7 Days)';
          break;
        case 'Last 30 Days':
          filterStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
          fileNamePrefix += '_last_30_days';
          reportTitle += ' (Last 30 Days)';
          break;
        case 'Last Year':
          filterStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 365));
          fileNamePrefix += '_last_year';
          reportTitle += ' (Last Year)';
          break;
        case 'Custom Range':
          filterStart = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
          filterEnd = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
          fileNamePrefix += '_custom';
          reportTitle += ' (${DateFormat('dd MMM').format(filterStart)} - ${DateFormat('dd MMM yyyy').format(filterEnd)})';
          break;
        case 'All Time':
        default:
          fileNamePrefix += '_all_time';
          break;
      }

      if (filterStart != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(filterStart));
      }
      // Note: Firestore does not allow multiple inequality ranges on different fields or same field easily without composite indexes, 
      // so we filter the end date locally if needed.

      final snap = await query.get();
      List<OrderModel> orders = snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      if (filterEnd != null) {
        orders = orders.where((o) => o.orderDate.isBefore(filterEnd!) || o.orderDate.isAtSameMomentAs(filterEnd!)).toList();
      }

      if (orders.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data found for the selected criteria.'), backgroundColor: AppColors.warning),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Preserve the order of columns as defined in allAvailableColumns
      final columnsToExport = ExportUtils.allAvailableColumns.where((c) => _selectedColumns.contains(c)).toList();

      if (_selectedFormat == 'CSV') {
        await ExportUtils.exportOrdersCsv(orders, columnsToExport, fileNamePrefix: fileNamePrefix);
      } else {
        await ExportUtils.exportOrdersPdf(orders, columnsToExport, title: reportTitle, fileNamePrefix: fileNamePrefix);
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
      title: const Text('Advanced Report Builder', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Format Selection
              const Text('1. Select Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('PDF Report', style: TextStyle(fontWeight: FontWeight.w600)),
                      value: 'PDF',
                      groupValue: _selectedFormat,
                      onChanged: (v) => setState(() => _selectedFormat = v!),
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('CSV Spreadsheet', style: TextStyle(fontWeight: FontWeight.w600)),
                      value: 'CSV',
                      groupValue: _selectedFormat,
                      onChanged: (v) => setState(() => _selectedFormat = v!),
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Time Range Selection
              const Text('2. Select Time Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedTimeRange,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _timeRanges.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedTimeRange = v);
                  }
                },
              ),
              
              if (_selectedTimeRange == 'Custom Range') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(_startDate == null ? 'Start Date' : DateFormat('d MMM yyyy').format(_startDate!), 
                                style: TextStyle(color: _startDate == null ? AppColors.textMuted : AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(_endDate == null ? 'End Date' : DateFormat('d MMM yyyy').format(_endDate!),
                                style: TextStyle(color: _endDate == null ? AppColors.textMuted : AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 32),

              // Customer Filter
              Row(
                children: [
                  const Text('3. Filter by Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
                  const Spacer(),
                  Switch(
                    value: _filterByCustomer,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _filterByCustomer = val),
                  ),
                ],
              ),
              if (_filterByCustomer) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<CustomerModel>(
                  value: _selectedCustomer,
                  hint: const Text('Choose a customer...'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.companyName))).toList(),
                  onChanged: (v) => setState(() => _selectedCustomer = v),
                ),
              ],
              const Divider(height: 32),

              // Metrics Selection
              Row(
                children: [
                  const Text('4. Select Metrics to Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedColumns.length == ExportUtils.allAvailableColumns.length) {
                          _selectedColumns.clear();
                        } else {
                          _selectedColumns.addAll(ExportUtils.allAvailableColumns);
                        }
                      });
                    },
                    child: Text(_selectedColumns.length == ExportUtils.allAvailableColumns.length ? 'Deselect All' : 'Select All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExportUtils.allAvailableColumns.map((col) {
                  final isSelected = _selectedColumns.contains(col);
                  return FilterChip(
                    label: Text('[$col]', style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedColumns.add(col);
                        } else {
                          _selectedColumns.remove(col);
                        }
                      });
                    },
                    selectedColor: AppColors.mint,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        AppButton(
          label: 'Generate Report',
          icon: Icons.download,
          isLoading: _isLoading,
          onPressed: _handleExport,
        ),
      ],
    );
  }
}
