import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  double _deliveryFee = 15.00;
  bool _isLoading = false;
  StreamSubscription? _sub;

  double get deliveryFee => _deliveryFee;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    loadSettings();
  }

  void loadSettings() {
    _sub?.cancel();
    _sub = _db.collection('settings').doc('general').snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final feeRaw = data['deliveryFee'];
        if (feeRaw is num) {
          _deliveryFee = feeRaw.toDouble();
        } else if (feeRaw is String) {
          _deliveryFee = double.tryParse(feeRaw) ?? 15.00;
        } else {
          _deliveryFee = 15.00;
        }
        notifyListeners();
      } else {
        // Create default settings if they don't exist
        _db.collection('settings').doc('general').set({
          'deliveryFee': 15.00,
        });
      }
    });
  }

  Future<void> updateDeliveryFee(double newFee) async {
    _isLoading = true;
    notifyListeners();
    
    await _db.collection('settings').doc('general').set({
      'deliveryFee': newFee,
    }, SetOptions(merge: true));
    
    _isLoading = false;
    notifyListeners();
  }
}
