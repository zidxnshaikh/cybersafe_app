import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cybersafe/services/link_verification_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('LinkVerificationService', () {
    test('extracts and normalizes links from a message', () {
      expect(
        LinkVerificationService.extractUrls(
          'Check https://amazon.com/orders and www.amazon.in/help.',
        ),
        [
          'https://amazon.com/orders',
          'https://www.amazon.in/help',
        ],
      );
    });

    test('matches known official domains and their subdomains only', () {
      expect(
        LinkVerificationService.knownOfficialDomainFor('blog.amazon.com'),
        'amazon.com',
      );
      expect(
        LinkVerificationService.knownOfficialDomainFor('amazon.com.evil.test'),
        isNull,
      );
      expect(
        LinkVerificationService.knownOfficialDomainFor('blog.amazon.net'),
        isNull,
      );
    });

    test('reports an unknown link as not verified without Safe Browsing key',
        () async {
      final results = await LinkVerificationService.verifyInput(
        input: 'https://blog.amazon.net/services',
      );

      expect(results, hasLength(1));
      expect(results.single.status, LinkVerificationStatus.notVerified);
      expect(results.single.threatLookupPerformed, isFalse);
      expect(results.single.details, contains('not verified'));
    });

    test('reports URLs returned by Safe Browsing as known threats', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'safebrowsing.googleapis.com');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['threatInfo']['threatEntries'], [
          {'url': 'https://example.test/phish'},
        ]);
        return http.Response(
          jsonEncode({
            'matches': [
              {
                'threatType': 'SOCIAL_ENGINEERING',
                'threat': {'url': 'https://example.test/phish'},
              },
            ],
          }),
          200,
        );
      });

      final results = await LinkVerificationService.verifyInput(
        input: 'https://example.test/phish',
        safeBrowsingApiKey: 'test-key',
        client: client,
      );

      expect(results.single.status, LinkVerificationStatus.knownThreat);
      expect(results.single.threatTypes, ['SOCIAL_ENGINEERING']);
    });

    test('a Safe Browsing no-match is still not treated as verified', () async {
      final client = MockClient(
        (_) async => http.Response('{}', 200),
      );

      final results = await LinkVerificationService.verifyInput(
        input: 'https://unlisted.example/phish',
        safeBrowsingApiKey: 'test-key',
        client: client,
      );

      expect(results.single.status, LinkVerificationStatus.notVerified);
      expect(results.single.threatLookupPerformed, isTrue);
      expect(results.single.details, contains('does not prove'));
    });

    test('rejects input that does not contain a web link', () async {
      expect(
        () => LinkVerificationService.verifyInput(input: 'hello, no link here'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
