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

      expect(report.score, 20);
      expect(report.indicators.single, contains('HTTP'));
    });

    test('identifies a UPI PIN request as suspicious', () {
      final report = ThreatEngine.analyze(
          'Scan this QR to receive money; enter your PIN.');

      expect(report.score, 70);
      expect(report.riskLevel, 'Critical Hazard');
      expect(report.recommendations, contains(contains('Never scan a QR')));
    });

    test('matches a suspicious domain ending in a URL', () {
      final report =
          ThreatEngine.analyze('Review this link: https://example.xyz/path');

      expect(report.score, 25);
      expect(report.indicators, contains(contains('.xyz')));
    });

    test('does not treat shopping as the whole word pin', () {
      final report =
          ThreatEngine.analyze('Shopping for a gift to receive tomorrow.');

      expect(report.indicators, isNot(contains(contains('Payment PIN'))));
    });

    test('combines a topic word and urgency word', () {
      final report = ThreatEngine.analyze('Your parcel is due today.');

      expect(report.score, 30);
      expect(report.indicators, contains(contains('"parcel"')));
      expect(report.indicators, contains(contains('"today"')));
    });

    test('detects shortened URL hosts from parsed links', () {
      final report = ThreatEngine.analyze('Pay at https://bit.ly/parcel');

      expect(report.indicators, contains(contains('https://bit.ly/parcel')));
    });

    test('detects common Hinglish scam phrasing', () {
      final report = ThreatEngine.analyze('KYC update turant karein.');

      expect(report.indicators, contains(contains('KYC update turant karein')));
    });

    test('checks more than one URL in the same message', () {
      final report = ThreatEngine.analyze(
        'Compare https://safe.example/path with http://unsafe.xyz/pay',
      );

      expect(report.indicators, contains(contains('http://unsafe.xyz/pay')));
      expect(report.indicators, contains(contains('unsafe.xyz')));
    });

    test('caps the total contribution from urgency phrases', () {
      final report = ThreatEngine.analyze(
        'Disconnected suspended within 2 hours lottery winner enter PIN',
      );

      expect(report.score, 35);
    });

    test('uses matching summary and risk-level thresholds', () {
      final moderate = ThreatEngine.analyze('Your parcel is due today.');
      final high =
          ThreatEngine.analyze('Your parcel is due today: http://example.com');
      final critical = ThreatEngine.analyze(
        'Receive through QR, enter PIN at https://bit.ly/claim',
      );

      expect(moderate.riskLevel, 'Moderate Caution');
      expect(moderate.summary, contains('caution-worthy'));
      expect(high.riskLevel, 'High Suspicion');
      expect(high.summary, contains('warning signs'));
      expect(critical.riskLevel, 'Critical Hazard');
      expect(critical.summary, contains('critical warning signs'));
    });

    test('classifies impersonation and credential requests as high risk', () {
      final prizeRequest = ThreatEngine.analyze(
        'You are the lucky winner. Share your bank PIN and OTP to claim.',
      );
      final impersonation = ThreatEngine.analyze(
        'This is CBI Cyber Crime Cell. You are under digital arrest.',
      );

      expect(prizeRequest.riskLevel, 'High Suspicion');
      expect(impersonation.riskLevel, 'Critical Hazard');
    });
  });
}
