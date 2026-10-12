import 'dart:convert';

import 'package:http/http.dart' as http;

enum LinkVerificationStatus {
  knownThreat,
  officialDomainMatch,
  notVerified,
}

class LinkVerificationResult {
  const LinkVerificationResult({
    required this.url,
    required this.status,
    required this.details,
    required this.threatTypes,
    required this.threatLookupPerformed,
  });

  final String url;
  final LinkVerificationStatus status;
  final String details;
  final List<String> threatTypes;
  final bool threatLookupPerformed;

  String get label => switch (status) {
        LinkVerificationStatus.knownThreat => 'Known threat detected',
        LinkVerificationStatus.officialDomainMatch =>
          'Matches a known official domain',
        LinkVerificationStatus.notVerified => 'Not verified',
      };
}

class LinkVerificationService {
  static const Set<String> _knownOfficialDomains = {
    'amazon.com',
    'amazon.in',
    'amazon.co.uk',
    'amazon.ca',
    'amazon.de',
    'amazon.co.jp',
    'google.com',
    'google.co.in',
    'microsoft.com',
    'microsoftonline.com',
    'apple.com',
    'apple.in',
  };

  static final RegExp _urlPattern = RegExp(
    r'\b(?:https?://|www\.)[^\s<>"\u0027]+',
    caseSensitive: false,
  );

  static Future<List<LinkVerificationResult>> verifyInput({
    required String input,
    String? safeBrowsingApiKey,
    http.Client? client,
  }) async {
    final urls = extractUrls(input);
    if (urls.isEmpty) {
      throw const FormatException('No valid web link was found in the input.');
    }

    final links = urls.map(_parseWebUrl).toList(growable: false);
    final apiKey = safeBrowsingApiKey?.trim() ?? '';
    final closeClient = client == null;
    final requestClient = client ?? http.Client();
    late final Map<String, List<String>> threatMatches;
    try {
      threatMatches = apiKey.isEmpty
          ? const <String, List<String>>{}
          : await _lookupThreats(links, apiKey, requestClient);
    } finally {
      if (closeClient) requestClient.close();
    }

    return [
      for (final uri in links)
        _resultFor(
          uri,
          threatMatches[uri.toString()] ?? const [],
          threatLookupPerformed: apiKey.isNotEmpty,
        ),
    ];
  }

  static List<String> extractUrls(String input) {
    final urls = <String>{};
    for (final match in _urlPattern.allMatches(input)) {
      final candidate =
          match.group(0)!.replaceFirst(RegExp(r'[.,!?;:)\]]+$'), '');
      try {
        final uri = _parseWebUrl(candidate);
        urls.add(uri.toString());
      } on FormatException {
        continue;
      }
    }

    if (urls.isEmpty && input.trim().contains('.') && !input.contains(' ')) {
      try {
        final uri = _parseWebUrl(input.trim());
        urls.add(uri.toString());
      } on FormatException {
        // Non-URL input should be reported as having no link.
      }
    }

    return urls.toList(growable: false);
  }

  static String? knownOfficialDomainFor(String host) {
    final normalizedHost = host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    for (final domain in _knownOfficialDomains) {
      if (normalizedHost == domain || normalizedHost.endsWith('.$domain')) {
        return domain;
      }
    }
    return null;
  }

  static Uri _parseWebUrl(String input) {
    final candidate = input.toLowerCase().startsWith('www.')
        ? 'https://$input'
        : input.contains('://')
            ? input
            : 'https://$input';
    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty ||
        !uri.host.contains('.')) {
      throw const FormatException('The input contains an invalid web link.');
    }
    return uri;
  }

  static Future<Map<String, List<String>>> _lookupThreats(
    List<Uri> links,
    String apiKey,
    http.Client client,
  ) async {
    final uri = Uri.https(
      'safebrowsing.googleapis.com',
      '/v4/threatMatches:find',
      {'key': apiKey},
    );
    final response = await client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'client': {
              'clientId': 'cybersafe-mini-project',
              'clientVersion': '1.0.0',
            },
            'threatInfo': {
              'threatTypes': [
                'MALWARE',
                'SOCIAL_ENGINEERING',
                'UNWANTED_SOFTWARE',
                'POTENTIALLY_HARMFUL_APPLICATION',
              ],
              'platformTypes': ['ANY_PLATFORM'],
              'threatEntryTypes': ['URL'],
              'threatEntries': [
                for (final link in links) {'url': link.toString()},
              ],
            },
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Google Safe Browsing check failed (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final matches = body['matches'];
    final result = <String, List<String>>{};
    if (matches is! List) return result;

    for (final match in matches) {
      if (match is! Map<String, dynamic>) continue;
      final threat = match['threat'];
      final url = threat is Map<String, dynamic> ? threat['url'] : null;
      final threatType = match['threatType'];
      if (url is String && threatType is String) {
        result.putIfAbsent(url, () => []).add(threatType);
      }
    }
    return result;
  }

  static LinkVerificationResult _resultFor(
    Uri uri,
    List<String> threatTypes, {
    required bool threatLookupPerformed,
  }) {
    if (threatTypes.isNotEmpty) {
      return LinkVerificationResult(
        url: uri.toString(),
        status: LinkVerificationStatus.knownThreat,
        details:
            'Google Safe Browsing lists this URL as ${threatTypes.join(', ')}.',
        threatTypes: threatTypes,
        threatLookupPerformed: threatLookupPerformed,
      );
    }

    final officialDomain = knownOfficialDomainFor(uri.host);

    if (officialDomain != null) {
      return LinkVerificationResult(
        url: uri.toString(),
        status: LinkVerificationStatus.officialDomainMatch,
        details: threatLookupPerformed
            ? 'The hostname is within the known official domain "$officialDomain", and Google Safe Browsing did not list this URL as a known threat.'
            : 'The hostname is within the known official domain "$officialDomain". Google Safe Browsing was not checked.',
        threatTypes: const [],
        threatLookupPerformed: threatLookupPerformed,
      );
    }

    return LinkVerificationResult(
      url: uri.toString(),
      status: LinkVerificationStatus.notVerified,
      details: threatLookupPerformed
          ? 'This hostname is not in the app’s small official-domain list. Google Safe Browsing did not list this URL as a known threat, but that does not prove it is genuine or safe.'
          : 'This hostname is not in the app’s small official-domain list. Configure Google Safe Browsing to check for known threats. The link is not verified.',
      threatTypes: const [],
      threatLookupPerformed: threatLookupPerformed,
    );
  }
}
