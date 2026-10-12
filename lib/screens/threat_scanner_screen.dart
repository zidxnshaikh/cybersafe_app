import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/threat_provider.dart';
import '../services/ai_verification_service.dart';
import '../services/link_verification_service.dart';
import '../services/threat_engine.dart';

class ThreatScannerScreen extends StatefulWidget {
  const ThreatScannerScreen({super.key});

  @override
  State<ThreatScannerScreen> createState() => _ThreatScannerScreenState();
}

class _ThreatScannerScreenState extends State<ThreatScannerScreen> {
  static const _samples = <({String label, String message, Color color})>[
    (
      label: 'Safe: OTP',
      message:
          'Your OTP for login is 482910. Valid for 10 minutes. Do not share this with anyone.',
      color: Color(0xFF22C55E),
    ),
    (
      label: 'Safe: delivery',
      message:
          'Your order has been shipped and will arrive by Thursday. Track at https://yourcourier.com/track/4521',
      color: Color(0xFF22C55E),
    ),
    (
      label: 'Moderate: parcel fee',
      message:
          'Your parcel is held at customs due to a pending fee. Pay here to release: http://track-parcel.club/pay',
      color: Color(0xFFEAB308),
    ),
    (
      label: 'High: power bill',
      message:
          'Dear consumer, your electricity power will be cut tonight at 9:30 PM due to unpaid bill. Contact billing dept immediately: http://elec-billpay.xyz/pay',
      color: Color(0xFFF97316),
    ),
    (
      label: 'High: prize claim',
      message:
          'Congratulations! You are the lucky winner of Rs. 25,00,000 in the Annual Lucky Draw 2026. Share your bank PIN and OTP with our agent to claim.',
      color: Color(0xFFF97316),
    ),
    (
      label: 'Critical: UPI',
      message:
          'Dear customer, someone has sent you Rs.5000 via UPI. To receive the amount, scan the attached QR code and enter your UPI PIN to confirm the transaction.',
      color: Color(0xFFEF4444),
    ),
    (
      label: 'Critical: CBI',
      message:
          'This is CBI Cyber Crime Cell. Your Aadhaar is linked to a money laundering case. You are under digital arrest. Do not disconnect this call.',
      color: Color(0xFFEF4444),
    ),
  ];

  static const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _safeBrowsingApiKey =
      String.fromEnvironment('SAFE_BROWSING_API_KEY');

  final _controller = TextEditingController();
  ThreatReport? _currentReport;
  bool _isScanning = false;
  bool _isAIReviewing = false;
  AIVerificationResult? _aiResult;
  String? _aiError;
  List<LinkVerificationResult> _linkResults = [];
  bool _isCheckingLinks = false;
  String? _linkCheckError;

  @override
  void initState() {
    super.initState();
    _removeLegacyApiKey();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _removeLegacyApiKey() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove('aiApiKey');
    } catch (error) {
      debugPrint('Could not remove the previously saved AI API key: $error');
    }
  }

  Future<void> _runScan() async {
    final input = _controller.text.trim();
    if (input.isEmpty || _isScanning) return;
    setState(() => _isScanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    final report = context.read<ThreatProvider>().analyze(input);
    setState(() {
      _currentReport = report;
      _isScanning = false;
    });
  }

  Future<void> _copyReport(ThreatReport report) async {
    final text = [
      'CYBERSAFE SCAN REPORT',
      'Generated: ${DateFormat('yyyy-MM-dd h:mm a').format(report.createdAt.toLocal())}',
      '',
      'Submitted message or link:',
      report.input,
      '',
      'Local pattern scan: ${report.score}/100 — ${report.riskLevel}',
      report.summary,
      'Local indicators:',
      if (report.indicators.isEmpty) '- None detected',
      ...report.indicators.map((indicator) => '- $indicator'),
      '',
      if (_aiResult != null) ...[
        'AI verification: ${_aiResult!.badgeText}',
        'Model confidence (not safety probability): ${(_aiResult!.confidence * 100).round()}%',
        'Summary: ${_aiResult!.summary}',
        'Explanation: ${_aiResult!.reasoning}',
        '',
      ],
      if (_aiError != null) ...[
        'AI verification: No AI verdict was returned.',
        'Reason: $_aiError',
        '',
      ],
      if (_linkResults.isNotEmpty) ...[
        'Link reputation and domain check:',
        ..._linkResults.map(
          (result) => '- ${result.url}: ${result.label}. ${result.details}',
        ),
        '',
      ],
      if (_linkCheckError != null) ...[
        'Link verification error: $_linkCheckError',
        '',
      ],
      'Recommendations:',
      ...report.recommendations.map((recommendation) => '- $recommendation'),
      '',
      'This automated assessment is not proof that a message or link is safe.',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied to clipboard')),
    );
  }

  Future<void> _checkLinks() async {
    final input = _controller.text.trim();
    if (input.isEmpty || _isCheckingLinks) return;
    final report = _currentReport?.input == input
        ? _currentReport!
        : context.read<ThreatProvider>().analyze(input);

    setState(() {
      _currentReport = report;
      _isCheckingLinks = true;
      _linkResults = [];
      _linkCheckError = null;
    });

    try {
      final results = await LinkVerificationService.verifyInput(
        input: input,
        safeBrowsingApiKey: _safeBrowsingApiKey,
      );
      if (!mounted) return;
      setState(() {
        _linkResults = results;
        _isCheckingLinks = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _linkCheckError = error.toString();
        _isCheckingLinks = false;
      });
    }
  }

  Future<void> _verifyWithAI() async {
    final input = _controller.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a message or link to verify.')),
      );
      return;
    }

    if (_geminiApiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gemini is not configured for this build. See the README.',
          ),
        ),
      );
      return;
    }

    final report = _currentReport?.input == input
        ? _currentReport!
        : context.read<ThreatProvider>().analyze(input);

    setState(() {
      _currentReport = report;
      _isAIReviewing = true;
      _aiResult = null;
      _aiError = null;
    });

    try {
      final result = await AIVerificationService.verifyText(
        apiKey: _geminiApiKey,
        message: input,
      );
      if (!mounted) return;
      setState(() {
        _aiResult = result;
        _aiError = null;
        _isAIReviewing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _aiError = error.toString();
        _isAIReviewing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI verification failed: $error')),
      );
    }
  }

  void _useSample(String message) {
    setState(() {
      _controller.value = TextEditingValue(
        text: message,
        selection: TextSelection.collapsed(offset: message.length),
      );
      _currentReport = null;
      _aiResult = null;
      _aiError = null;
      _linkResults = [];
      _linkCheckError = null;
    });
  }

  void _clearMessage() {
    setState(() {
      _controller.clear();
      _currentReport = null;
      _aiResult = null;
      _aiError = null;
      _linkResults = [];
      _linkCheckError = null;
    });
  }

  Widget _riskBadge(ThreatReport report, Color riskColor) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        report.riskLevel.toUpperCase(),
        style: TextStyle(color: riskColor, fontWeight: FontWeight.bold),
      ),
    );

    if (report.riskLevel != 'Critical Hazard') return badge;
    // Reserve the repeating pulse for the highest-risk result only.
    return badge
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.035, 1.035),
          duration: 900.ms,
          curve: Curves.easeInOut,
        );
  }

  @override
  Widget build(BuildContext context) {
    final report = _currentReport;
    final riskColor = report == null
        ? Theme.of(context).colorScheme.primary
        : report.score >= 40
            ? Colors.redAccent
            : Colors.greenAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phishing & Scam Link Analyzer',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 8),
          Text(
              'Check suspicious messages and links with an on-device pattern scan.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 16),
          const Text('Try a sample',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final sample in _samples) ...[
                  ActionChip(
                    onPressed: () => _useSample(sample.message),
                    label: Text(sample.label),
                    labelStyle: TextStyle(color: sample.color),
                    backgroundColor: sample.color.withValues(alpha: 0.12),
                    side:
                        BorderSide(color: sample.color.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {
              _currentReport = null;
              _aiResult = null;
              _aiError = null;
              _linkResults = [];
              _linkCheckError = null;
            }),
            decoration: InputDecoration(
              hintText: 'Paste a suspicious SMS, URL, or chat message',
              alignLabelWithHint: true,
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear message',
                      onPressed: _clearMessage,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _runScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.security),
              label: Text(
                  _isScanning ? 'Checking message...' : 'Scan threat level'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isCheckingLinks ||
                      LinkVerificationService.extractUrls(_controller.text)
                          .isEmpty
                  ? null
                  : _checkLinks,
              icon: _isCheckingLinks
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link),
              label: Text(
                _isCheckingLinks ? 'Checking link...' : 'Check link reputation',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _safeBrowsingApiKey.trim().isEmpty
                ? 'Without a Safe Browsing key, this only checks the app’s small known-domain list.'
                : 'Checks known threats and compares the host to a small known-domain list.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text('Gemini AI verification',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            _geminiApiKey.trim().isEmpty
                ? 'Gemini is not configured for this build. The local scan is still available.'
                : 'The message will be sent to Gemini for analysis.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isScanning ||
                      _isCheckingLinks ||
                      _isAIReviewing ||
                      _controller.text.isEmpty ||
                      _geminiApiKey.trim().isEmpty
                  ? null
                  : _verifyWithAI,
              icon: _isAIReviewing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.smart_toy_outlined),
              label: Text(
                  _isAIReviewing ? 'Verifying with AI...' : 'Verify with AI'),
            ),
          ),
          if (report != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: riskColor, width: 1.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _riskBadge(report, riskColor)),
                      Text('${report.score}/100',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        tooltip: 'Copy report',
                        onPressed: () => _copyReport(report),
                        icon: const Icon(Icons.copy_outlined),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Analyzed message or link',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SelectableText(report.input),
                  const SizedBox(height: 12),
                  Text(report.summary),
                  if (_aiResult != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'AI: ${_aiResult!.badgeText}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          'Model confidence: ${(_aiResult!.confidence * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      'This is not the probability that the link is safe.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(_aiResult!.summary),
                    const SizedBox(height: 8),
                    Text(
                      _aiResult!.reasoning,
                      style: TextStyle(color: Colors.grey[300], height: 1.4),
                    ),
                  ],
                  if (_aiError != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'AI report unavailable',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _aiError!,
                      style: TextStyle(color: Colors.grey[300], height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No AI verdict was received. The local pattern scan below is not an AI result.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                  if (_linkResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Link checks',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    for (final result in _linkResults) ...[
                      const SizedBox(height: 10),
                      Text(
                        result.label,
                        style: TextStyle(
                          color: switch (result.status) {
                            LinkVerificationStatus.knownThreat =>
                              Colors.redAccent,
                            LinkVerificationStatus.officialDomainMatch =>
                              Colors.greenAccent,
                            LinkVerificationStatus.notVerified =>
                              Colors.orangeAccent,
                          },
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(result.url),
                      const SizedBox(height: 4),
                      Text(
                        result.url,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.details,
                        style: TextStyle(color: Colors.grey[300], height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'A domain match does not prove a specific page is safe. No known threat found does not mean the link is safe.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                  if (_linkCheckError != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Link check unavailable',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _linkCheckError!,
                      style: TextStyle(color: Colors.grey[300], height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (report.indicators.isNotEmpty) ...[
                    const Text('Detected indicators',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...report.indicators.map((item) => _ReportLine(
                          icon: Icons.warning_amber,
                          color: Colors.orangeAccent,
                          text: item,
                        )),
                    const SizedBox(height: 12),
                  ],
                  const Text('What to do',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...report.recommendations.map((item) => _ReportLine(
                        icon: Icons.check_circle_outline,
                        color: Colors.greenAccent,
                        text: item,
                      )),
                  const SizedBox(height: 12),
                  Text(
                    'A pattern check is not proof that a message is safe or malicious.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.04, end: 0, duration: 280.ms),
          ] else ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(Icons.fact_check_outlined, color: Colors.grey[500]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Run a scan to see the threat assessment.',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportLine extends StatelessWidget {
  const _ReportLine(
      {required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      );
}
