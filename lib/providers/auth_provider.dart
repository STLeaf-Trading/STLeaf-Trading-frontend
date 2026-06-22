import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  AuthProvider({FirebaseAuth? auth, FirebaseFirestore? db}) : _auth = auth ?? FirebaseAuth.instance, _db = db ?? FirebaseFirestore.instance;

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
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Enforce email verification for users created after June 22, 2026
      final creationTime = userCredential.user?.metadata.creationTime;
      final enforceVerificationAfter = DateTime(2026, 6, 22); // Today's date
      
      if (creationTime != null && creationTime.isAfter(enforceVerificationAfter)) {
        if (!userCredential.user!.emailVerified) {
          await _auth.signOut();
          _error = 'email_not_verified';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      await _updateUser(userCredential.user);
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
          'creditScore': 100.0,
          'creditHistory': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Send verification email and sign out
        await userCredential.user!.sendEmailVerification();
        await _auth.signOut();
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
    await _updateUser(null);
  }

  Future<bool> resendVerificationEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.sendEmailVerification();
      await _auth.signOut();
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Failed to resend verification email.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to resend verification email.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Failed to send password reset email.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to send password reset email.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No user logged in.';
      // Re-authenticate
      final credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      final uid = user.uid;
      // Delete Firestore docs (customers and orders are NOT deleted — preserved for records)
      await _db.collection('users').doc(uid).delete();
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
