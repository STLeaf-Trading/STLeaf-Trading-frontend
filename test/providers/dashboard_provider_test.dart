import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stleaf_trading/providers/app_providers.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late DashboardProvider provider;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    provider = DashboardProvider(db: fakeDb);
  });

  test('Dashboard aggregates revenue and pending orders correctly', () async {
    final now = DateTime.now();

    // 1. Setup mock products for low stock alert
    await fakeDb.collection('products').add({
      'name': 'Low Stock Item',
      'stockQuantity': 2,
      'lowStockLevel': 5,
      'status': 'Active',
      'price': 10.0,
      'packType': 'kg'
    });
    await fakeDb.collection('products').add({
      'name': 'Good Stock Item',
      'stockQuantity': 20,
      'lowStockLevel': 5,
      'status': 'Active',
      'price': 10.0,
      'packType': 'kg'
    });

    // 2. Setup mock orders
    // Order 1: Today, Paid
    await fakeDb.collection('orders').add({
      'createdAt': Timestamp.fromDate(now),
      'paymentStatus': 'Paid',
      'orderStatus': 'Confirmed',
      'totalAmount': 150.0,
      'items': []
    });

    // Order 2: Today, Pending
    await fakeDb.collection('orders').add({
      'createdAt': Timestamp.fromDate(now),
      'paymentStatus': 'Pending',
      'orderStatus': 'Pending',
      'totalAmount': 50.0,
      'items': []
    });

    // Order 3: Yesterday, Paid
    await fakeDb.collection('orders').add({
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      'paymentStatus': 'Paid',
      'orderStatus': 'Delivered',
      'totalAmount': 200.0,
      'items': []
    });

    // Load dashboard
    await provider.loadStats();

    // Assert: Today's Revenue (all non-cancelled orders from today) = 200.0 (150 + 50)
    expect(provider.stats?.todayRevenue, 200.0);

    // Assert: Today's Total Orders (all statuses today) = 2
    expect(provider.stats?.todayOrders, 2);

    // Assert: Pending orders globally = 1
    expect(provider.stats?.pendingOrders, 1);

    // Assert: Low stock products = 1 (lowStockProducts is an int)
    expect(provider.stats?.lowStockProducts, 1);

    // Assert: 7 Days Revenue chart data includes today and yesterday
    expect(provider.stats?.revenueData.length, 7);
    expect(provider.stats?.revenueData.last.amount, 200.0); // Today
    expect(provider.stats?.revenueData[5].amount, 200.0);   // Yesterday
  });
}
