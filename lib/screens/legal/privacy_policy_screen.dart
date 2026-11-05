import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

enum LegalDocTab {
  privacy,
  terms,
  deletion,
}

class PrivacyPolicyScreen extends StatefulWidget {
  final LegalDocTab initialTab;

  const PrivacyPolicyScreen({
    super.key,
    this.initialTab = LegalDocTab.privacy,
  });

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const String privacyUrl = 'https://api.sheeshindia.com/privacy-policy';
  static const String termsUrl = 'https://api.sheeshindia.com/terms-of-service';
  static const String deletionUrl = 'https://api.sheeshindia.com/delete-account';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyLink(String url, String title) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '$title URL copied to clipboard!',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2A7B54),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Legal & Compliance',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy Public Policy Link',
            icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
            onPressed: () => _copyLink(privacyUrl, 'Privacy Policy'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Privacy Policy'),
                Tab(text: 'Terms of Use'),
                Tab(text: 'Data Deletion'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrivacyTab(),
          _buildTermsTab(),
          _buildDeletionTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. PRIVACY POLICY TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compliance Badge Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5A1629), Color(0xFF7A1C43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5A1629).withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sheesh Official Privacy Policy',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Compliant with Google Play Developer Policy, Digital Personal Data Protection (DPDP) Act, and IT Rules 2021.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Effective Date: November 2026 • Sheesh: Moradabad Artisans (com.sheesh.sheesh_app)',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFE5C384),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSectionCard(
            title: '1. Overview & Data Philosophy',
            content:
                'Sheesh ("we", "our", or "us"), operated by Sheesh Craft Ventures, is an artisan-direct hyperlocal marketplace connecting buyers across India with verified Moradabad brassware, bridal crafts, and traditional home decor artisans.\n\n'
                '• We NEVER sell your personal information or contact details to third-party ad networks.\n'
                '• We do not store sensitive payment credentials (credit/debit card numbers, CVVs, or UPI PINs). All financial transactions are securely processed by RBI-certified partners (Razorpay).\n'
                '• You retain full ownership of your data and can request complete account deletion at any time.',
          ),

          _buildSectionCard(
            title: '2. Information We Collect',
            content:
                'A. Personal Identifiers:\n'
                '• Full Name & Email Address: For account authentication via passwordless Email OTP or Google Sign-In.\n'
                '• Phone / WhatsApp Number: To send delivery OTPs, live order updates, and facilitate direct buyer-artisan communication.\n'
                '• Shipping & Workshop Addresses: To calculate delivery distances, provide localized craft discoveries, and route orders to your destination.\n\n'
                'B. Artisan & Store Information:\n'
                '• Workshop name, brand category, artisan bio, craft heritage story, and workshop photos uploaded to your digital storefront.\n'
                '• UPI Virtual Payment Address (VPA) or Bank Account Details: Strictly for crediting direct buyer order payouts with 0% platform commission.\n\n'
                'C. Device & Technical Information:\n'
                '• Device model, operating system version, and anonymous crash telemetry to ensure app stability.',
          ),

          _buildSectionCard(
            title: '3. App Permissions & Usage',
            content:
                'Sheesh requests only essential runtime permissions required for marketplace operations:\n\n'
                '• Photos & Media / Camera: Required only when you choose to take a photo or upload product pictures, store cover banners, or profile avatars. We never scan your device gallery without your explicit action.\n'
                '• Approximate/Precise Location: Optional. Used strictly to display nearby Moradabad workshops and calculate estimated delivery timelines on the Map screen. Location data is never tracked in the background.\n'
                '• Notifications: Used to alert you on order status changes, delivery out-for-delivery alerts, and artisan direct messages.',
          ),

          _buildSectionCard(
            title: '4. Information Sharing & Disclosure',
            content:
                'We share information only under strict operational necessity:\n\n'
                '• With Verified Artisans: When an order is placed, the artisan receives your delivery name, address, and phone number solely to prepare and package your creation.\n'
                '• With Logistics Partners: Reputable third-party courier delivery services receive shipping details to fulfill pan-India doorstep transit.\n'
                '• Legal Requirements: If mandated by law, court order, or governmental authorities under Indian jurisdiction.',
          ),

          _buildSectionCard(
            title: '5. Data Security & Storage',
            content:
                'All user communications and database queries are encrypted in transit via industry-standard TLS 1.3 / HTTPS. Our databases are managed with role-based access control and row-level security (RLS) on Supabase and PostgreSQL infrastructure, hosted in ISO 27001 certified data centers.',
          ),

          _buildSectionCard(
            title: '6. Grievance Officer & Contact',
            content:
                'In accordance with the Information Technology Act 2000 and rules made thereunder, the contact details of the Grievance Officer are:\n\n'
                '• Grievance Officer: Sheesh Customer & Compliance Cell\n'
                '• Email: support@sheeshindia.com\n'
                '• Web Portal: https://api.sheeshindia.com/privacy-policy\n'
                '• Address: Peetal Mandi, Moradabad, Uttar Pradesh, 244001, India\n'
                '• Response Time: Within 48 business hours',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. TERMS OF USE TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: '1. Acceptance of Terms',
            content:
                'By downloading, accessing, or using the Sheesh mobile application or API services, you agree to be bound by these Terms of Service. If you do not agree to all terms, please refrain from using our application.',
          ),
          _buildSectionCard(
            title: '2. Artisan-Direct Marketplace Model',
            content:
                '• Sheesh provides an empowering digital platform enabling Moradabad karigars, women entrepreneurs, and metal crafters to showcase and sell creations directly to buyers.\n'
                '• Artisans maintain 100% ownership of their brand identity and receive direct payments with 0% platform deductions.\n'
                '• Each artisan guarantees that all listed items are genuinely handcrafted, ethically sourced, and compliant with Indian trade standards.',
          ),
          _buildSectionCard(
            title: '3. Buyer Guidelines & Orders',
            content:
                '• Handcrafted Variations: Since Moradabad brassware and zardozi items are made by hand, slight organic variations in finish, engraving depth, or patina are hallmarks of authentic handicraft and not considered defects.\n'
                '• Order Tracking: Buyers receive real-time dispatch updates and estimated delivery schedules.\n'
                '• Cancellations & Returns: Orders may be cancelled before workshop dispatch. In case of transit damage, buyers can request a full replacement or refund within 48 hours of delivery with unboxing photos.',
          ),
          _buildSectionCard(
            title: '4. Seller Listing Policies',
            content:
                '• Prohibited Items: Machine-manufactured replicas falsely claimed as handmade, counterfeit goods, or prohibited materials are strictly banned.\n'
                '• Account Suspension: Sheesh reserves the right to suspend or remove any seller profile engaging in fraudulent listings or abusive behavior.',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. ACCOUNT & DATA DELETION TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildDeletionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Account & Data Deletion',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Google Play User Data Deletion Policy Compliant',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'You have the legal right under the Digital Personal Data Protection Act to permanently delete your Sheesh account and all associated personal records.\n\n'
                  'What gets permanently deleted:\n'
                  '• Profile information (name, email, phone number, avatars)\n'
                  '• Saved delivery destinations and address book\n'
                  '• Active shopping cart items and saved wishlist creations\n'
                  '• Artisan storefront configuration and unlisted drafts\n\n'
                  'Note: Financial transaction logs required for statutory tax compliance (GST / IT Act) are retained securely for the legally mandated period.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.mail_outline_rounded, size: 18),
                    label: Text(
                      'Email Account Deletion Request',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () => _showDeletionConfirmDialog(context),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => _copyLink(deletionUrl, 'Account Deletion'),
                    child: Text(
                      'Copy Public Web Deletion URL: $deletionUrl',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeletionConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Sheesh Account?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'To process your deletion request, our compliance team will verify your registered email and delete all data within 7 business days.\n\nPlease confirm to send a request to support@sheeshindia.com.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Deletion request logged. Email support@sheeshindia.com from your registered address to complete.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  ),
                  backgroundColor: AppColors.primaryDark,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: Text('Confirm Request', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

