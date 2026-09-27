import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/threat_provider.dart';
import '../services/threat_engine.dart';

class ThreatScannerScreen extends StatefulWidget {
  const ThreatScannerScreen({super.key});

  @override
  State<ThreatScannerScreen> createState() => _ThreatScannerScreenState();
}

class _ThreatScannerScreenState extends State<ThreatScannerScreen> {
  final _controller = TextEditingController();
  ThreatReport? _currentReport;
  bool _isScanning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final report = _currentReport;
    final riskColor = report == null
        ? Theme.of(context).colorScheme.primary
        : report.score >= 40 ? Colors.redAccent : Colors.greenAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phishing & Scam Link Analyzer', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 6),
          Text('Check suspicious messages and links with an on-device pattern scan.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Paste a suspicious SMS, URL, or chat message',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _runScan,
              icon: _isScanning
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.security),
              label: Text(_isScanning ? 'Checking message...' : 'Scan threat level'),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(report.riskLevel.toUpperCase(),
                        style: TextStyle(color: riskColor, fontWeight: FontWeight.bold))),
                      Text('${report.score}/100', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(report.summary),
                  const SizedBox(height: 14),
                  if (report.indicators.isNotEmpty) ...[
                    const Text('Detected indicators', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...report.indicators.map((item) => _ReportLine(
                      icon: Icons.warning_amber, color: Colors.orangeAccent, text: item,
                    )),
                    const SizedBox(height: 12),
                  ],
                  const Text('What to do', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...report.recommendations.map((item) => _ReportLine(
                    icon: Icons.check_circle_outline, color: Colors.greenAccent, text: item,
                  )),
                  const SizedBox(height: 12),
                  Text('A pattern check is not proof that a message is safe or malicious.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
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
  const _ReportLine({required this.icon, required this.color, required this.text});

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