import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String customerCode;
  final String companyName;
  final String contactPerson;
  final String phoneNumber;
  final String email;
  final String businessRegistrationNo;
  final String address;
  final double creditLimit;
  final String creditTerm;
  final String status;
  final double outstandingBalance;
  final double creditScore;
  final List<Map<String, dynamic>> creditHistory;

  const CustomerModel({
    required this.id,
    required this.customerCode,
    required this.companyName,
    required this.contactPerson,
    required this.phoneNumber,
    required this.email,
    required this.businessRegistrationNo,
    required this.address,
    required this.creditLimit,
    required this.creditTerm,
    required this.status,
    this.outstandingBalance = 0,
    this.creditScore = 100.0,
    this.creditHistory = const [],
  });

  double get availableCredit => creditLimit - outstandingBalance;
  bool get isActive => status == 'Active';
  bool get isCreditOverLimit => outstandingBalance >= creditLimit;

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return CustomerModel(
      id: doc.id,
      customerCode: json['customerCode'] ?? '',
      companyName: json['companyName'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      businessRegistrationNo: json['businessRegistrationNo'] ?? '',
      address: json['address'] ?? '',
      creditLimit: (json['creditLimit'] ?? 0).toDouble(),
      creditTerm: json['creditTerm'] ?? 'COD',
      status: json['status'] ?? 'Active',
      outstandingBalance: (json['outstandingBalance'] ?? 0).toDouble(),
      creditScore: (json['creditScore'] ?? 100.0).toDouble(),
      creditHistory: List<Map<String, dynamic>>.from(
        (json['creditHistory'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'customerCode': customerCode,
        'companyName': companyName,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
        'email': email,
        'businessRegistrationNo': businessRegistrationNo,
        'address': address,
        'creditLimit': creditLimit,
        'creditTerm': creditTerm,
        'status': status,
        'outstandingBalance': outstandingBalance,
        'creditScore': creditScore,
        'creditHistory': creditHistory,
      };
}
