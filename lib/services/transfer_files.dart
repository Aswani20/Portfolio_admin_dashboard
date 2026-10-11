import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../models/portfolio_transfer.dart';

abstract interface class TransferFiles {
  Future<String?> open();
  Future<String?> save(String document, {required bool backup});
}

class NativeTransferFiles implements TransferFiles {
  const NativeTransferFiles();
  static const types = [
    XTypeGroup(label: 'Portfolio JSON', extensions: ['json']),
  ];
  @override
  Future<String?> open() async {
    final file = await openFile(acceptedTypeGroups: types);
    if (file == null) return null;
    if (await file.length() > PortfolioTransfer.maxBytes) {
      throw const FormatException('Maximum transfer file size is 256 MB.');
    }
    return file.readAsString();
  }

  @override
  Future<String?> save(String document, {required bool backup}) async {
    final location = await getSaveLocation(
      suggestedName:
          'portfolio-${backup ? 'backup' : 'export'}-${DateTime.now().millisecondsSinceEpoch}.json',
      acceptedTypeGroups: types,
    );
    if (location == null) return null;
    final file = File(location.path);
    // The native picker may offer overwrite, but exports always require a new
    // filename so an older backup cannot accidentally be destroyed.
    await file.create(exclusive: true);
    await file.writeAsString(document, flush: true);
    return file.path;
  }
}
