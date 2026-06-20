import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/order_model.dart';
import '../data/models/customer_model.dart';
import 'package:flutter/foundation.dart';

class ExportUtils {
  static Future<void> exportOrdersCsv(List<OrderModel> orders, {String fileNamePrefix = 'orders'}) async {
    final fmt = DateFormat('yyyy-MM-dd');
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Order ID,Customer,Order Date,Delivery Date,Payment Method,Subtotal,Delivery Fee,Total,Status,Payment Status,Cancellation Reason');
    
    // Rows
    for (final o in orders) {
      final reason = (o.cancellationReason ?? '').replaceAll(',', ';');
      buffer.writeln('${o.orderId},"${o.customerName ?? ''}",${fmt.format(o.orderDate)},${fmt.format(o.deliveryDate)},${o.paymentMethod},${o.subtotal.toStringAsFixed(2)},${o.deliveryFee.toStringAsFixed(2)},${o.totalAmount.toStringAsFixed(2)},${o.orderStatus},${o.paymentStatus},"$reason"');
    }
    
    final blob = html.Blob([buffer.toString()], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final fileName = '${fileNamePrefix}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> exportOrdersPdf(List<OrderModel> orders, {String title = 'Orders Report', String fileNamePrefix = 'orders'}) async {
    final pdf = pw.Document();
    final fmt = DateFormat('yyyy-MM-dd');
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
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
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
              headers: ['Order ID', 'Customer', 'Date', 'Total (RM)', 'Status'],
              data: orders.map((o) {
                return [
                  o.orderId,
                  o.customerName ?? 'Unknown',
                  fmt.format(o.orderDate),
                  o.totalAmount.toStringAsFixed(2),
                  o.orderStatus,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName = '${fileNamePrefix}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    
    if (kIsWeb) {
      // Direct download on web
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Use printing package for mobile/desktop to share/print
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }
}
