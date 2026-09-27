class ThreatReport {
  const ThreatReport({
    required this.score,
    required this.riskLevel,
    required this.summary,
    required this.indicators,
    required this.recommendations,
  });

  final int score;
  final String riskLevel;
  final String summary;
  final List<String> indicators;
  final List<String> recommendations;
}

class ThreatEngine {
  static const Set<String> _suspiciousTlds = {
    'xyz', 'top', 'buzz', 'rest', 'ru', 'cc', 'club', 'vip', 'click',
  };

  static const List<String> _urgencyPatterns = [
    'electricity will be cut', 'disconnected', 'suspended', 'within 2 hours',
    'lottery', 'winner', 'digital arrest', 'cbi', 'kyc expired', 'enter pin',
  ];

  static ThreatReport analyze(String input) {
    var score = 10;
    final indicators = <String>[];
    final recommendations = <String>[];
    final lower = input.toLowerCase();

    for (final pattern in _urgencyPatterns) {
      if (lower.contains(pattern)) {
        score += 25;
        indicators.add('Urgency/fear trigger detected: "$pattern"');
      }
    }

    if (lower.contains('pin') && (lower.contains('receive') || lower.contains('qr'))) {
      score += 40;
      indicators.add('Possible UPI PIN scam: a PIN is used to authorize payments.');
      recommendations.add('Never scan a QR code or enter a PIN to receive money.');
    }

    if (lower.contains('http://')) {
      score += 20;
      indicators.add('Insecure HTTP link detected; its connection is not encrypted.');
      recommendations.add('Avoid entering personal details on links that use HTTP.');
    }

    for (final tld in _suspiciousTlds) {
      if (RegExp('\\.$tld(?:[/:?#]|\$)').hasMatch(lower)) {
        score += 30;
        indicators.add('A potentially risky domain ending (.$tld) was found.');
      }
    }

    score = score.clamp(0, 100);
    final riskLevel = switch (score) {
      >= 70 => 'Critical Hazard',
      >= 40 => 'High Suspicion',
      >= 20 => 'Moderate Caution',
      _ => 'Low Signals',
    };

    if (indicators.isEmpty) {
      recommendations.add('Verify the sender through a separate trusted channel.');
      recommendations.add('Do not share passwords, one-time codes, or payment PINs.');
    }

    return ThreatReport(
      score: score,
      riskLevel: riskLevel,
      summary: score >= 50
          ? 'This message has warning signs associated with social engineering.'
          : 'No strong warning patterns were found by this basic local check.',
      indicators: indicators,
      recommendations: recommendations,
    );
  }
}