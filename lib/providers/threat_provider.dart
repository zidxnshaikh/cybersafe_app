import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/threat_engine.dart';

class ThreatProvider extends ChangeNotifier {
  static const _historyKey = 'recentThreatReports';

  final List<ThreatReport> _reports = [];
  late final Future<void> _historyLoaded;
  Future<void> _saveQueue = Future<void>.value();

  ThreatProvider() {
    _historyLoaded = _loadHistory();
  }

  List<ThreatReport> get recentReports => List.unmodifiable(_reports);

  ThreatReport analyze(String input) {
    final report = ThreatEngine.analyze(input);
    _reports.insert(0, report);
    if (_reports.length > 10) _reports.removeLast();
    _saveQueue = _saveQueue.then((_) => _saveHistory());
    notifyListeners();
    return report;
  }

  Future<void> _loadHistory() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_historyKey);
      if (encoded == null) return;

      final storedReports = jsonDecode(encoded);
      if (storedReports is! List) return;
      for (final item in storedReports) {
        if (item is! Map<String, dynamic>) continue;
        try {
          _reports.add(_reportFromJson(item));
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        }
      }

      // Keep reports created during startup ahead of restored history.
      _reports
          .sort((first, second) => second.createdAt.compareTo(first.createdAt));
      if (_reports.length > 10) _reports.removeRange(10, _reports.length);
      notifyListeners();
    } catch (_) {
      // A missing or unreadable local store should not prevent scanning.
    }
  }

  Future<void> _saveHistory() async {
    try {
      await _historyLoaded;
      final preferences = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_reports.map(_reportToJson).toList());
      await preferences.setString(_historyKey, encoded);
    } catch (_) {
      // Scanning remains available even when the device cannot persist history.
    }
  }

  static Map<String, Object> _reportToJson(ThreatReport report) => {
        'input': report.input,
        'createdAt': report.createdAt.toIso8601String(),
        'score': report.score,
        'riskLevel': report.riskLevel,
        'summary': report.summary,
        'indicators': report.indicators,
        'recommendations': report.recommendations,
      };

  static ThreatReport _reportFromJson(Map<String, dynamic> json) =>
      ThreatReport(
        input: json['input'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        score: json['score'] as int,
        riskLevel: json['riskLevel'] as String,
        summary: json['summary'] as String,
        indicators: (json['indicators'] as List).cast<String>(),
        recommendations: (json['recommendations'] as List).cast<String>(),
      );
}
