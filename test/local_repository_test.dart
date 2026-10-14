import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/data/json_portfolio_store.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_content.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:portfolio_admin_dashboard/models/record_ids.dart';
import 'package:portfolio_admin_dashboard/repositories/local_portfolio_repository.dart';
import 'package:portfolio_admin_dashboard/repositories/portfolio_repository.dart';

void main() {
  late Directory directory;
  late JsonPortfolioStore store;
  late LocalPortfolioRepository repository;
  final seedText = File('assets/seed/portfolio.json').readAsStringSync();
  Future<void> initialize(JsonPortfolioStore target) => target.initialize(
    loadSeed: () async => seedText,
    loadSeedMedia: (path) async => Uint8List.fromList(path.codeUnits),
  );
  Future<File> latest() async {
    final files = await directory
        .list()
        .where((f) => f.path.endsWith('.json'))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files.last;
  }

  Project sample(String id) => Project(
    id: id,
    title: 'Sample',
    description: 'Repository test',
    imagePaths: [],
    techStack: ['Dart'],
    liveUrl: null,
    githubUrl: null,
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'portfolio_repository_test_',
    );
    store = JsonPortfolioStore(directory);
    await initialize(store);
    repository = LocalPortfolioRepository(store);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'seed preserves every field, nested relationship, media and order',
    () async {
      final content = await repository.read();
      expect(content.toJson(), {
        ...(jsonDecode(seedText) as Map)['content'] as Map,
        'articles': [],
      });
      expect(content.projects.length, 8);
      expect(content.education.length, 5);
      expect(content.experiences.length, 3);
      expect(content.experiences[1].milestones.single.title, 'Flutter Mentor');
      expect(
        content.skillCategories.fold<int>(0, (sum, c) => sum + c.skills.length),
        15,
      );
      expect(content.media.length, 42);
      expect(content.profiles.single.name, 'Abdelrahman Youssef');
      expect(content.projects.first.imagePaths.length, 12);
      expect(content.profiles.single.heroName, startsWith('\t'));
      expect(() => content.projects.clear(), throwsUnsupportedError);
      expect(
        () => content.projects.first.imagePaths.clear(),
        throwsUnsupportedError,
      );
      expect(
        await repository.readMedia(content.media.first.id),
        content.media.first.sourcePath.codeUnits,
      );
    },
  );

  test('create, read, update, delete and reopen through repository', () async {
    final id = RecordIds.create();
    final saved = await repository.projects.create(sample(id));
    expect(saved.revision, 1);
    expect((await repository.projects.get(id))!.title, 'Sample');
    final edited = Project.fromJson({...saved.toJson(), 'title': 'Updated'});
    final updated = await repository.projects.update(
      edited,
      expectedRevision: saved.revision,
    );
    expect(updated.id, id);
    expect(updated.revision, 2);
    final reopenedStore = JsonPortfolioStore(directory);
    await reopenedStore.initialize(
      loadSeed: () => throw StateError('Must not reseed'),
      loadSeedMedia: (_) => throw StateError('Must not copy media'),
    );
    final reopened = LocalPortfolioRepository(reopenedStore);
    expect((await reopened.projects.get(id))!.title, 'Updated');
    await reopened.projects.delete(id, expectedRevision: 2);
    await initialize(JsonPortfolioStore(directory));
    expect(
      await LocalPortfolioRepository(JsonPortfolioStore(directory)).projects
          .get(id),
      isNull,
    );
    expect((await repository.projects.list()).length, 8);
  });

  test(
    'duplicate IDs, stale edits and stale deletes cannot overwrite data',
    () async {
      final saved = await repository.projects.create(sample('conflict-sample'));
      await expectLater(
        repository.projects.create(sample(saved.id)),
        throwsA(isA<ConflictException>()),
      );
      await repository.projects.update(
        Project.fromJson({...saved.toJson(), 'title': 'First edit'}),
        expectedRevision: 1,
      );
      await expectLater(
        repository.projects.update(saved, expectedRevision: 1),
        throwsA(isA<ConflictException>()),
      );
      await expectLater(
        repository.projects.delete(saved.id, expectedRevision: 1),
        throwsA(isA<ConflictException>()),
      );
      expect((await repository.projects.get(saved.id))!.title, 'First edit');
      await expectLater(
        repository.projects.delete('absent', expectedRevision: 1),
        throwsA(isA<RecordNotFoundException>()),
      );
    },
  );

  test(
    'concurrent repository instances serialize without losing records',
    () async {
      final other = LocalPortfolioRepository(JsonPortfolioStore(directory));
      await Future.wait(
        List.generate(
          12,
          (i) => (i.isEven ? repository : other).projects.create(
            sample('parallel-$i'),
          ),
        ),
      );
      expect((await repository.projects.list()).length, 20);
    },
  );

  test(
    'invalid references, singleton removal and path traversal are rejected',
    () async {
      final content = await repository.read();
      final before = await (await latest()).readAsString();
      final referenced = content.media.firstWhere(
        (m) => m.sourcePath == content.projects.first.imagePaths.first,
      );
      await expectLater(
        repository.media.delete(
          referenced.id,
          expectedRevision: referenced.revision,
        ),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        repository.profiles.delete(
          content.profiles.single.id,
          expectedRevision: 1,
        ),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        repository.media.update(
          MediaAsset.fromJson({
            ...referenced.toJson(),
            'localPath': '../outside.png',
          }),
          expectedRevision: 1,
        ),
        throwsA(isA<RepositoryException>()),
      );
      expect(await (await latest()).readAsString(), before);
    },
  );

  test(
    'malformed latest data is preserved and never reseeded or rolled back',
    () async {
      await repository.projects.create(sample('before-corruption'));
      final file = await latest();
      await file.writeAsString('{broken');
      await expectLater(
        initialize(JsonPortfolioStore(directory)),
        throwsA(isA<StoreException>()),
      );
      await expectLater(
        repository.projects.create(sample('after-corruption')),
        throwsA(isA<StoreException>()),
      );
      expect(await file.readAsString(), '{broken');
      expect(
        await File('${directory.path}/revision-000000000001.json').exists(),
        isTrue,
      );
    },
  );

  test('revision zero cannot conceal a missing committed snapshot', () async {
    await repository.projects.create(sample('history-two'));
    await repository.projects.create(sample('history-three'));
    await File('${directory.path}/revision-000000000002.json')
        .rename('${directory.path}/revision-000000000000.json');
    await expectLater(repository.read(), throwsA(isA<StoreException>()));
    expect(
      await File('${directory.path}/revision-000000000003.json').exists(),
      isTrue,
    );
  });

  test('future schemas and unknown model fields fail closed', () async {
    final file = await latest();
    final document =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    document['schemaVersion'] = 99;
    final future = jsonEncode(document);
    await file.writeAsString(future);
    await expectLater(repository.read(), throwsA(isA<StoreException>()));
    expect(await file.readAsString(), future);
    document['schemaVersion'] = 1;
    document['content']['projects'][0]['unknownField'] = 'preserve';
    await file.writeAsString(jsonEncode(document));
    await expectLater(repository.read(), throwsA(isA<StoreException>()));
    expect(await file.readAsString(), contains('unknownField'));
  });

  test('missing data and missing media do not trigger reseeding', () async {
    final content = await repository.read();
    final asset = File('${directory.path}/${content.media.first.localPath}');
    await asset.rename('${asset.path}.saved');
    await initialize(JsonPortfolioStore(directory));
    await expectLater(
      repository.readMedia(content.media.first.id),
      throwsA(isA<StoreException>()),
    );
    expect((await repository.read()).media.length, content.media.length);
    await (await latest()).rename('${directory.path}/snapshot.saved');
    await expectLater(
      initialize(JsonPortfolioStore(directory)),
      throwsA(isA<StoreException>()),
    );
    expect(await asset.exists(), isFalse);
  });

  test(
    'uncommitted pending snapshot is ignored; committed history stays intact',
    () async {
      final committed = await (await latest()).readAsString();
      await File(
        '${directory.path}/revision-000000000002.json.interrupted.pending',
      ).writeAsString('{unfinished');
      await initialize(JsonPortfolioStore(directory));
      expect((await repository.read()).projects.length, 8);
      await repository.projects.create(sample('after-interruption'));
      expect(
        await File('${directory.path}/revision-000000000001.json')
            .readAsString(),
        committed,
      );
      expect(
        await File(
          '${directory.path}/revision-000000000002.json.interrupted.pending',
        ).readAsString(),
        '{unfinished',
      );
    },
  );

  test(
    'interrupted first initialization preserves partial data and blocks reseed',
    () async {
      final child = Directory('${directory.path}/interrupted');
      final interrupted = JsonPortfolioStore(child);
      await expectLater(
        interrupted.initialize(
          loadSeed: () async => seedText,
          loadSeedMedia: (_) async =>
              throw const FileSystemException('Simulated copy failure'),
        ),
        throwsA(isA<StoreException>()),
      );
      expect(await File('${child.path}/initialized').exists(), isTrue);
      await expectLater(
        initialize(interrupted),
        throwsA(isA<StoreException>()),
      );
    },
  );

  test('model serialization rejects missing and wrong-typed fields', () {
    final document =
        (jsonDecode(seedText) as Map<String, dynamic>)['content']
            as Map<String, dynamic>;
    document['projects'][0]['title'] = 42;
    expect(() => PortfolioContent.fromJson(document), throwsFormatException);
  });
  test(
    'failed disk commit leaves the previous snapshot intact and queue usable',
    () async {
      final before = await (await latest()).readAsString();
      final obstruction = Directory(
        '${directory.path}/revision-000000000002.json',
      );
      await obstruction.create();
      await expectLater(
        repository.projects.create(sample('failed-write')),
        throwsA(isA<StoreException>()),
      );
      expect((await repository.projects.list()).length, 8);
      expect(
        await File('${directory.path}/revision-000000000001.json')
            .readAsString(),
        before,
      );
      await obstruction.delete();
      await repository.projects.create(sample('successful-retry'));
      expect(await repository.projects.get('successful-retry'), isNotNull);
      expect(await repository.projects.get('failed-write'), isNull);
    },
  );

  test('project reordering persists atomically and rejects stale or partial orders', () async {
    final before = await repository.projects.list();
    final ids = before.reversed.map((p) => p.id).toList();
    final revisions = {for (final p in before) p.id: p.revision};
    await repository.reorderProjects(ids, expectedRevisions: revisions);
    final reopened = LocalPortfolioRepository(JsonPortfolioStore(directory));
    expect((await reopened.projects.list()).map((p) => p.id).toList(), ids);
    expect(
      (await reopened.projects.get(before.first.id))!.description,
      before.first.description,
    );
    await expectLater(
      repository.reorderProjects(
        ids.reversed.toList(),
        expectedRevisions: revisions,
      ),
      throwsA(isA<ConflictException>()),
    );
    await expectLater(
      repository.reorderProjects(ids.sublist(1), expectedRevisions: revisions),
      throwsA(isA<ConflictException>()),
    );
    expect((await reopened.projects.list()).map((p) => p.id).toList(), ids);
  });
  test(
    'project required fields and unsafe URL schemes fail before commit',
    () async {
      final before = await repository.projects.list();
      final blank = Project.fromJson({
        ...sample('invalid').toJson(),
        'title': '   ',
      });
      await expectLater(
        repository.projects.create(blank),
        throwsA(isA<RepositoryException>()),
      );
      final invalidUrl = Project.fromJson({
        ...before.first.toJson(),
        'liveUrl': 'javascript:alert(1)',
      });
      await expectLater(
        repository.projects.update(
          invalidUrl,
          expectedRevision: before.first.revision,
        ),
        throwsA(isA<RepositoryException>()),
      );
      expect(
        (await repository.projects.list()).map((p) => p.toJson()).toList(),
        before.map((p) => p.toJson()).toList(),
      );
    },
  );
}
