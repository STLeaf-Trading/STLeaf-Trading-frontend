import 'package:flutter/material.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';
import 'package:stleaf_trading/presentation/widgets/layout/customer_layout.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String type; // 'terms' or 'privacy'
  const LegalScreen({super.key, required this.title, required this.type});

  @override
  Widget build(BuildContext context) {
    return CustomerLayout(
      currentRoute: '/shop/profile',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(backgroundColor: AppColors.mint, foregroundColor: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
            ]),
            const SizedBox(height: 8),
            Text(
              'ST Leaf Trading · Last updated: June 2025',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            if (type == 'terms') _buildTerms(context) else _buildPrivacy(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTerms(BuildContext context) {
    const sections = [
      ('1.0 Acceptance of Terms',
        'By accessing or using the ST Leaf Trading mobile/web application, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use our services.'),
      ('2.0 Services',
        'ST Leaf Trading provides an online platform for ordering fresh vegetables and produce directly from our farm/supplier. All orders are subject to availability and our confirmation.'),
      ('3.0 Orders and Payment',
        'Orders placed through the app are subject to acceptance by ST Leaf Trading. We accept Cash / COD (Cash on Delivery) as the payment method. Prices are displayed in Malaysian Ringgit (RM) and are inclusive of applicable taxes.'),
      ('4.0 Delivery',
        'We offer two delivery options: self-pickup from our location (J1809 Pasar Jasin, 77000 Jasin, Melaka) or delivery by our team subject to a delivery fee set by the admin. Delivery times are estimated and not guaranteed.'),
      ('5.0 Cancellation',
        'Customers may cancel their orders before the order status is marked as "Packed." Once an order is packed, cancellations are not permitted. All cancellation reasons are recorded for quality improvement purposes.'),
      ('6.0 Product Quality',
        'We strive to deliver the freshest produce. However, freshness levels indicated in the app are approximate. If you receive unsatisfactory produce, please contact our support team immediately.'),
      ('7.0 Account Responsibility',
        'You are responsible for maintaining the confidentiality of your account credentials. Any activity under your account is your responsibility. If you suspect unauthorized access, please contact us immediately.'),
      ('8.0 Limitation of Liability',
        'ST Leaf Trading shall not be liable for any indirect, incidental, or consequential damages arising from the use or inability to use our services.'),
      ('9.0 Changes to Terms',
        'We reserve the right to update these Terms at any time. Continued use of the app after changes constitutes your acceptance of the new Terms.'),
      ('10.0 Contact',
        'For questions about these Terms, please contact us via WhatsApp at 011-2889 2991 or email stleaf9193@gmail.com.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((s) => _section(context, s.$1, s.$2)).toList(),
    );
  }

  Widget _buildPrivacy(BuildContext context) {
    const sections = [
      ('Introduction',
        'ST Leaf Trading ("we," "our," or "us") is committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our application.'),
      ('1.0 Information We Collect',
        '• Account Information: Your name, email address, phone number, and company/business name collected during registration.\n• Delivery Address: Provided voluntarily to facilitate order delivery.\n• Order History: Details of products ordered, quantities, amounts paid, and delivery preferences.\n• Communication Data: Any messages or notes you send to us through the app (e.g., order remarks, cancellation reasons).'),
      ('2.0 How We Use Your Information',
        '• To process and fulfill your orders.\n• To contact you about your orders or account.\n• To improve our services and product offerings.\n• To maintain order records for tax compliance and legal purposes under Malaysian law.\n• To send important notifications about your orders and account status.'),
      ('3.0 Data Sharing',
        'We do not sell, trade, or rent your personal information to third parties. Your data may be shared only with:\n• Our delivery team (name and address only) for order fulfillment.\n• Firebase/Google Cloud as our secure technology platform provider, subject to Google\'s Privacy Policy.'),
      ('4.0 Data Retention',
        '• Account data (name, email, phone, address) is retained while your account is active. Upon account deletion, this data is permanently removed.\n• Order history is retained indefinitely for tax compliance and legal record-keeping purposes, even after account deletion, as required under the Income Tax Act 1967 and the SST Act 2018.'),
      ('5.0 Data Security',
        'We implement industry-standard security measures including Firebase Authentication and Firestore security rules to protect your data from unauthorized access. However, no method of transmission over the Internet is 100% secure.'),
      ('6.0 Your Rights',
        'You have the right to:\n• Access your personal information by viewing your profile in the app.\n• Update your information via the Edit Profile page.\n• Delete your account (note: order history is retained per Section 4.0).\n• Contact us to request correction of any inaccurate data.'),
      ('7.0 Cookies and Analytics',
        'Our web version may use browser storage for session management. We do not use third-party tracking cookies or advertising networks.'),
      ('8.0 Children\'s Privacy',
        'Our services are not directed to individuals under the age of 18. We do not knowingly collect personal information from children.'),
      ('9.0 Changes to This Policy',
        'We may update this Privacy Policy periodically. We will notify you of significant changes through the app. Continued use of our services after changes constitutes your acceptance.'),
      ('10.0 Contact Us',
        'If you have any questions or concerns about this Privacy Policy or your personal data, please contact:\n\nST Leaf Trading\nJ1809 Pasar Jasin, 77000 Jasin, Melaka, Malaysia\nWhatsApp: 011-2889 2991\nEmail: stleaf9193@gmail.com'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((s) => _section(context, s.$1, s.$2)).toList(),
    );
  }

  Widget _section(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary)),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
