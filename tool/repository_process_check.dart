import 'package:image/image.dart' as img;

// Run using `dart run tool/repository_process_check.dart` from the project root.
// Uses a temporary store, never the user's application-data directory.
import 'dart:convert';
import 'dart:io';

import 'package:portfolio_admin_dashboard/data/json_portfolio_store.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_models.dart';
import 'package:portfolio_admin_dashboard/repositories/local_portfolio_repository.dart';
import 'package:portfolio_admin_dashboard/repositories/portfolio_repository.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    final directory = await Directory.systemTemp.createTemp(
      'portfolio_process_check_',
    );
    try {
      for (final mode in [
        'write',
        'read-update',
        'read-delete',
        'verify-deleted',
      ]) {
        final result = await Process.run(Platform.resolvedExecutable, [
          Platform.script.toFilePath(),
          mode,
          directory.path,
        ]);
        if (result.exitCode != 0) {
          throw StateError('$mode failed: ${result.stdout}\n${result.stderr}');
        }
        stdout.write(result.stdout);
      }
      final locker = await Process.start(Platform.resolvedExecutable, [
        Platform.script.toFilePath(),
        'lock',
        directory.path,
      ]);
      await locker.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
      try {
        final repository = LocalPortfolioRepository(
          JsonPortfolioStore(directory),
        );
        try {
          await repository.read();
          throw StateError('OS lock was not enforced');
        } on StoreException {
          stdout.writeln(
            'PASS: separate-process lock blocks concurrent access.',
          );
        }
      } finally {
        locker.stdin.writeln('release');
        await locker.stdin.close();
        await locker.exitCode;
      }
      stdout.writeln(
        'PASS: project CRUD/order, imported media and thumbnail references survived four separate Dart process launches; media remains after project deletion.',
      );
    } finally {
      await directory.delete(recursive: true);
    }
    return;
  }
  final directory = Directory(args[1]);
  if (args.first == 'lock') {
    final file = await File('${directory.path}/store.lock')
        .open(mode: FileMode.append);
    await file.lock(FileLock.exclusive);
    stdout.writeln('locked');
    await stdin.first;
    await file.unlock();
    await file.close();
    return;
  }
  final store = JsonPortfolioStore(directory);
  await store.initialize(
    loadSeed: () => File('assets/seed/portfolio.json').readAsString(),
    loadSeedMedia: (path) => File('assets/seed/media/$path').readAsBytes(),
  );
  final repository = LocalPortfolioRepository(store);
  const id = 'restart-test-sample';
  final record = await repository.projects.get(id);
  switch (args.first) {
    case 'write':
      final image = await repository.importImage(
        img.encodePng(img.Image(width: 7, height: 5)),
        filename: 'restart-cover.png',
      );
      await repository.projects.create(
        Project(
          id: id,
          title: 'Persisted sample',
          description: 'Temporary process test only',
          imagePaths: [image.sourcePath],
          techStack: [],
          liveUrl: null,
          githubUrl: null,
        ),
      );
      final savedProjects = await repository.projects.list();
      await repository.reorderProjects(
        savedProjects.reversed.map((p) => p.id).toList(),
        expectedRevisions: {for (final p in savedProjects) p.id: p.revision},
      );
    case 'read-update':
      if ((await repository.projects.list()).first.id != id) {
        throw StateError('Display order did not survive restart');
      }
      if (record?.title != 'Persisted sample') {
        throw StateError('Create did not survive restart');
      }
      final cover = (await repository.read()).media.singleWhere(
        (a) => a.sourcePath == record!.imagePaths.first,
      );
      if (img.decodePng(await repository.readMedia(cover.id))?.width != 7) {
        throw StateError(
          'Image bytes or thumbnail reference did not survive restart',
        );
      }
      await repository.projects.update(
        Project.fromJson({...record!.toJson(), 'title': 'Persisted update'}),
        expectedRevision: record.revision,
      );
    case 'read-delete':
      if (record?.title != 'Persisted update') {
        throw StateError('Update did not survive restart');
      }
      await repository.projects.delete(id, expectedRevision: record!.revision);
    case 'verify-deleted':
      final retained = (await repository.read()).media.singleWhere(
        (a) => a.label == 'restart-cover.png',
      );
      if (img.decodePng(await repository.readMedia(retained.id))?.height != 5) {
        throw StateError('Deleting a project removed shared media');
      }
      if (record != null || (await repository.projects.list()).length != 8) {
        throw StateError('Delete did not survive restart');
      }
  }
  stdout.writeln('PASS: ${args.first}');
}
