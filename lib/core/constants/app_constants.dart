class AppConstants {
  // App Info
  static const String appName = 'ST Leaf Trading';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Fresh from Farm to Table';
  static const String company = 'ST Leaf Trading';
  static const String location = 'Melaka, Malaysia';

  // API
  static const String apiBaseUrl = 'http://localhost:8080/api';
  static const bool useMock = true; // Toggle to false when backend is ready

  // Auth
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  static const String roleKey = 'user_role';

  // Roles
  static const String roleAdmin = 'ADMIN';
  static const String roleCustomer = 'CUSTOMER';

  // Delivery
  static const double defaultDeliveryFee = 15.00;
  static const String deliveryPolicy = 'Orders placed today will be delivered tomorrow.';

  // Credit Terms
  static const List<String> creditTerms = ['Cash / COD', '7 Days', '14 Days', '30 Days', '60 Days'];

  // Categories
  static const List<String> productCategories = [
    'Fruits',
    'Vegetables',
    'Mushrooms',
  ];

  // Freshness Levels
  static const List<String> freshnessLevels = [
    'Fresh',
    'Very Fresh',
    'Premium Fresh',
    'A',
    'B',
  ];

  // Order Status
  static const List<String> orderStatuses = [
    'Pending',
    'Confirmed',
    'Packed',
    'Out For Delivery',
    'Delivered',
    'Cancelled',
  ];

  // Delivery Status
  static const List<String> deliveryStatuses = [
    'Scheduled',
    'Loading',
    'In Transit',
    'Delivered',
    'Failed',
  ];

  static const List<String> paymentMethods = [
    'Cash / COD',
    'FPX (Online Banking)',
    'Touch \'n Go (TNG)',
    'Instalment',
  ];

  // Instalment period presets
  static const List<String> instalmentPresets = [
    '1 Month',
    '3 Months',
    '6 Months',
    'Custom',
  ];

  // Instalment payment methods (subset)
  static const List<String> instalmentPaymentMethods = [
    'Cash / COD',
    'FPX (Online Banking)',
    'Touch \'n Go (TNG)',
  ];

  // Payment Status
  static const List<String> paymentStatuses = [
    'Pending',
    'Partially Paid',
    'Paid',
    'Overdue',
  ];

  // Customer Status
  static const List<String> customerStatuses = ['Active', 'Inactive', 'Suspended'];
}
