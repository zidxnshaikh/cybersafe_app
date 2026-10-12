class ThreatReport {
  const ThreatReport({
    required this.input,
    required this.createdAt,
    required this.score,
    required this.riskLevel,
    required this.summary,
    required this.indicators,
    required this.recommendations,
  });

  final String input;
  final DateTime createdAt;
  final int score;
  final String riskLevel;
  final String summary;
  final List<String> indicators;
  final List<String> recommendations;
}

class ThreatEngine {
  static const Set<String> _suspiciousTlds = {
    'xyz',
    'top',
    'buzz',
    'rest',
    'ru',
    'cc',
    'club',
    'vip',
    'click',
  };
  static const Set<String> _shortenedUrlHosts = {
    'bit.ly',
    'tinyurl.com',
    'cutt.ly',
  };

  static const List<String> _topicWords = [
    'electricity',
    'bill',
    'power',
    'kyc',
    'account',
    'bank',
    'parcel',
    'delivery',
    'prize',
    'refund',
    'payment',
  ];
  static const List<String> _urgencyWords = [
    'today',
    'tonight',
    'immediately',
    'urgent',
    'expire',
    'expires',
    'hours',
    'suspend',
    'suspended',
    'block',
    'blocked',
    'verify now',
  ];
  static const List<String> _urgencyPhrases = [
    'electricity will be cut',
    'disconnected',
    'suspended',
    'within 2 hours',
    'lottery',
    'winner',
    'digital arrest',
    'cbi',
    'kyc expired',
    'enter pin',
    'upi pin',
  ];
  static const List<String> _hinglishPhrases = [
    'turant bhugtan karein',
    'aapka account band ho jayega',
    'kyc update turant karein',
  ];
  static final _credentialRequestPattern = RegExp(
    r'\b(?:share|send|provide)\b[^.!?]{0,50}\b(?:otp|pin|password)\b',
    caseSensitive: false,
  );

  static ThreatReport analyze(String input) {
    var score = 10;
    var urgencyPoints = 0;
    var hinglishPoints = 0;
    final indicators = <String>[];
    final recommendations = <String>[];
    final topicMatch = _firstWordMatch(input, _topicWords);
    final urgencyMatch = _firstWordMatch(input, _urgencyWords);

    // Add distinct urgency evidence, with a cap to prevent repeated wording from dominating.
    for (final phrase in _urgencyPhrases) {
      final match = _phraseMatch(input, phrase);
      if (match != null) {
        final addition = (8).clamp(0, 25 - urgencyPoints).toInt();
        urgencyPoints += addition;
        score += addition;
        indicators.add('Urgency phrase detected: "${match.group(0)}"');
      }
    }

    if (topicMatch != null && urgencyMatch != null) {
      score += 20;
      indicators.add(
        'Urgent request about "${topicMatch.group(0)}" uses "${urgencyMatch.group(0)}".',
      );
    }

    final cbiMatch = _phraseMatch(input, 'cbi');
    final digitalArrestMatch = _phraseMatch(input, 'digital arrest');
    if (cbiMatch != null && digitalArrestMatch != null) {
      score += 45;
      indicators.add(
        'Law-enforcement impersonation terms: "${cbiMatch.group(0)}" and "${digitalArrestMatch.group(0)}".',
      );
      recommendations.add(
        'End the contact and verify any case through an official agency number.',
      );
    }

    final credentialRequest = _credentialRequestPattern.firstMatch(input);
    if (credentialRequest != null) {
      score += 25;
      indicators.add(
        'Sensitive information request: "${credentialRequest.group(0)}".',
      );
      recommendations.add(
        'Never share one-time codes, passwords, or PINs in response to a message.',
      );
    }

    final pinMatch = _phraseMatch(input, 'pin');
    final paymentActionMatch = _firstWordMatch(input, ['receive', 'qr']);
    if (pinMatch != null && paymentActionMatch != null) {
      score += 60;
      indicators.add(
        'Payment PIN warning: "${pinMatch.group(0)}" appears with "${paymentActionMatch.group(0)}".',
      );
      recommendations
          .add('Never scan a QR code or enter a PIN to receive money.');
    }

    // Parse every extracted URL so host reputation and scheme checks use URI components.
    final urlMatches = RegExp(
      r'\b(?:https?://|www\.)[^\s<>"\u0027]+',
      caseSensitive: false,
    ).allMatches(input);
    var httpPoints = 0;
    var domainPoints = 0;
    for (final urlMatch in urlMatches) {
      final matchedUrl = urlMatch.group(0)!.replaceFirst(
            RegExp(r'[.,!?;:)\]]+$'),
            '',
          );
      final parseableUrl = matchedUrl.toLowerCase().startsWith('www.')
          ? 'https://$matchedUrl'
          : matchedUrl;
      final uri = Uri.tryParse(parseableUrl);
      if (uri == null || uri.host.isEmpty) continue;

      if (uri.scheme.toLowerCase() == 'http') {
        final addition = (10).clamp(0, 10 - httpPoints).toInt();
        httpPoints += addition;
        score += addition;
        indicators.add('Insecure link detected: "$matchedUrl" uses HTTP.');
        if (!recommendations.contains(
            'Avoid entering personal details on links that use HTTP.')) {
          recommendations
              .add('Avoid entering personal details on links that use HTTP.');
        }
      }

      final host = uri.host.toLowerCase();
      final tld = host.split('.').last;
      if (_suspiciousTlds.contains(tld) || _shortenedUrlHosts.contains(host)) {
        final addition = (15).clamp(0, 15 - domainPoints).toInt();
        domainPoints += addition;
        score += addition;
        indicators.add('Potentially risky link host: "$matchedUrl".');
        if (!recommendations.contains(
            'Check shortened or unfamiliar links through the official service.')) {
          recommendations.add(
              'Check shortened or unfamiliar links through the official service.');
        }
      }
    }

    for (final phrase in _hinglishPhrases) {
      final match = _phraseMatch(input, phrase);
      if (match != null) {
        final addition = (10).clamp(0, 20 - hinglishPoints).toInt();
        hinglishPoints += addition;
        score += addition;
        indicators.add('Hinglish scam phrase detected: "${match.group(0)}"');
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
      recommendations
          .add('Verify the sender through a separate trusted channel.');
      recommendations
          .add('Do not share passwords, one-time codes, or payment PINs.');
    }

    return ThreatReport(
      input: input,
      createdAt: DateTime.now(),
      score: score,
      riskLevel: riskLevel,
      // Match summary wording to the same boundaries used for the risk label.
      summary: switch (score) {
        >= 70 =>
          'This message has critical warning signs associated with social engineering.',
        >= 40 =>
          'This message has warning signs associated with social engineering.',
        >= 20 => 'This message has some caution-worthy patterns.',
        _ => 'No strong warning patterns were found by this basic local check.',
      },
      indicators: indicators,
      recommendations: recommendations,
    );
  }

  static RegExpMatch? _firstWordMatch(String input, List<String> words) {
    for (final word in words) {
      final match = _phraseMatch(input, word);
      if (match != null) return match;
    }
    return null;
  }

  static RegExpMatch? _phraseMatch(String input, String phrase) {
    final expression = phrase.split(' ').map(RegExp.escape).join(r'\s+');
    return RegExp(r'\b' + expression + r'\b', caseSensitive: false)
        .firstMatch(input);
  }
}
