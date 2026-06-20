class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? token;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
        role: json['role'] ?? 'CUSTOMER',
        token: json['token'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'token': token,
      };

  bool get isAdmin => role == 'ADMIN';
  bool get isCustomer => role == 'CUSTOMER';
}
