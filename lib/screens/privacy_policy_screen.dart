import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showPrivacyPolicyDialog(context),
          child: const Text('View Privacy Policy'),
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Text('Effective date: March, 2025'),
              SizedBox(height: 10),
              Text('This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our application.'),
              SizedBox(height: 10),
              Text('1. Information We Collect: We may collect information about you in a variety of ways, including personal information, usage data, and device information.'),
              SizedBox(height: 10),
              Text('2. Use of Your Information: We may use the information we collect to provide and maintain our service, improve user experience, and communicate with you.'),
              SizedBox(height: 10),
              Text('3. Disclosure of Your Information: We may share your information with third parties only in accordance with this Privacy Policy.'),
              SizedBox(height: 10),
              Text('4. Security of Your Information: We use administrative, technical, and physical security measures to help protect your personal information.'),
              SizedBox(height: 10),
              Text('5. Changes to This Privacy Policy: We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.'),
              SizedBox(height: 10),
              Text('6. Contact Us: If you have any questions about this Privacy Policy, please contact us at [Insert Contact Information].'),
              SizedBox(height: 10),
              Text('7. Advertising: We display ads within the app to support our services.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
