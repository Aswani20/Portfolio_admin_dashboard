import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/data/json_portfolio_store.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_transfer.dart';
import 'package:portfolio_admin_dashboard/repositories/local_portfolio_repository.dart';
import 'package:portfolio_admin_dashboard/repositories/portfolio_repository.dart';
import 'package:portfolio_admin_dashboard/services/article_export.dart';

void main() {
  late Directory directory;
  late LocalPortfolioRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('articles_test_');
    final store = JsonPortfolioStore(directory);
    await store.initialize(
      loadSeed: () => File('assets/seed/portfolio.json').readAsString(),
      loadSeedMedia: (_) async => Uint8List.fromList([1]),
    );
    repository = LocalPortfolioRepository(store);
  });
  tearDown(() => directory.delete(recursive: true));
  Article sample(String id, {bool published = false}) => Article(
    id: id,
    title: 'A title',
    summary: 'Summary',
    body: 'Line one\n\nLine two with "quotes" and \$code',
    publishedOn: '2026-10-13',
    isPublished: published,
  );

  test('article CRUD, order, export and backup restore survive reopen without changing other content', () async {
    final original = await repository.read();
    expect(original.articles, isEmpty);
    final first = await repository.articles.create(
      sample('one', published: true),
    );
    final second = await repository.articles.create(sample('two'));
    await expectLater(
      repository.articles.create(sample('one')),
      throwsA(isA<ConflictException>()),
    );
    final updated = await repository.articles.update(
      Article.fromJson({...first.toJson(), 'title': 'Edited'}),
      expectedRevision: first.revision,
    );
    await repository.reorderContent(
      OrderedCollection.articles,
      ['two', 'one'],
      expectedRevisions: {'one': updated.revision, 'two': second.revision},
    );
    final reopened = LocalPortfolioRepository(JsonPortfolioStore(directory));
    final content = await reopened.read();
    expect(content.articles.map((a) => a.id), ['two', 'one']);
    expect(
      content.projects.map((p) => p.toJson()),
      original.projects.map((p) => p.toJson()),
    );
    final exported = jsonDecode(exportWebsiteArticles(content.articles));
    expect(exported['articles'].length, 1);
    expect(exported['articles'][0]['title'], 'Edited');
    expect(exported['articles'][0]['body'], first.body);
    expect(exported['articles'][0].containsKey('revision'), false);
    final backup = await reopened.exportData(includeMedia: true);
    final current = content.articles.last;
    await reopened.articles.delete(
      current.id,
      expectedRevision: current.revision,
    );
    expect(
      jsonDecode(
        exportWebsiteArticles((await reopened.read()).articles),
      )['articles'],
      isEmpty,
    );
    await reopened.replaceData(
      backup,
      expectedFingerprint: PortfolioTransfer.fingerprint(await reopened.read()),
    );
    expect(
      (await LocalPortfolioRepository(
        JsonPortfolioStore(directory),
      ).read()).articles.length,
      2,
    );
  });

  test(
    'legacy snapshots and transfers migrate to an empty article list safely',
    () async {
      final seed = jsonDecode(
        await File('assets/seed/portfolio.json').readAsString(),
      );
      final initial = File('${directory.path}/revision-000000000001.json');
      await initial.writeAsString(jsonEncode(seed));
      final before = await initial.readAsString();
      expect((await repository.read()).articles, isEmpty);
      expect(await initial.readAsString(), before);
      final legacy = jsonEncode({
        'format': 'portfolio-admin-transfer',
        'schemaVersion': 1,
        'content': seed['content'],
        'mediaFiles': {},
      });
      expect(PortfolioTransfer.decode(legacy).content.articles, isEmpty);
      await repository.articles.create(sample('migrated'));
      expect(
        jsonDecode(
          await File('${directory.path}/revision-000000000002.json')
              .readAsString(),
        )['schemaVersion'],
        2,
      );
      expect(await initial.readAsString(), before);
      await repository.replaceData(
        legacy,
        expectedFingerprint: PortfolioTransfer.fingerprint(
          await repository.read(),
        ),
      );
      expect((await repository.read()).articles, isEmpty);
    },
  );

  test(
    'required fields, invalid dates and malformed article schema are rejected',
    () async {
      for (final change in [
        {'title': ''},
        {'body': ''},
        {'publishedOn': '2026-02-30'},
      ]) {
        await expectLater(
          repository.articles.create(
            Article.fromJson({...sample('invalid').toJson(), ...change}),
          ),
          throwsA(isA<RepositoryException>()),
        );
      }
      expect((await repository.read()).articles, isEmpty);
      final data = jsonDecode(await repository.exportData());
      data['content'].remove('articles');
      expect(
        () => PortfolioTransfer.decode(jsonEncode(data)),
        throwsFormatException,
      );
    },
  );
}
