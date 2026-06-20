import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  // Mock users
  static const _mockUsers = [
    {'id': 'USR001', 'email': 'admin@stleaf.com', 'password': 'Admin123!', 'name': 'Admin ST Leaf', 'role': 'ADMIN'},
    {'id': 'USR002', 'email': 'john@abcrestaurant.com', 'password': 'Customer123!', 'name': 'John Lim', 'role': 'CUSTOMER'},
    {'id': 'USR003', 'email': 'mary@goldenpalace.com', 'password': 'Customer123!', 'name': 'Mary Tan', 'role': 'CUSTOMER'},
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final role = prefs.getString('user_role');
    final name = prefs.getString('user_name');
    final id = prefs.getString('user_id');
    if (email != null && role != null) {
      _currentUser = UserModel(id: id ?? '', email: email, name: name ?? '', role: role);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final user = _mockUsers.firstWhere(
        (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );

      if (user.isEmpty) {
        _error = 'Invalid email or password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = UserModel(
        id: user['id']!, email: user['email']!, name: user['name']!, role: user['role']!,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user['id']!);
      await prefs.setString('user_email', user['email']!);
      await prefs.setString('user_name', user['name']!);
      await prefs.setString('user_role', user['role']!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String companyName, required String contactPerson,
    required String phone, required String email, required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));

    _currentUser = UserModel(
      id: 'USR${DateTime.now().millisecondsSinceEpoch}',
      email: email, name: contactPerson, role: 'CUSTOMER',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _currentUser!.id);
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', contactPerson);
    await prefs.setString('user_role', 'CUSTOMER');

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
