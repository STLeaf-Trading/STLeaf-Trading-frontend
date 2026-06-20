import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';

class ContactSupportUtils {
  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  static void showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              const Text('Contact Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 8),
              const Text('How would you like to reach us?', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 24),
              _contactTile(
                icon: Icons.chat_rounded,
                title: 'WhatsApp',
                subtitle: '011-2889 2991',
                color: const Color(0xFF25D366),
                onTap: () => _launchUrl('https://wa.me/601128892991'),
              ),
              const SizedBox(height: 12),
              _contactTile(
                icon: Icons.phone_rounded,
                title: 'Phone Call',
                subtitle: '011-2889 2991',
                color: AppColors.info,
                onTap: () => _launchUrl('tel:+601128892991'),
              ),
              const SizedBox(height: 12),
              _contactTile(
                icon: Icons.email_rounded,
                title: 'Email',
                subtitle: 'stleaf9193@gmail.com',
                color: AppColors.danger,
                onTap: () => _launchUrl('mailto:stleaf9193@gmail.com'),
              ),
              const SizedBox(height: 24),
              _buildLocationAndHours(),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildLocationAndHours() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Location', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('J1809 Pasar Jasin,\n77000 Jasin, Melaka, Malaysia', style: TextStyle(fontSize: 13, height: 1.4)),
          const Divider(height: 24),
          const Row(
            children: [
              Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Operating Hours', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          _hourRow('Mon - Tue', '7:00 AM – 3:00 PM'),
          _hourRow('Wednesday', 'Closed', isClosed: true),
          _hourRow('Thu - Sun', '7:00 AM – 3:00 PM'),
        ],
      ),
    );
  }

  static Widget _hourRow(String days, String hours, {bool isClosed = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(days, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(hours, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isClosed ? AppColors.danger : AppColors.textPrimary)),
        ],
      ),
    );
  }

  static Widget _contactTile({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class ContactSupportFAB extends StatelessWidget {
  const ContactSupportFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => ContactSupportUtils.showContactOptions(context),
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.headset_mic_rounded, color: AppColors.white),
    );
  }
}
