import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:file_selector/file_selector.dart';
import 'package:portfolio_admin_dashboard/data/json_portfolio_store.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_transfer.dart';
import 'package:portfolio_admin_dashboard/repositories/local_portfolio_repository.dart';
import 'package:portfolio_admin_dashboard/repositories/portfolio_repository.dart';
import 'package:portfolio_admin_dashboard/services/image_selection.dart';

void main() {
  late Directory directory;
  late LocalPortfolioRepository repository;
  final png = img.encodePng(img.Image(width: 3, height: 2));
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('portfolio_media_test_');
    final store = JsonPortfolioStore(directory);
    await store.initialize(
      loadSeed: () => File('assets/seed/portfolio.json').readAsString(),
      loadSeedMedia: (path) => File('assets/seed/media/$path').readAsBytes(),
    );
    repository = LocalPortfolioRepository(store);
  });
  tearDown(() async => directory.delete(recursive: true));

  test('imports portable references, deduplicates new and seeded bytes, survives reopen', () async {
    final asset = await repository.importImage(
      png,
      filename: r'C:\Pictures\sample.png',
    );
    expect(asset.label, 'sample.png');
    expect(asset.sourcePath, startsWith('assets/images/imported/'));
    expect(asset.sourcePath, isNot(contains(':')));
    final duplicate = await repository.importImage(
      png,
      filename: 'different-name.png',
    );
    expect(duplicate.id, asset.id);
    final original = (await repository.read()).media.firstWhere(
      (a) => a.kind == 'image',
    );
    expect(
      (await repository.importImage(
        await repository.readMedia(original.id),
        filename: 'copy.jpg',
      )).id,
      original.id,
    );
    expect((await repository.read()).media.length, 43);
    expect(await Directory('${directory.path}/media/uploads').list().length, 1);
    final reopened = LocalPortfolioRepository(JsonPortfolioStore(directory));
    expect(await reopened.readMedia(asset.id), png);
  });

  test(
    'thumbnail/gallery changes persist; removal keeps shared physical files',
    () async {
      final asset = await repository.importImage(png, filename: 'cover.png');
      final before = (await repository.projects.list()).first;
      final images = [asset.sourcePath, ...before.imagePaths];
      final saved = await repository.projects.update(
        Project.fromJson({...before.toJson(), 'imagePaths': images}),
        expectedRevision: before.revision,
      );
      final reopened = LocalPortfolioRepository(JsonPortfolioStore(directory));
      expect((await reopened.projects.get(saved.id))!.imagePaths, images);
      expect(
        (await reopened.projects.get(saved.id))!.description,
        before.description,
      );
      await reopened.projects.update(
        Project.fromJson({...saved.toJson(), 'imagePaths': before.imagePaths}),
        expectedRevision: saved.revision,
      );
      expect(await reopened.readMedia(asset.id), png);
      expect(
        (await reopened.read()).media.any((a) => a.id == asset.id),
        isTrue,
      );
    },
  );

  test('missing images do not block edits and explicit reimport restores imported bytes', () async {
    final asset = await repository.importImage(png, filename: 'recover.png');
    await File('${directory.path}/${asset.localPath}').delete();
    final store = JsonPortfolioStore(directory);
    await store.initialize(
      loadSeed: () => throw StateError('Never reseed'),
      loadSeedMedia: (_) => throw StateError('Never recopy'),
    );
    await expectLater(
      repository.readMedia(asset.id),
      throwsA(isA<StoreException>()),
    );
    final project = (await repository.projects.list()).first;
    await repository.projects.update(
      Project.fromJson({...project.toJson(), 'title': 'Still editable'}),
      expectedRevision: project.revision,
    );
    expect(
      (await repository.importImage(png, filename: 'recover.png')).id,
      asset.id,
    );
    expect(await repository.readMedia(asset.id), png);
  });

  test(
    'reimport repairs a missing image after backup remapped its local path',
    () async {
      final asset = await repository.importImage(png, filename: 'recover.png');
      final backup = await repository.exportData(includeMedia: true);
      await repository.replaceData(
        backup,
        expectedFingerprint: PortfolioTransfer.fingerprint(
          await repository.read(),
        ),
      );
      final restored = (await repository.media.get(asset.id))!;
      expect(restored.localPath, isNot(asset.localPath));
      await File('${directory.path}/${restored.localPath}').delete();
      final recovered = await repository.importImage(
        png,
        filename: 'recover.png',
      );
      expect(recovered.id, asset.id);
      expect(await repository.readMedia(asset.id), png);
      expect((await repository.read()).media.length, 43);
      expect(
        await LocalPortfolioRepository(JsonPortfolioStore(directory))
            .readMedia(asset.id),
        png,
      );
    },
  );

  test('selection handles cancel, multiple files, invalid and missing files individually', () async {
    expect(
      (await importSelectedImages(repository, picker: () async => [])).assets,
      isEmpty,
    );
    final result = await importSelectedImages(
      repository,
      picker: () async => [
        XFile.fromData(png, name: 'valid.png'),
        XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'invalid.png'),
        XFile('${directory.path}/missing.png'),
        XFile.fromData(png, name: 'duplicate.png'),
      ],
    );
    expect(result.assets.length, 1);
    expect(result.errors.length, 2);
    expect((await repository.read()).media.length, 43);
    await expectLater(
      repository.importImage(
        img.encodeGif(img.Image(width: 1, height: 1)),
        filename: 'unsupported.gif',
      ),
      throwsA(isA<RepositoryException>()),
    );
    await expectLater(
      repository.importImage(
        Uint8List(20 * 1024 * 1024 + 1),
        filename: 'large.png',
      ),
      throwsA(isA<RepositoryException>()),
    );
    final jpeg = await repository.importImage(
      img.encodeJpg(img.Image(width: 3, height: 2)),
      filename: 'photo.jpeg',
    );
    expect(jpeg.sourcePath, endsWith('.jpg'));
  });
}
