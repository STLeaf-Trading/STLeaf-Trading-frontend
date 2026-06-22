import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/order_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'web_download_stub.dart' if (dart.library.html) 'web_download.dart';

class ExportUtils {
  static const List<String> allAvailableColumns = [
    'Order ID',
    'Customer ID',
    'Customer Name',
    'Order Date',
    'Delivery Date',
    'Delivery Address',
    'Items Bought',
    'Subtotal',
    'Delivery Fee',
    'Total Amount',
    'Payment Method',
    'Payment Status',
    'Order Status',
    'Cancellation Reason',
    'Customer Comment'
  ];

  static String _getCellValue(OrderModel o, String col, DateFormat fmt) {
    switch (col) {
      case 'Order ID': return o.orderId;
      case 'Customer ID': return o.customerId;
      case 'Customer Name': return o.customerName ?? 'Unknown';
      case 'Order Date': return fmt.format(o.orderDate);
      case 'Delivery Date': return fmt.format(o.deliveryDate);
      case 'Delivery Address': return o.deliveryAddress ?? '';
      case 'Items Bought': 
        return o.items.map((i) => '${i.quantity}x ${i.productName}').join('; ');
      case 'Subtotal': return o.subtotal.toStringAsFixed(2);
      case 'Delivery Fee': return o.deliveryFee.toStringAsFixed(2);
      case 'Total Amount': return o.totalAmount.toStringAsFixed(2);
      case 'Payment Method': return o.paymentMethod;
      case 'Payment Status': return o.paymentStatus;
      case 'Order Status': return o.orderStatus;
      case 'Cancellation Reason': return o.cancellationReason ?? '';
      case 'Customer Comment': return o.customerComment ?? '';
      default: return '';
    }
  }

  static Future<void> exportOrdersCsv(List<OrderModel> orders, List<String> selectedColumns, {String fileNamePrefix = 'orders'}) async {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln(selectedColumns.map((c) => '"$c"').join(','));
    
    // Rows
    for (final o in orders) {
      final rowFields = selectedColumns.map((col) {
        final val = _getCellValue(o, col, fmt);
        return '"${val.replaceAll('"', '""')}"';
      });
      buffer.writeln(rowFields.join(','));
    }
    
    final fileName = '${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    
    if (kIsWeb) {
      downloadFileWeb(utf8.encode(buffer.toString()), 'text/csv', fileName);
    } else {
      debugPrint('CSV export is currently only supported on Web.');
    }
  }

  static Future<void> exportOrdersPdf(List<OrderModel> orders, List<String> selectedColumns, {String title = 'Orders Report', String fileNamePrefix = 'orders'}) async {
    final pdf = pw.Document();
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    
    // Determine cell alignments based on column name
    Map<int, pw.Alignment> alignments = {};
    for (int i = 0; i < selectedColumns.length; i++) {
      final c = selectedColumns[i];
      if (['Subtotal', 'Delivery Fee', 'Total Amount'].contains(c)) {
        alignments[i] = pw.Alignment.centerRight;
      } else if (['Order Date', 'Delivery Date', 'Payment Status', 'Order Status'].contains(c)) {
        alignments[i] = pw.Alignment.center;
      } else {
        alignments[i] = pw.Alignment.centerLeft;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}'),
            pw.Text('Total Orders: ${orders.length}'),
            pw.SizedBox(height: 20),
            
            pw.TableHelper.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              headerHeight: 25,
              cellHeight: 25,
              cellAlignments: alignments,
              headers: selectedColumns,
              data: orders.map((o) {
                return selectedColumns.map((col) => _getCellValue(o, col, fmt)).toList();
              }).toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = '${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    
    if (kIsWeb) {
      downloadFileWeb(bytes, 'application/pdf', fileName);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }
}
