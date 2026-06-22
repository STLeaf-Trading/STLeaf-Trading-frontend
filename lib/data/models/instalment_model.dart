import 'package:cloud_firestore/cloud_firestore.dart';

class InstalmentEntry {
  final int periodNumber;
  final DateTime dueDate;
  final double amountDue;
  final String status; // Pending, Paid, Late
  final DateTime? paidAt;
  final bool markedByAdmin;
  final String? adminNote;

  final String? paymentMethod;
  final String? paymentProofUrl;

  const InstalmentEntry({
    required this.periodNumber,
    required this.dueDate,
    required this.amountDue,
    this.status = 'Pending',
    this.paidAt,
    this.markedByAdmin = false,
    this.adminNote,
    this.paymentMethod,
    this.paymentProofUrl,
  });

  bool get isPaid => status == 'Paid';
  bool get isLate => status == 'Late';
  bool get isPending => status == 'Pending';

  factory InstalmentEntry.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }
    return InstalmentEntry(
      periodNumber: map['periodNumber'] ?? 0,
      dueDate: parseDate(map['dueDate']),
      amountDue: (map['amountDue'] ?? 0).toDouble(),
      status: map['status'] ?? 'Pending',
      paidAt: map['paidAt'] != null ? parseDate(map['paidAt']) : null,
      markedByAdmin: map['markedByAdmin'] ?? false,
      adminNote: map['adminNote'],
      paymentMethod: map['paymentMethod'],
      paymentProofUrl: map['paymentProofUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'periodNumber': periodNumber,
    'dueDate': dueDate.toIso8601String(),
    'amountDue': amountDue,
    'status': status,
    if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
    'markedByAdmin': markedByAdmin,
    if (adminNote != null && adminNote!.isNotEmpty) 'adminNote': adminNote,
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
    if (paymentProofUrl != null) 'paymentProofUrl': paymentProofUrl,
  };

  InstalmentEntry copyWith({
    String? status,
    DateTime? paidAt,
    bool? markedByAdmin,
    String? adminNote,
    double? amountDue,
    String? paymentMethod,
    String? paymentProofUrl,
  }) {
    return InstalmentEntry(
      periodNumber: periodNumber,
      dueDate: dueDate,
      amountDue: amountDue ?? this.amountDue,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      markedByAdmin: markedByAdmin ?? this.markedByAdmin,
      adminNote: adminNote ?? this.adminNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
    );
  }
}

class InstalmentPlanModel {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final int numberOfPeriods;
  final String periodUnit; // weeks, months, years
  final double amountPerPeriod;
  final String perPeriodPaymentMethod; // Cash, FPX, TNG
  final String status; // Active, Completed, Overdue
  final DateTime createdAt;
  final List<InstalmentEntry> entries;

  const InstalmentPlanModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.numberOfPeriods,
    required this.periodUnit,
    required this.amountPerPeriod,
    required this.perPeriodPaymentMethod,
    this.status = 'Active',
    required this.createdAt,
    required this.entries,
  });

  double get totalPaid => entries.where((e) => e.isPaid).fold(0.0, (sum, e) => sum + e.amountDue);
  double get totalRemaining => totalAmount - totalPaid;
  int get paidCount => entries.where((e) => e.isPaid).length;
  int get lateCount => entries.where((e) => e.isLate).length;
  bool get isCompleted => paidCount == numberOfPeriods;

  factory InstalmentPlanModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }
    return InstalmentPlanModel(
      id: doc.id,
      orderId: json['orderId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      numberOfPeriods: json['numberOfPeriods'] ?? 1,
      periodUnit: json['periodUnit'] ?? 'months',
      amountPerPeriod: (json['amountPerPeriod'] ?? 0).toDouble(),
      perPeriodPaymentMethod: json['perPeriodPaymentMethod'] ?? 'Cash / COD',
      status: json['status'] ?? 'Active',
      createdAt: parseDate(json['createdAt']),
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((e) => InstalmentEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'customerId': customerId,
    'customerName': customerName,
    'totalAmount': totalAmount,
    'numberOfPeriods': numberOfPeriods,
    'periodUnit': periodUnit,
    'amountPerPeriod': amountPerPeriod,
    'perPeriodPaymentMethod': perPeriodPaymentMethod,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  InstalmentPlanModel copyWith({
    List<InstalmentEntry>? entries,
    String? status,
  }) {
    return InstalmentPlanModel(
      id: id,
      orderId: orderId,
      customerId: customerId,
      customerName: customerName,
      totalAmount: totalAmount,
      numberOfPeriods: numberOfPeriods,
      periodUnit: periodUnit,
      amountPerPeriod: amountPerPeriod,
      perPeriodPaymentMethod: perPeriodPaymentMethod,
      status: status ?? this.status,
      createdAt: createdAt,
      entries: entries ?? this.entries,
    );
  }
}
