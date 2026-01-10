import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/language_provider.dart';

class TermsOfServiceScreen extends ConsumerStatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  ConsumerState<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends ConsumerState<TermsOfServiceScreen> {
  String? _termsContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    try {
      final locale = ref.read(currentLocaleProvider);
      final languageCode = locale.languageCode;
      
      // Map language code to file name
      final fileName = 'assets/terms/terms_$languageCode.md';
      
      // Try to load the language-specific terms, fallback to English if not found
      String content;
      try {
        content = await rootBundle.loadString(fileName);
      } catch (e) {
        // Fallback to English if the language file doesn't exist
        content = await rootBundle.loadString('assets/terms/terms_en.md');
      }
      
      setState(() {
        _termsContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Terms of Service';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error!),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTerms,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Markdown(
                    data: _termsContent!,
                    padding: const EdgeInsets.all(24.0),
                    styleSheet: MarkdownStyleSheet(
                      h1: Theme.of(context).textTheme.headlineMedium,
                      h2: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      h3: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      p: Theme.of(context).textTheme.bodyMedium,
                      listBullet: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
    );
  }
}

// Legacy widget for inline display (kept for backward compatibility)
class _LegacyTermsOfServiceScreen extends StatelessWidget {
  const _LegacyTermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: December 12, 2025',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                '1. Acceptance of Terms',
                'By creating an account and using We Coach ("the Service"), you agree to be bound by these Terms of Service. If you do not agree to these terms, you may not use the Service.',
              ),
              _buildSection(
                context,
                '2. Description of Service',
                'We Coach is a relationship communication support application designed to facilitate communication between couples. The Service provides:\n\n'
                '• Private conversation spaces for couples\n'
                '• AI-assisted relationship coaching and communication support\n'
                '• Secure messaging and communication tools\n'
                '• Partner connection and invitation features\n\n'
                '⚠️ THIS SERVICE IS NOT THERAPY: We Coach provides communication support and educational guidance only. It is not a substitute for professional therapy, counseling, or mental health treatment.',
              ),
              _buildSection(
                context,
                '3. User Accounts and Registration',
                '3.1 Account Creation:\n'
                '• You must provide accurate, current, and complete information during registration\n'
                '• You must be at least 18 years old to use this Service\n'
                '• You are responsible for maintaining the confidentiality of your account credentials\n'
                '• You are responsible for all activities that occur under your account\n\n'
                '3.2 Account Security:\n'
                '• You agree to notify us immediately of any unauthorized access to your account\n'
                '• We are not liable for any loss or damage arising from your failure to maintain account security',
              ),
              _buildSection(
                context,
                '4. Privacy and Data Protection',
                '4.1 Personal Information:\n'
                '• We collect and process personal information as described in our Privacy Policy\n'
                '• By using the Service, you consent to the collection and use of your information\n'
                '• Your conversations and personal data are stored securely\n\n'
                '4.2 Data Sharing:\n'
                '• We do not sell or share your personal information with third parties for marketing purposes\n'
                '• Partner information is shared only with your connected partner within the Service\n'
                '• We may use anonymized data for service improvement purposes',
              ),
              _buildSection(
                context,
                '5. User Conduct',
                'You agree not to:\n\n'
                '• Use the Service for any illegal purpose or in violation of any laws\n'
                '• Harass, abuse, or harm another person\n'
                '• Impersonate any person or entity\n'
                '• Upload or transmit viruses, malware, or malicious code\n'
                '• Attempt to gain unauthorized access to the Service or related systems\n'
                '• Use the Service to distribute spam or unsolicited messages',
              ),
              _buildSection(
                context,
                '6. Intellectual Property',
                '6.1 Service Content:\n'
                '• All content, features, and functionality of the Service are owned by We Coach\n'
                '• You may not copy, modify, distribute, or create derivative works without permission\n\n'
                '6.2 User Content:\n'
                '• You retain ownership of any content you create through the Service\n'
                '• You grant us a license to use, store, and display your content to provide the Service\n'
                '• You represent that you have the right to share all content you post',
              ),
              _buildSection(
                context,
                '7. AI Relationship Coaching Features',
                '⚠️ IMPORTANT DISCLAIMERS:\n\n'
                '7.1 Not Therapy or Mental Health Treatment:\n'
                '• The AI relationship coach provides communication support and educational guidance ONLY\n'
                '• This is NOT therapy, counseling, or mental health treatment\n'
                '• The AI is not a licensed therapist, psychologist, or mental health professional\n'
                '• AI-generated advice is for informational and educational purposes only\n\n'
                '7.2 No Substitute for Professional Help:\n'
                '• The Service is NOT a substitute for professional therapy or mental health services\n'
                '• We strongly encourage seeking licensed professional help for:\n'
                '  - Mental health concerns (depression, anxiety, trauma, etc.)\n'
                '  - Relationship crises or serious conflicts\n'
                '  - Abuse, violence, or safety concerns\n'
                '  - Suicidal thoughts or self-harm\n\n'
                '7.3 Crisis Situations:\n'
                '• If you are in crisis or immediate danger, call emergency services (112/911)\n'
                '• For mental health crises, contact a crisis hotline or emergency services\n'
                '• The AI cannot provide crisis intervention\n\n'
                '7.4 Accuracy and Reliability:\n'
                '• We do not guarantee the accuracy, completeness, or appropriateness of AI responses\n'
                '• AI responses may contain errors or inappropriate suggestions\n'
                '• You use AI-generated content at your own risk\n\n'
                '7.5 Professional Consultation:\n'
                '• Always consult licensed professionals for serious relationship or mental health issues\n'
                '• The Service is designed to support communication between partners, not replace professional guidance',
              ),
              _buildSection(
                context,
                '8. Service Modifications and Termination',
                '8.1 Service Changes:\n'
                '• We reserve the right to modify or discontinue the Service at any time\n'
                '• We will make reasonable efforts to notify users of significant changes\n\n'
                '8.2 Account Termination:\n'
                '• You may terminate your account at any time by contacting us\n'
                '• We may suspend or terminate your account for violations of these Terms\n'
                '• Upon termination, your right to access the Service will immediately cease',
              ),
              _buildSection(
                context,
                '9. Disclaimers and Limitations of Liability',
                '9.1 Service Availability:\n'
                '• The Service is provided "as is" without warranties of any kind\n'
                '• We do not guarantee uninterrupted or error-free operation\n'
                '• We are not responsible for service interruptions or data loss\n\n'
                '9.2 Limitation of Liability:\n'
                '• We are not liable for any indirect, incidental, special, or consequential damages\n'
                '• Our total liability shall not exceed the amount paid by you for the Service in the past 12 months',
              ),
              _buildSection(
                context,
                '10. Indemnification',
                'You agree to indemnify and hold harmless We Coach and its affiliates from any claims, losses, or damages arising from:\n\n'
                '• Your use of the Service\n'
                '• Your violation of these Terms\n'
                '• Your violation of any rights of another party',
              ),
              _buildSection(
                context,
                '11. Governing Law',
                'These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which We Coach operates, without regard to conflict of law provisions.',
              ),
              _buildSection(
                context,
                '12. Dispute Resolution',
                '12.1 Informal Resolution:\n'
                '• Before filing a formal claim, you agree to attempt to resolve disputes informally by contacting us\n\n'
                '12.2 Arbitration:\n'
                '• Any disputes not resolved informally shall be settled through binding arbitration\n'
                '• You waive your right to participate in class actions or class arbitrations',
              ),
              _buildSection(
                context,
                '13. Changes to Terms',
                'We reserve the right to modify these Terms at any time. We will notify users of material changes by:\n\n'
                '• Posting updated Terms on the Service\n'
                '• Sending an email notification to your registered email address\n\n'
                'Your continued use of the Service after changes constitutes acceptance of the modified Terms.',
              ),
              _buildSection(
                context,
                '14. Contact Information',
                'If you have questions about these Terms, please contact us at:\n\n'
                'Email: support@we-connect-app.com',
              ),
              _buildSection(
                context,
                '15. Severability',
                'If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.',
              ),
              _buildSection(
                context,
                '16. Entire Agreement',
                'These Terms, together with our Privacy Policy, constitute the entire agreement between you and We Coach regarding the Service.',
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'By creating an account, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
