import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  Future<void> _updateUser(User? user) async {
    if (user != null) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
      } else {
        _currentUser = UserModel(id: user.uid, email: user.email ?? '', name: 'Unknown', role: 'CUSTOMER');
      }
    } else {
      _currentUser = null;
    }
  }

  Future<void> init() async {
    final initialUser = await _auth.authStateChanges().first;
    await _updateUser(initialUser);

    _auth.authStateChanges().skip(1).listen((User? user) async {
      await _updateUser(user);
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // init() listener will handle currentUser setting
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Login failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
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

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        // Create user doc
        await _db.collection('users').doc(uid).set({
          'email': email,
          'name': contactPerson,
          'role': 'CUSTOMER',
        });
        // Create customer doc
        await _db.collection('customers').doc(uid).set({
          'customerCode': 'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
          'companyName': companyName,
          'contactPerson': contactPerson,
          'phoneNumber': phone,
          'email': email,
          'businessRegistrationNo': '',
          'address': '',
          'creditLimit': 0,
          'creditTerm': 'COD',
          'status': 'Active',
          'outstandingBalance': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';
      // Re-authenticate
      final credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      final uid = user.uid;
      // Delete Firestore docs (orders are NOT deleted — preserved for records)
      await Future.wait([
        _db.collection('customers').doc(uid).delete(),
        _db.collection('users').doc(uid).delete(),
      ]);
      // Delete Firebase Auth account
      await user.delete();
      _currentUser = null;
      notifyListeners();
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Incorrect password. Please try again.';
      }
      return e.message ?? 'Failed to delete account.';
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
