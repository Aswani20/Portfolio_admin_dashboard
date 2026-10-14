import 'dart:isolate';

import 'package:crypto/crypto.dart';

import '../models/image_import.dart';
import '../models/portfolio_transfer.dart';
import '../models/record_ids.dart';
import '../models/portfolio_models.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../models/portfolio_content.dart';
import '../repositories/portfolio_repository.dart';

/// Small, versioned, append-only snapshots. A committed snapshot is never edited.
/// All reads/mutations reload the latest snapshot under process + OS file locks.
class JsonPortfolioStore {
  JsonPortfolioStore(this.directory);
  final Directory directory;
  static final Map<String, Future<void>> _queues = {};
  static const schemaVersion = 2;

  static Directory applicationDirectory() {
    final base = Platform.environment['LOCALAPPDATA'];
    if (!Platform.isWindows ||
        base == null ||
        base.trim().isEmpty ||
        !Directory(base).isAbsolute) {
      throw const StoreException(
        'Windows LOCALAPPDATA is unavailable. No data was written.',
      );
    }
    return Directory('$base${Platform.pathSeparator}PortfolioAdminDashboard');
  }

  Future<void> initialize({
    required Future<String> Function() loadSeed,
    required Future<Uint8List> Function(String) loadSeedMedia,
  }) => _locked(() async {
    final marker = File('${directory.path}/initialized');
    if (await marker.exists()) {
      await _read();
      return;
    }
    final existing = await directory
        .list()
        .where(
          (entry) =>
              entry.path !=
                  '${directory.path}${Platform.pathSeparator}store.lock' &&
              entry.path != '${directory.path}/store.lock',
        )
        .toList();
    if (existing.isNotEmpty) {
      throw StoreException(
        'Existing data found without an initialization marker in ${directory.path}. It has been preserved. Restore the complete store before retrying.',
      );
    }
    final seed = _decode(await loadSeed());
    if (seed.revision != 1) {
      throw const StoreException('Seed must start at revision 1.');
    }
    // A failure after this marker must never silently reseed over partial data.
    await marker.create(exclusive: true);
    await marker.writeAsString(
      'Portfolio Admin Dashboard schema 2\n',
      flush: true,
    );
    for (final asset in seed.content.media) {
      final bytes = await loadSeedMedia(asset.sourcePath);
      final target = File('${directory.path}/${asset.localPath}');
      await target.parent.create(recursive: true);
      if (await target.exists()) {
        throw StoreException(
          'Media already exists: ${target.path}. It was not overwritten.',
        );
      }
      final pending = File('${target.path}.pending');
      await pending.writeAsBytes(bytes, flush: true);
      await pending.rename(target.path);
    }
    await _write(seed);
  });

  Future<PortfolioContent> read() =>
      _locked(() async => (await _read()).content);

  Future<R> change<R>(R Function(Map<String, dynamic> content) edit) =>
      _locked(() async {
        final before = await _read();
        final document = before.content.toJson();
        final result = edit(document);
        late PortfolioContent validated;
        try {
          validated = PortfolioContent.fromJson(document);
        } on FormatException catch (error) {
          throw RepositoryException('Change rejected: ${error.message}');
        }

        // Existing missing files must not prevent repairing project references.
        // New or relocated media metadata still requires actual stored bytes.
        final oldPaths = {
          for (final asset in before.content.media) asset.id: asset.localPath,
        };
        for (final asset in validated.media) {
          if (oldPaths[asset.id] != asset.localPath &&
              !await File('${directory.path}/${asset.localPath}').exists()) {
            throw const StoreException(
              'Import the image before adding or relocating its metadata.',
            );
          }
        }
        await _write(_Snapshot(before.revision + 1, validated));
        return result;
      });

  Future<String> exportData({bool includeMedia = false}) => _locked(() async {
    final content = (await _read()).content;
    return _export(content, includeMedia: includeMedia);
  });

  Future<String> _export(
    PortfolioContent content, {
    required bool includeMedia,
  }) async {
    final files = <String, Uint8List>{};
    var total = 0;
    if (includeMedia) {
      for (final asset in content.media) {
        final file = File('${directory.path}/${asset.localPath}');
        if (!await file.exists()) continue;
        total += await file.length();
        if (total > PortfolioTransfer.maxBytes * 3 ~/ 4) {
          throw const RepositoryException(
            'Media exceeds the backup size limit. No content was replaced.',
          );
        }
        files[asset.id] = await file.readAsBytes();
      }
    }
    return PortfolioTransfer.encode(content, files);
  }

  Future<String> replaceData(
    String document, {
    required String expectedFingerprint,
  }) async {
    // Parse before acquiring the store lock; parse again is unnecessary because
    // the immutable input string is the exact file reviewed by the user.
    final transfer = PortfolioTransfer.decode(document);
    return _locked(() async {
      final before = await _read();
      if (PortfolioTransfer.fingerprint(before.content) !=
          expectedFingerprint) {
        throw const ConflictException(
          'Content changed since the preview. Review the import again. Nothing was replaced.',
        );
      }
      final backup = await _export(before.content, includeMedia: true);
      final backupDirectory = Directory('${directory.path}/backups');
      await backupDirectory.create(recursive: true);
      final backupFile = File(
        '${backupDirectory.path}/backup-${RecordIds.create()}.json',
      );
      final pendingBackup = File('${backupFile.path}.pending');
      await pendingBackup.writeAsString(backup, flush: true);
      await pendingBackup.rename(backupFile.path);

      final updated = transfer.content.toJson();
      final oldMedia = {
        for (final asset in before.content.media) asset.id: asset,
      };
      final batch = RecordIds.create();
      for (final value in jsonList(updated['media'])) {
        final asset = jsonObject(value);
        final id = asset['id'] as String;
        final bytes = transfer.files[id];
        final old = oldMedia[id];
        if (bytes == null &&
            old != null &&
            old.sourcePath == asset['sourcePath']) {
          asset['localPath'] = old.localPath;
        } else {
          // Never trust imported destination filenames, overwrite existing media,
          // or let an unrelated existing file satisfy an imported reference.
          final path = 'media/restored/$batch/${RecordIds.create()}.bin';
          asset['localPath'] = path;
          if (bytes != null) {
            final file = File('${directory.path}/$path');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes, flush: true);
          }
        }
      }
      // Local revision tokens must not resurrect stale editor revisions.
      for (final values in updated.values) {
        for (final record in jsonList(values)) {
          jsonObject(record)['revision'] = before.revision + 1;
        }
      }
      final validated = PortfolioContent.fromJson(updated);
      await _write(_Snapshot(before.revision + 1, validated));
      return backupFile.path;
    });
  }

  Future<Uint8List> readMedia(String id) => _locked(() async {
    final content = (await _read()).content;
    final matches = content.media.where((asset) => asset.id == id);
    if (matches.isEmpty) {
      throw RecordNotFoundException('Media $id was not found.');
    }
    return File('${directory.path}/${matches.single.localPath}').readAsBytes();
  });

  Future<MediaAsset> importImage(
    Uint8List data, {
    required String filename,
  }) async {
    // Copy caller-owned bytes before asynchronous validation/storage.
    final bytes = Uint8List.fromList(data);
    final info = await Isolate.run(
      () => ImageInfo.inspect(bytes, decode: true),
    );
    final digest = sha256.convert(bytes).toString();
    return _locked(() async {
      final before = await _read();
      for (final asset in before.content.media.where(
        (m) => m.kind == 'image',
      )) {
        final file = File('${directory.path}/${asset.localPath}');
        if (await file.exists() &&
            await file.length() == bytes.length &&
            sha256.convert(await file.readAsBytes()).toString() == digest) {
          return asset;
        }
      }
      final source = 'assets/images/imported/$digest.${info.extension}';
      final local = 'media/uploads/$digest.${info.extension}';
      final target = File('${directory.path}/$local');
      await target.parent.create(recursive: true);
      if (await target.exists()) {
        if (sha256.convert(await target.readAsBytes()).toString() != digest) {
          throw const StoreException(
            'An existing media file is damaged. It was preserved; restore it from backup.',
          );
        }
      } else {
        final pending = File('${target.path}.${RecordIds.create()}.pending');
        await pending.writeAsBytes(bytes, flush: true);
        await pending.rename(target.path);
      }
      final existing = before.content.media.where(
        (m) => m.sourcePath == source,
      );
      // Explicit re-import can restore missing bytes for an imported asset.
      if (existing.isNotEmpty) {
        final previous = existing.single;
        if (previous.localPath == local) return previous;
        // Restores remap local filenames. Repair the metadata as well as bytes
        // so a successful re-import makes that same record readable again.
        final repaired = MediaAsset.fromJson({
          ...previous.toJson(),
          'localPath': local,
          'revision': previous.revision + 1,
        });
        final document = before.content.toJson();
        final records = jsonList(document['media']);
        final index = records.indexWhere(
          (value) => jsonObject(value)['id'] == previous.id,
        );
        records[index] = repaired.toJson();
        await _write(
          _Snapshot(before.revision + 1, PortfolioContent.fromJson(document)),
        );
        return repaired;
      }
      final label = filename.replaceAll('\\', '/').split('/').last.trim();
      final asset = MediaAsset(
        id: RecordIds.create(),
        revision: 1,
        sourcePath: source,
        localPath: local,
        kind: 'image',
        label: label.isEmpty ? 'Imported image.${info.extension}' : label,
      );
      final document = before.content.toJson();
      jsonList(document['media']).add(asset.toJson());
      final content = PortfolioContent.fromJson(document);
      await _write(_Snapshot(before.revision + 1, content));
      return asset;
    });
  }

  Future<_Snapshot> _read() async {
    if (!await File('${directory.path}/initialized').exists()) {
      throw const StoreException('Store is not initialized.');
    }
    final entries = await directory
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    if (entries.isEmpty) {
      throw StoreException(
        'No committed data exists in ${directory.path}. Initialization may have been interrupted or data removed. Files have been preserved; restore a backup before retrying.',
      );
    }
    final revisions = <int, File>{};
    for (final entry in entries) {
      final name = entry.uri.pathSegments.last;
      final match = RegExp(r'^revision-(\d{12})\.json$').firstMatch(name);
      if (match == null) {
        throw StoreException(
          'Unrecognized store file: $name. No files were changed.',
        );
      }
      final revision = int.parse(match[1]!);
      if (revision < 1) {
        throw const StoreException(
          'Invalid snapshot revision. Files were preserved.',
        );
      }
      revisions[revision] = entry;
    }
    final latest = revisions.keys.reduce(max);
    if (latest != revisions.length || !revisions.containsKey(1)) {
      throw const StoreException(
        'Local snapshot history is incomplete. Restore the missing files before continuing.',
      );
    }
    final snapshot = _decode(await revisions[latest]!.readAsString());
    if (snapshot.revision != latest) {
      throw const StoreException(
        'Snapshot revision does not match its filename.',
      );
    }
    return snapshot;
  }

  _Snapshot _decode(String text) {
    final document = jsonObject(jsonDecode(text));
    if (![1, schemaVersion].contains(document['schemaVersion'])) {
      throw StoreException(
        'Unsupported local data schema: ${document['schemaVersion']}. Existing data was preserved.',
      );
    }
    if (document.length != 3 ||
        document['revision'] is! int ||
        (document['revision'] as int) < 1) {
      throw const FormatException('Invalid snapshot header.');
    }
    final raw = jsonObject(document['content']);
    if ((document['schemaVersion'] == 1 && raw.containsKey('articles')) ||
        (document['schemaVersion'] == 2 && !raw.containsKey('articles'))) {
      throw const FormatException(
        'Collections do not match the snapshot schema.',
      );
    }
    return _Snapshot(
      document['revision'] as int,
      PortfolioContent.fromJson(jsonObject(document['content'])),
    );
  }

  Future<void> _write(_Snapshot snapshot) async {
    final path =
        '${directory.path}/revision-${snapshot.revision.toString().padLeft(12, '0')}.json';
    if (await File(path).exists()) {
      throw const ConflictException(
        'A newer snapshot already exists. Retry the operation.',
      );
    }
    final pending = File(
      '$path.${DateTime.now().microsecondsSinceEpoch}.pending',
    );
    await pending.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': schemaVersion,
        'revision': snapshot.revision,
        'content': snapshot.content.toJson(),
      }),
      flush: true,
    );
    // Same-directory rename publishes a complete file; previous revisions remain.
    await pending.rename(path);
  }

  Future<T> _locked<T>(Future<T> Function() operation) {
    final key = directory.absolute.path.toLowerCase();
    final previous = _queues[key] ?? Future<void>.value();
    final release = Completer<void>();
    _queues[key] = release.future;
    return () async {
      await previous;
      RandomAccessFile? handle;
      var acquired = false;
      try {
        await directory.create(recursive: true);
        handle = await File('${directory.path}/store.lock')
            .open(mode: FileMode.append);
        try {
          await handle.lock(FileLock.exclusive);
          acquired = true;
        } on FileSystemException {
          throw const StoreException(
            'The local store is busy in another application instance. Close that instance and retry.',
          );
        }
        return await operation();
      } on RepositoryException {
        rethrow;
      } on FormatException catch (error) {
        throw StoreException(
          'Local data is invalid or corrupted: ${error.message}. Files in ${directory.path} were preserved. Restore a known-good backup before retrying.',
        );
      } on FileSystemException catch (error) {
        throw StoreException(
          'Local storage could not be accessed: ${error.message} (${error.path}). Check permissions, free space and backups.',
        );
      } finally {
        try {
          if (acquired) await handle?.unlock();
        } finally {
          try {
            await handle?.close();
          } finally {
            release.complete();
            if (identical(_queues[key], release.future)) _queues.remove(key);
          }
        }
      }
    }();
  }
}

class _Snapshot {
  const _Snapshot(this.revision, this.content);
  final int revision;
  final PortfolioContent content;
}
