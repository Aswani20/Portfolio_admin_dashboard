// Uses a temporary store; each stage runs in a fresh Dart process.
import 'dart:convert';
import 'dart:io';

import 'package:portfolio_admin_dashboard/data/json_portfolio_store.dart';
import 'package:portfolio_admin_dashboard/models/portfolio_transfer.dart';
import 'package:portfolio_admin_dashboard/repositories/local_portfolio_repository.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    final directory = await Directory.systemTemp.createTemp(
      'portfolio_transfer_process_',
    );
    try {
      for (final stage in ['import', 'verify', 'restore', 'verify-restored']) {
        final result = await Process.run(Platform.resolvedExecutable, [
          Platform.script.toFilePath(),
          stage,
          directory.path,
        ]);
        if (result.exitCode != 0) {
          throw StateError('$stage: ${result.stdout} ${result.stderr}');
        }
        stdout.write(result.stdout);
      }
    } finally {
      await directory.delete(recursive: true);
    }
    return;
  }
  final store = JsonPortfolioStore(Directory('${args[1]}/store'));
  await store.initialize(
    loadSeed: () => File('assets/seed/portfolio.json').readAsString(),
    loadSeedMedia: (path) => File('assets/seed/media/$path').readAsBytes(),
  );
  final repository = LocalPortfolioRepository(store);
  final content = await repository.read();
  final pointer = File('${args[1]}/backup-path.txt');
  if (args.first == 'import') {
    final data = jsonDecode(await repository.exportData(includeMedia: true));
    data['content']['projects'][0]['title'] = 'Process import verification';
    final backup = await repository.replaceData(
      jsonEncode(data),
      expectedFingerprint: PortfolioTransfer.fingerprint(content),
    );
    await pointer.writeAsString(backup);
  } else if (args.first == 'restore') {
    await repository.replaceData(
      await File(await pointer.readAsString()).readAsString(),
      expectedFingerprint: PortfolioTransfer.fingerprint(content),
    );
  } else if (args.first == 'verify') {
    if (content.projects.first.title != 'Process import verification') {
      throw StateError('Import was not persisted');
    }
    if ((await repository.readMedia(content.media.first.id)).isEmpty) {
      throw StateError('Media missing');
    }
  } else {
    final original = PortfolioTransfer.decode(
      await File(await pointer.readAsString()).readAsString(),
    ).content;
    if (content.projects.first.title != original.projects.first.title) {
      throw StateError('Restore was not persisted');
    }
    if ((await repository.readMedia(content.media.first.id)).isEmpty) {
      throw StateError('Restored media missing');
    }
  }
  stdout.writeln('${args.first}: passed');
}
