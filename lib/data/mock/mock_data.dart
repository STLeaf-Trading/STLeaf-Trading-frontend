import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/order_model.dart';
import '../models/inventory_model.dart';

class MockData {
  // ─────────────────────────────────────────────
  // PRODUCTS
  // ─────────────────────────────────────────────
  static final List<ProductModel> products = [
    ProductModel(
      id: 'P001', itemCode: 'VEG-001', name: 'Kangkung (Water Spinach)',
      category: 'Leafy Vegetable', description: 'Fresh water spinach, ideal for stir-fry dishes.',
      precaution: 'Store in cool place. Use within 2 days.', freshnessLevel: 'Very Fresh',
      packType: 'Bundle', weightKg: 0.5, price: 3.50, promotionPrice: 2.80,
      stockQuantity: 120, status: 'Active', createdAt: DateTime(2024, 1, 10),
    ),
    ProductModel(
      id: 'P002', itemCode: 'VEG-002', name: 'Sawi (Mustard Green)',
      category: 'Leafy Vegetable', description: 'Crispy mustard greens, perfect for soups and stir-fry.',
      precaution: 'Keep refrigerated.', freshnessLevel: 'Fresh',
      packType: 'Bundle', weightKg: 0.5, price: 2.80,
      stockQuantity: 85, status: 'Active', createdAt: DateTime(2024, 1, 10),
    ),
    ProductModel(
      id: 'P003', itemCode: 'VEG-003', name: 'Bayam (Spinach)',
      category: 'Leafy Vegetable', description: 'Tender green spinach, rich in iron and nutrients.',
      precaution: 'Consume within 1-2 days of purchase.', freshnessLevel: 'Premium Fresh',
      packType: 'Bundle', weightKg: 0.4, price: 3.20,
      stockQuantity: 60, status: 'Active', createdAt: DateTime(2024, 1, 12),
    ),
    ProductModel(
      id: 'P004', itemCode: 'VEG-004', name: 'Carrot',
      category: 'Root Vegetable', description: 'Sweet and crunchy carrots, freshly harvested.',
      precaution: 'Store in cool dry place.', freshnessLevel: 'Very Fresh',
      packType: 'KG', weightKg: 1.0, price: 4.50,
      stockQuantity: 200, status: 'Active', createdAt: DateTime(2024, 1, 12),
    ),
    ProductModel(
      id: 'P005', itemCode: 'VEG-005', name: 'Sweet Potato',
      category: 'Root Vegetable', description: 'Naturally sweet potatoes, good for baking and steaming.',
      precaution: 'Store in cool, ventilated area.', freshnessLevel: 'Fresh',
      packType: 'KG', weightKg: 1.0, price: 3.80,
      stockQuantity: 150, status: 'Active', createdAt: DateTime(2024, 1, 14),
    ),
    ProductModel(
      id: 'P006', itemCode: 'VEG-006', name: 'Tomato',
      category: 'Fruit Vegetable', description: 'Ripe and juicy tomatoes, perfect for cooking and salads.',
      precaution: 'Handle with care to prevent bruising.', freshnessLevel: 'Very Fresh',
      packType: 'KG', weightKg: 1.0, price: 5.50, promotionPrice: 4.80,
      stockQuantity: 8, status: 'Active', createdAt: DateTime(2024, 1, 15),
    ),
    ProductModel(
      id: 'P007', itemCode: 'VEG-007', name: 'Cucumber',
      category: 'Fruit Vegetable', description: 'Cool and refreshing cucumbers, great for salads.',
      precaution: 'Keep refrigerated after cutting.', freshnessLevel: 'Fresh',
      packType: 'KG', weightKg: 1.0, price: 3.00,
      stockQuantity: 180, status: 'Active', createdAt: DateTime(2024, 1, 16),
    ),
    ProductModel(
      id: 'P008', itemCode: 'VEG-008', name: 'Shiitake Mushroom',
      category: 'Mushroom', description: 'Premium dried shiitake mushrooms with rich umami flavour.',
      precaution: 'Store in airtight container away from moisture.', freshnessLevel: 'Premium Fresh',
      packType: 'Pack', weightKg: 0.2, price: 12.00,
      stockQuantity: 45, status: 'Active', createdAt: DateTime(2024, 1, 18),
    ),
    ProductModel(
      id: 'P009', itemCode: 'VEG-009', name: 'Oyster Mushroom',
      category: 'Mushroom', description: 'Delicate oyster mushrooms with a mild, sweet flavour.',
      precaution: 'Use within 3 days. Do not wash until ready to cook.', freshnessLevel: 'Very Fresh',
      packType: 'Pack', weightKg: 0.3, price: 6.50,
      stockQuantity: 0, status: 'Active', createdAt: DateTime(2024, 1, 18),
    ),
    ProductModel(
      id: 'P010', itemCode: 'VEG-010', name: 'Lemongrass',
      category: 'Herbs', description: 'Fragrant lemongrass stalks, essential for Malaysian cuisine.',
      precaution: 'Store in cool place or refrigerate.', freshnessLevel: 'Fresh',
      packType: 'Bundle', weightKg: 0.3, price: 2.50,
      stockQuantity: 75, status: 'Active', createdAt: DateTime(2024, 1, 20),
    ),
    ProductModel(
      id: 'P011', itemCode: 'VEG-011', name: 'Pandan Leaves',
      category: 'Herbs', description: 'Fresh pandan leaves for flavouring desserts and rice.',
      precaution: 'Best used fresh. Store refrigerated.', freshnessLevel: 'Very Fresh',
      packType: 'Bundle', weightKg: 0.2, price: 1.80,
      stockQuantity: 90, status: 'Active', createdAt: DateTime(2024, 1, 20),
    ),
    ProductModel(
      id: 'P012', itemCode: 'VEG-012', name: 'Broccoli (Imported)',
      category: 'Imported Vegetable', description: 'Premium imported broccoli, crisp and fresh.',
      precaution: 'Keep refrigerated. Best consumed within 3 days.', freshnessLevel: 'Premium Fresh',
      packType: 'Head', weightKg: 0.6, price: 8.00,
      stockQuantity: 35, status: 'Active', createdAt: DateTime(2024, 1, 22),
    ),
  ];

  // ─────────────────────────────────────────────
  // CUSTOMERS
  // ─────────────────────────────────────────────
  static final List<CustomerModel> customers = [
    CustomerModel(
      id: 'CUS001', customerCode: 'CUS00001', companyName: 'ABC Restaurant Sdn Bhd',
      contactPerson: 'John Lim', phoneNumber: '0123456789', email: 'john@abcrestaurant.com',
      businessRegistrationNo: 'BRN123456', address: '12, Jalan Bendahara, 75000 Melaka',
      creditLimit: 5000, creditTerm: '30 Days', status: 'Active',
      outstandingBalance: 1200, createdAt: DateTime(2024, 1, 5),
    ),
    CustomerModel(
      id: 'CUS002', customerCode: 'CUS00002', companyName: 'Golden Palace Kitchen',
      contactPerson: 'Mary Tan', phoneNumber: '0167891234', email: 'mary@goldenpalace.com',
      businessRegistrationNo: 'BRN234567', address: '35, Jalan Kota Laksamana, 75200 Melaka',
      creditLimit: 8000, creditTerm: '14 Days', status: 'Active',
      outstandingBalance: 3500, createdAt: DateTime(2024, 1, 8),
    ),
    CustomerModel(
      id: 'CUS003', customerCode: 'CUS00003', companyName: 'Mama Wok Catering',
      contactPerson: 'Ahmad Razif', phoneNumber: '0198765432', email: 'razif@mamawok.com',
      businessRegistrationNo: 'BRN345678', address: '8, Jalan Parameswara, 75300 Melaka',
      creditLimit: 3000, creditTerm: 'COD', status: 'Active',
      outstandingBalance: 0, createdAt: DateTime(2024, 2, 1),
    ),
    CustomerModel(
      id: 'CUS004', customerCode: 'CUS00004', companyName: 'Sunrise Hotel & Resort',
      contactPerson: 'David Wong', phoneNumber: '0132345678', email: 'david@sunrisehotel.com',
      businessRegistrationNo: 'BRN456789', address: '100, Jalan Tun Perak, 75000 Melaka',
      creditLimit: 15000, creditTerm: '30 Days', status: 'Active',
      outstandingBalance: 7800, createdAt: DateTime(2024, 2, 10),
    ),
    CustomerModel(
      id: 'CUS005', customerCode: 'CUS00005', companyName: 'Leaf & Bowl Cafe',
      contactPerson: 'Sarah Lee', phoneNumber: '0145678901', email: 'sarah@leafbowl.com',
      businessRegistrationNo: 'BRN567890', address: '22, Jalan Hang Tuah, 75300 Melaka',
      creditLimit: 2000, creditTerm: '7 Days', status: 'Inactive',
      outstandingBalance: 800, createdAt: DateTime(2024, 3, 1),
    ),
  ];

  // ─────────────────────────────────────────────
  // ORDERS
  // ─────────────────────────────────────────────
  static final List<OrderModel> orders = [
    OrderModel(
      id: 'ORD001', orderId: 'ORD-20240620-001', customerId: 'CUS001',
      customerName: 'ABC Restaurant Sdn Bhd',
      orderDate: DateTime.now(), deliveryDate: DateTime.now().add(const Duration(days: 1)),
      subtotal: 285.00, deliveryFee: 15.00, totalAmount: 300.00,
      paymentMethod: 'Credit Term', paymentStatus: 'Pending', orderStatus: 'Confirmed',
      items: [
        OrderItemModel(id: 'OI001', orderId: 'ORD001', productId: 'P001',
          product: products[0], quantity: 20, price: 2.80, subtotal: 56.00),
        OrderItemModel(id: 'OI002', orderId: 'ORD001', productId: 'P004',
          product: products[3], quantity: 30, price: 4.50, subtotal: 135.00),
        OrderItemModel(id: 'OI003', orderId: 'ORD001', productId: 'P007',
          product: products[6], quantity: 20, price: 3.00, subtotal: 60.00),
      ],
      createdAt: DateTime.now(),
    ),
    OrderModel(
      id: 'ORD002', orderId: 'ORD-20240619-002', customerId: 'CUS002',
      customerName: 'Golden Palace Kitchen',
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
      deliveryDate: DateTime.now(),
      subtotal: 520.00, deliveryFee: 15.00, totalAmount: 535.00,
      paymentMethod: 'Bank Transfer', paymentStatus: 'Paid', orderStatus: 'Delivered',
      items: [
        OrderItemModel(id: 'OI004', orderId: 'ORD002', productId: 'P008',
          product: products[7], quantity: 10, price: 12.00, subtotal: 120.00),
        OrderItemModel(id: 'OI005', orderId: 'ORD002', productId: 'P012',
          product: products[11], quantity: 50, price: 8.00, subtotal: 400.00),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    OrderModel(
      id: 'ORD003', orderId: 'ORD-20240620-003', customerId: 'CUS003',
      customerName: 'Mama Wok Catering',
      orderDate: DateTime.now(), deliveryDate: DateTime.now().add(const Duration(days: 1)),
      subtotal: 148.00, deliveryFee: 15.00, totalAmount: 163.00,
      paymentMethod: 'Cash', paymentStatus: 'Pending', orderStatus: 'Pending',
      items: [
        OrderItemModel(id: 'OI006', orderId: 'ORD003', productId: 'P002',
          product: products[1], quantity: 20, price: 2.80, subtotal: 56.00),
        OrderItemModel(id: 'OI007', orderId: 'ORD003', productId: 'P006',
          product: products[5], quantity: 20, price: 4.60, subtotal: 92.00),
      ],
      createdAt: DateTime.now(),
    ),
    OrderModel(
      id: 'ORD004', orderId: 'ORD-20240618-004', customerId: 'CUS004',
      customerName: 'Sunrise Hotel & Resort',
      orderDate: DateTime.now().subtract(const Duration(days: 2)),
      deliveryDate: DateTime.now().subtract(const Duration(days: 1)),
      subtotal: 890.00, deliveryFee: 15.00, totalAmount: 905.00,
      paymentMethod: 'Credit Term', paymentStatus: 'Partially Paid', orderStatus: 'Delivered',
      items: [
        OrderItemModel(id: 'OI008', orderId: 'ORD004', productId: 'P003',
          product: products[2], quantity: 50, price: 3.20, subtotal: 160.00),
        OrderItemModel(id: 'OI009', orderId: 'ORD004', productId: 'P004',
          product: products[3], quantity: 80, price: 4.50, subtotal: 360.00),
        OrderItemModel(id: 'OI010', orderId: 'ORD004', productId: 'P008',
          product: products[7], quantity: 30, price: 12.00, subtotal: 360.00),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    OrderModel(
      id: 'ORD005', orderId: 'ORD-20240620-005', customerId: 'CUS005',
      customerName: 'Leaf & Bowl Cafe',
      orderDate: DateTime.now(), deliveryDate: DateTime.now().add(const Duration(days: 1)),
      subtotal: 76.00, deliveryFee: 15.00, totalAmount: 91.00,
      paymentMethod: 'Cash', paymentStatus: 'Pending', orderStatus: 'Packed',
      items: [
        OrderItemModel(id: 'OI011', orderId: 'ORD005', productId: 'P010',
          product: products[9], quantity: 10, price: 2.50, subtotal: 25.00),
        OrderItemModel(id: 'OI012', orderId: 'ORD005', productId: 'P011',
          product: products[10], quantity: 20, price: 1.80, subtotal: 36.00),
        OrderItemModel(id: 'OI013', orderId: 'ORD005', productId: 'P009',
          product: products[8], quantity: 0, price: 6.50, subtotal: 0.00),
      ],
      createdAt: DateTime.now(),
    ),
  ];

  // ─────────────────────────────────────────────
  // INVENTORY
  // ─────────────────────────────────────────────
  static final List<InventoryModel> inventory = [
    InventoryModel(id: 'INV001', productId: 'P001', productName: 'Kangkung', productCode: 'VEG-001',
      currentStock: 120, reservedStock: 20, reorderLevel: 30, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV002', productId: 'P002', productName: 'Sawi', productCode: 'VEG-002',
      currentStock: 85, reservedStock: 20, reorderLevel: 30, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV003', productId: 'P003', productName: 'Bayam', productCode: 'VEG-003',
      currentStock: 60, reservedStock: 50, reorderLevel: 30, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV004', productId: 'P004', productName: 'Carrot', productCode: 'VEG-004',
      currentStock: 200, reservedStock: 110, reorderLevel: 50, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV005', productId: 'P005', productName: 'Sweet Potato', productCode: 'VEG-005',
      currentStock: 150, reservedStock: 0, reorderLevel: 30, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV006', productId: 'P006', productName: 'Tomato', productCode: 'VEG-006',
      currentStock: 8, reservedStock: 0, reorderLevel: 20, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV007', productId: 'P007', productName: 'Cucumber', productCode: 'VEG-007',
      currentStock: 180, reservedStock: 20, reorderLevel: 40, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV008', productId: 'P008', productName: 'Shiitake Mushroom', productCode: 'VEG-008',
      currentStock: 45, reservedStock: 40, reorderLevel: 10, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV009', productId: 'P009', productName: 'Oyster Mushroom', productCode: 'VEG-009',
      currentStock: 0, reservedStock: 0, reorderLevel: 10, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV010', productId: 'P010', productName: 'Lemongrass', productCode: 'VEG-010',
      currentStock: 75, reservedStock: 10, reorderLevel: 20, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV011', productId: 'P011', productName: 'Pandan Leaves', productCode: 'VEG-011',
      currentStock: 90, reservedStock: 20, reorderLevel: 20, lastUpdated: DateTime.now()),
    InventoryModel(id: 'INV012', productId: 'P012', productName: 'Broccoli (Imported)', productCode: 'VEG-012',
      currentStock: 35, reservedStock: 0, reorderLevel: 15, lastUpdated: DateTime.now()),
  ];

  // ─────────────────────────────────────────────
  // DELIVERIES
  // ─────────────────────────────────────────────
  static final List<DeliveryModel> deliveries = [
    DeliveryModel(id: 'DEL001', orderId: 'ORD001', orderCode: 'ORD-20240620-001',
      customerName: 'ABC Restaurant Sdn Bhd',
      deliveryDate: DateTime.now().add(const Duration(days: 1)),
      driverName: 'Ali bin Hassan', vehicleNumber: 'MKA 1234',
      status: 'Scheduled'),
    DeliveryModel(id: 'DEL002', orderId: 'ORD002', orderCode: 'ORD-20240619-002',
      customerName: 'Golden Palace Kitchen',
      deliveryDate: DateTime.now(),
      driverName: 'Chong Wei Keong', vehicleNumber: 'MKB 5678',
      status: 'Delivered', remarks: 'Left at reception'),
    DeliveryModel(id: 'DEL003', orderId: 'ORD003', orderCode: 'ORD-20240620-003',
      customerName: 'Mama Wok Catering',
      deliveryDate: DateTime.now().add(const Duration(days: 1)),
      driverName: 'Ali bin Hassan', vehicleNumber: 'MKA 1234',
      status: 'Scheduled'),
    DeliveryModel(id: 'DEL004', orderId: 'ORD004', orderCode: 'ORD-20240618-004',
      customerName: 'Sunrise Hotel & Resort',
      deliveryDate: DateTime.now().subtract(const Duration(days: 1)),
      driverName: 'Chong Wei Keong', vehicleNumber: 'MKB 5678',
      status: 'Delivered'),
    DeliveryModel(id: 'DEL005', orderId: 'ORD005', orderCode: 'ORD-20240620-005',
      customerName: 'Leaf & Bowl Cafe',
      deliveryDate: DateTime.now().add(const Duration(days: 1)),
      driverName: 'Ali bin Hassan', vehicleNumber: 'MKA 1234',
      status: 'Loading'),
  ];

  // ─────────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────────
  static DashboardStats get dashboardStats => DashboardStats(
    todayOrders: 3,
    todayRevenue: 554.00,
    pendingOrders: 2,
    pendingDeliveries: 3,
    lowStockProducts: 3,
    outstandingDebts: 13300.00,
    revenueData: [
      const RevenuePoint(label: 'Mon', amount: 1200),
      const RevenuePoint(label: 'Tue', amount: 1850),
      const RevenuePoint(label: 'Wed', amount: 980),
      const RevenuePoint(label: 'Thu', amount: 2300),
      const RevenuePoint(label: 'Fri', amount: 1750),
      const RevenuePoint(label: 'Sat', amount: 3100),
      const RevenuePoint(label: 'Sun', amount: 554),
    ],
    topProducts: [
      const TopProduct(name: 'Carrot', quantity: 180, revenue: 810),
      const TopProduct(name: 'Kangkung', quantity: 140, revenue: 392),
      const TopProduct(name: 'Broccoli', quantity: 80, revenue: 640),
      const TopProduct(name: 'Shiitake', quantity: 40, revenue: 480),
      const TopProduct(name: 'Tomato', quantity: 60, revenue: 330),
    ],
    topCustomers: [
      const TopCustomer(name: 'Sunrise Hotel', orders: 12, totalSpent: 9800),
      const TopCustomer(name: 'Golden Palace', orders: 18, totalSpent: 8200),
      const TopCustomer(name: 'ABC Restaurant', orders: 22, totalSpent: 5600),
      const TopCustomer(name: 'Mama Wok', orders: 15, totalSpent: 3200),
    ],
  );
}
