import 'package:flutter_test/flutter_test.dart';
import 'package:cybersafe/services/threat_engine.dart';

void main() {
  group('ThreatEngine.analyze', () {
    test('returns a low-signal baseline for ordinary text', () {
      final report = ThreatEngine.analyze('See you at the station at six.');

      expect(report.score, 10);
      expect(report.riskLevel, 'Low Signals');
      expect(report.indicators, isEmpty);
      expect(report.recommendations, isNotEmpty);
    });

    test('raises the score for insecure links', () {
      final report = ThreatEngine.analyze('Visit http://example.com');

      expect(report.score, 30);
      expect(report.indicators.single, contains('HTTP'));
    });

    test('identifies a UPI PIN request as suspicious', () {
      final report = ThreatEngine.analyze('Scan this QR to receive money; enter your PIN.');

      expect(report.score, 50);
      expect(report.riskLevel, 'High Suspicion');
      expect(report.recommendations, contains(contains('Never scan a QR')));
    });

    test('matches a suspicious domain ending in a URL', () {
      final report = ThreatEngine.analyze('Review this link: https://example.xyz/path');

      expect(report.score, 40);
      expect(report.indicators, contains(contains('.xyz')));
    });
  });
}