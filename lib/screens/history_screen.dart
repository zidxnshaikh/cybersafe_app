import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/threat_provider.dart';
import '../services/threat_engine.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ThreatProvider>().recentReports;
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 32, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text('Scanned messages will appear here.',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _HistoryReport(report: reports[index]),
    );
  }
}

class _HistoryReport extends StatelessWidget {
  const _HistoryReport({required this.report});

  final ThreatReport report;

  @override
  Widget build(BuildContext context) {
    final riskColor = switch (report.score) {
      >= 70 => Colors.redAccent,
      >= 40 => Colors.orangeAccent,
      >= 20 => Colors.amber,
      _ => const Color(0xFF10B981),
    };
    final snippet = report.input.replaceAll(RegExp(r'\s+'), ' ').trim();
    final shortSnippet =
        snippet.length > 110 ? '${snippet.substring(0, 107)}...' : snippet;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(report.riskLevel,
                    style: TextStyle(
                        color: riskColor, fontWeight: FontWeight.w700)),
              ),
              Text('${report.score}/100',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(shortSnippet, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(_formatTimestamp(report.createdAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final localTime = timestamp.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reportDay = DateTime(localTime.year, localTime.month, localTime.day);
    final dayDifference = today.difference(reportDay).inDays;

    if (dayDifference == 0) {
      return 'Today, ${DateFormat('h:mm a').format(localTime)}';
    }
    if (dayDifference == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(localTime)}';
    }
    if (dayDifference < 7) {
      return DateFormat('EEE, h:mm a').format(localTime);
    }
    return DateFormat('MMM d, h:mm a').format(localTime);
  }
}
