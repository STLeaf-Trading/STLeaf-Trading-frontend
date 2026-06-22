import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:stleaf_trading/providers/app_providers.dart';
import 'package:stleaf_trading/data/models/instalment_model.dart';
import 'package:stleaf_trading/data/models/order_model.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late InstalmentProvider provider;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    provider = InstalmentProvider(db: fakeDb);
  });

  test('markPeriodPaid updates debt and syncs with order', () async {
    // 1. Setup mock order
    final orderRef = fakeDb.collection('orders').doc('order_123');
    await orderRef.set({
      'id': 'order_123',
      'orderId': 'ORD-123',
      'customerId': 'cust_1',
      'paymentStatus': 'Pending',
      'orderStatus': 'Confirmed',
    });

    // 2. Setup mock instalment plan
    final planRef = fakeDb.collection('instalments').doc('plan_123');
    await planRef.set({
      'id': 'plan_123',
      'orderId': 'order_123',
      'customerId': 'cust_1',
      'totalAmount': 300.0,
      'numberOfPeriods': 3,
      'periodUnit': 'months',
      'amountPerPeriod': 100.0,
      'status': 'Active',
      'entries': [
        {
          'periodNumber': 1,
          'dueDate': DateTime.now().toIso8601String(),
          'amountDue': 100.0,
          'status': 'Pending',
        },
        {
          'periodNumber': 2,
          'dueDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'amountDue': 100.0,
          'status': 'Pending',
        },
        {
          'periodNumber': 3,
          'dueDate': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
          'amountDue': 100.0,
          'status': 'Pending',
        }
      ]
    });

    // 3. Setup mock customer for credit score update
    final custRef = fakeDb.collection('customers').doc('cust_1');
    await custRef.set({
      'id': 'cust_1',
      'creditScore': 80,
    });

    // Action: Mark first period paid
    await provider.markPeriodPaid(
      planId: 'plan_123',
      customerId: 'cust_1',
      entryIndex: 0,
      isLate: false,
    );

    // Assert: First period is paid
    var planDoc = await planRef.get();
    expect(planDoc.data()!['entries'][0]['status'], 'Paid');
    expect(planDoc.data()!['status'], 'Active'); // Plan is still active

    // Assert: Order status is still Pending
    var orderDoc = await orderRef.get();
    expect(orderDoc.data()!['paymentStatus'], 'Pending');

    // Action: Mark remaining periods paid
    await provider.markPeriodPaid(
      planId: 'plan_123',
      customerId: 'cust_1',
      entryIndex: 1,
      isLate: false,
    );
    await provider.markPeriodPaid(
      planId: 'plan_123',
      customerId: 'cust_1',
      entryIndex: 2,
      isLate: false,
    );

    // Assert: Plan is completed
    planDoc = await planRef.get();
    expect(planDoc.data()!['status'], 'Completed');

    // Assert: Order is now Paid
    orderDoc = await orderRef.get();
    expect(orderDoc.data()!['paymentStatus'], 'Paid');

    // Assert: Credit score increased
    final custDoc = await custRef.get();
    expect(custDoc.data()!['creditScore'], 95.0); // 80 + (3 * 5) for 3 on-time payments
  });
}
