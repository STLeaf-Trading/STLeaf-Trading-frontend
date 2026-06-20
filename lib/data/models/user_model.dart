import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? token; // This might be unused in Firebase Auth, but kept for compatibility

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.token,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'role': role,
        'token': token,
      };

  bool get isAdmin => role == 'ADMIN';
  bool get isCustomer => role == 'CUSTOMER';
}
