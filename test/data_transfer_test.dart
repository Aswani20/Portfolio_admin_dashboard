import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_admin_dashboard/data/json_portfolio_store.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_transfer.dart';
import 'package:portfolio_admin_dashboard/repositories/local_portfolio_repository.dart';
import 'package:portfolio_admin_dashboard/repositories/portfolio_repository.dart';

void main() {
  late Directory directory;
  late LocalPortfolioRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('transfer_test_');
    final store = JsonPortfolioStore(directory);
    await store.initialize(
      loadSeed: () => File('assets/seed/portfolio.json').readAsString(),
      loadSeedMedia: (_) async => Uint8List.fromList([1, 2, 3]),
    );
    repository = LocalPortfolioRepository(store);
  });
  tearDown(() => directory.delete(recursive: true));
  Future<String> token() async =>
      PortfolioTransfer.fingerprint(await repository.read());

  test('content export preserves IDs, order, relationships and excludes storage state', () async {
    final content = await repository.read();
    final text = await repository.exportData();
    final exported = PortfolioTransfer.decode(text);
    expect(exported.content.toJson(), content.toJson());
    expect(exported.files, isEmpty);
    expect(
      jsonDecode(text).keys,
      unorderedEquals(['format', 'schemaVersion', 'content', 'mediaFiles']),
    );
    expect(text, isNot(contains(directory.path)));
  });

  test('import persists on reopen and automatic backup restores previous content and media', () async {
    final before = await repository.read();
    final export = jsonDecode(
      await repository.exportData(includeMedia: true),
    ) as Map<String, dynamic>;
    export['content']['projects'][0]['title'] = 'Imported project';
    final backupPath = await repository.replaceData(
      jsonEncode(export),
      expectedFingerprint: await token(),
    );
    final reopened = LocalPortfolioRepository(JsonPortfolioStore(directory));
    final imported = await reopened.read();
    expect(imported.projects.first.title, 'Imported project');
    expect(imported.projects.first.id, before.projects.first.id);
    expect(
      imported.projects.first.imagePaths,
      before.projects.first.imagePaths,
    );
    expect(await reopened.readMedia(imported.media.first.id), [1, 2, 3]);
    expect(
      PortfolioTransfer.decode(await File(backupPath).readAsString()).content
          .toJson(),
      before.toJson(),
    );
    await reopened.replaceData(
      await File(backupPath).readAsString(),
      expectedFingerprint: PortfolioTransfer.fingerprint(imported),
    );
    final restored = await LocalPortfolioRepository(
      JsonPortfolioStore(directory),
    ).read();
    expect(restored.projects.first.title, before.projects.first.title);
    expect(
      restored.projects.map((p) => p.id),
      before.projects.map((p) => p.id),
    );
    expect(await reopened.readMedia(restored.media.first.id), [1, 2, 3]);
    expect(
      await File('${directory.path}/${before.media.first.localPath}').exists(),
      isTrue,
    );
    await expectLater(
      repository.projects.update(
        before.projects.first,
        expectedRevision: before.projects.first.revision,
      ),
      throwsA(isA<ConflictException>()),
    );
  });

  test('invalid JSON, schemas, duplicate IDs, unknown fields and broken references leave store untouched', () async {
    final original = await repository.exportData();
    final fingerprint = await token();
    final invalid = <String>['{', '[]'];
    void changed(void Function(dynamic) change) {
      final data = jsonDecode(original);
      change(data);
      invalid.add(jsonEncode(data));
    }

    changed((d) => d['schemaVersion'] = 99);
    changed((d) => d['content']['projects'].add(d['content']['projects'][0]));
    changed(
      (d) => d['content']['projects'][0]['imagePaths'] = ['missing/image.png'],
    );
    changed((d) => d['content']['settings'][0]['secretToken'] = 'not-allowed');
    changed((d) => d['content']['media'][0]['localPath'] = '../escape.png');
    changed(
      (d) => d['content']['skillCategories'][0]['skills'].add(
        d['content']['skillCategories'][0]['skills'][0],
      ),
    );
    for (final text in invalid) {
      await expectLater(
        repository.replaceData(text, expectedFingerprint: fingerprint),
        throwsA(isA<FormatException>()),
      );
      expect(await token(), fingerprint);
    }
    expect(await Directory('${directory.path}/backups').exists(), isFalse);
  });

  test('media checksum validation and stale previews fail before replacing content', () async {
    final original = await repository.exportData(includeMedia: true);
    final data = jsonDecode(original);
    data['mediaFiles'].values.first['base64'] = base64Encode([9]);
    await expectLater(
      repository.replaceData(
        jsonEncode(data),
        expectedFingerprint: await token(),
      ),
      throwsA(isA<FormatException>()),
    );
    final stale = await token();
    final first = (await repository.read()).projects.first;
    await repository.projects.update(
      Project.fromJson({...first.toJson(), 'title': 'Newer edit'}),
      expectedRevision: first.revision,
    );
    await expectLater(
      repository.replaceData(original, expectedFingerprint: stale),
      throwsA(isA<ConflictException>()),
    );
    expect((await repository.read()).projects.first.title, 'Newer edit');
  });

  test(
    'failure to create the automatic backup leaves content unchanged',
    () async {
      final text = await repository.exportData();
      final before = await token();
      await File('${directory.path}/backups').writeAsString('blocking file');
      await expectLater(
        repository.replaceData(text, expectedFingerprint: before),
        throwsA(isA<StoreException>()),
      );
      expect(await token(), before);
    },
  );

  test('missing media is reported by omission and metadata imports reuse matching local files', () async {
    final before = await repository.read();
    await File('${directory.path}/${before.media.first.localPath}').delete();
    final backup = PortfolioTransfer.decode(
      await repository.exportData(includeMedia: true),
    );
    expect(backup.files.length, before.media.length - 1);
    final text = await repository.exportData();
    await repository.replaceData(text, expectedFingerprint: await token());
    final after = await repository.read();
    expect(after.media.first.localPath, before.media.first.localPath);
    await expectLater(
      repository.readMedia(after.media.first.id),
      throwsA(isA<StoreException>()),
    );
    expect(await repository.readMedia(after.media[1].id), [1, 2, 3]);
  });
}
