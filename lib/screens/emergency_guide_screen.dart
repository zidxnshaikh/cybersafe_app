import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyGuideScreen extends StatelessWidget {
  const EmergencyGuideScreen({super.key});

  Future<void> _callHelpline(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '1930');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling is not available on this device.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Cyber Incident Guide', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Act quickly if you shared information or made an unauthorized payment.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => _callHelpline(context),
          icon: const Icon(Icons.call),
          label: const Text('Call India cyber fraud helpline 1930'),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
        ),
        const SizedBox(height: 8),
        Text('Helpline availability and procedures can vary. If you are outside India, contact your local authorities or bank.',
          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 20),
        const _GuideStep(number: '01', title: 'Contact your bank',
          body: 'Use the number on your card or the official banking app to block affected cards or accounts.'),
        const _GuideStep(number: '02', title: 'Report the incident',
          body: 'In India, report financial cyber fraud promptly through 1930 and the official cybercrime reporting portal.'),
        const _GuideStep(number: '03', title: 'Secure your accounts',
          body: 'Change reused passwords from a trusted device, sign out other sessions, and enable multi-factor authentication.'),
        const _GuideStep(number: '04', title: 'Keep evidence',
          body: 'Save transaction IDs, messages, phone numbers, links, and complaint references. Do not delete relevant records.'),
        const SizedBox(height: 8),
        const Text('Do not share one-time passwords, PINs, or remote-access codes with anyone offering to help.',
          style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.title, required this.body});

  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(number, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(body, style: TextStyle(color: Colors.grey[300], height: 1.4)),
      ])),
    ]),
  );
}