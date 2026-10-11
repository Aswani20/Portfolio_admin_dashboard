import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_transfer.dart';

import 'fixture_repository.dart';

void main() {
  final cases = <(String, String, String, Object?)>[
    ('project title', 'projects', 'title', '   '),
    ('project link scheme', 'projects', 'githubUrl', 'file:///private'),
    ('education institution', 'education', 'institution', ''),
    ('experience role', 'experiences', 'role', ''),
    ('skill category title', 'skillCategories', 'title', ''),
    ('profile email', 'profiles', 'email', 'not-an-email'),
    ('CV download filename', 'settings', 'cvDownloadFilename', ''),
    ('section heading', 'sectionContent', 'heading', ''),
  ];
  for (final scenario in cases) {
    test('Import rejects invalid ${scenario.$1} with record context', () {
      final data = jsonDecode(PortfolioTransfer.encode(fixtureContent(), {}));
      final record = data['content'][scenario.$2][0];
      record[scenario.$3] = scenario.$4;
      expect(
        () => PortfolioTransfer.decode(jsonEncode(data)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'record context',
            contains(record['id']),
          ),
        ),
      );
    });
  }
  test(
    'nested skill model rejects out-of-range colors and wrong boolean types',
    () {
      for (final field in {'colorValue': -1, 'themeAdaptive': 'true'}.entries) {
        final data = jsonDecode(PortfolioTransfer.encode(fixtureContent(), {}));
        data['content']['skillCategories'][0]['skills'][0][field.key] =
            field.value;
        expect(
          () => PortfolioTransfer.decode(jsonEncode(data)),
          throwsA(isA<FormatException>()),
        );
      }
    },
  );
}
