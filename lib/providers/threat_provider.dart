import 'package:flutter/foundation.dart';

import '../services/threat_engine.dart';

class ThreatProvider extends ChangeNotifier {
  final List<ThreatReport> _reports = [];

  List<ThreatReport> get recentReports => List.unmodifiable(_reports);

  ThreatReport analyze(String input) {
    final report = ThreatEngine.analyze(input);
    _reports.insert(0, report);
    if (_reports.length > 10) _reports.removeLast();
    notifyListeners();
    return report;
  }
}