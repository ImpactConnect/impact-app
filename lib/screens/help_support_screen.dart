import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (await url_launcher.canLaunchUrl(url)) {
      await url_launcher.launchUrl(url);
    }
  }

  Widget _buildSection(String title, List<FAQItem> items) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: items
          .map((item) => FAQTile(
                question: item.question,
                answer: item.answer,
                link: item.link,
                onTapLink: () => _launchURL(item.link ?? ''),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        children: [
          // Quick Actions Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SupportCard(
                    icon: Icons.email,
                    title: 'Contact Support',
                    onTap: () => _launchURL('mailto:teay361@gmail.com'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SupportCard(
                    icon: Icons.chat,
                    title: 'Live Chat',
                    onTap: () async {
                      final whatsappUrl = 'https://wa.me/2347032196863?text=Hello%20I%20need%20help';
                      await _launchURL(whatsappUrl);
                    },
                  ),
                ),
              ],
            ),
          ),

          // FAQ Sections
          _buildSection(
            'Getting Started',
            [
              FAQItem(
                question: 'How do I access the app?',
                answer:
                    'The app is free to use and does not require registration. Simply open the app to access all available resources.',
              ),
              FAQItem(
                question: 'What resources are available?',
                answer:
                    'You can access sermons, ebooks, Bible, Devotionals, Hymns. articles, and other spiritual content without signing in.',
              ),
            ],
          ),
          _buildSection(
            'Bible Features',
            [
              FAQItem(
                question: 'How do I highlight verses?',
                answer:
                    'Long press any verse to open the highlight menu. Choose your preferred color.',
              ),
              FAQItem(
                question: 'Can I add personal notes?',
                answer:
                    'Yes! Tap the note icon next to any verse to add your thoughts.',
              ),
            ],
          ),
          _buildSection(
            'Media & Content',
            [
              FAQItem(
                question: 'How do I download sermons?',
                answer:
                    'To download a sermon, click the three dots icon on the sermon list card and select the download option.',
              ),
              FAQItem(
                question: 'How do I access the downloaded sermon?',
                answer:
                    'You can access your downloaded sermons by clicking the downloaded tab on the sermon page.',
              ),
              FAQItem(
                question: 'How do I download an ebook?',
                answer:
                    'To download an ebook, use the download button available on the book details page.',
              ),
            ],
          ),

          // Contact Information
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('Email: products@impacttech-solutions.com'),
                Text('Phone: +2347032196863'),
                Text('Hours: Monday-Friday, 9AM-5PM EST'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FAQItem {
  FAQItem({
    required this.question,
    required this.answer,
    this.link,
  });
  final String question;
  final String answer;
  final String? link;
}

class FAQTile extends StatelessWidget {
  const FAQTile({
    Key? key,
    required this.question,
    required this.answer,
    this.link,
    this.onTapLink,
  }) : super(key: key);
  final String question;
  final String answer;
  final String? link;
  final VoidCallback? onTapLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (link != null) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: onTapLink,
              child: Text(
                'Learn more',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
