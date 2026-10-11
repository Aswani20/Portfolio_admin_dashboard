import 'package:file_selector/file_selector.dart';

import '../models/image_import.dart';
import '../models/portfolio_models.dart';
import '../repositories/portfolio_repository.dart';
import '../repositories/media_repository.dart';

typedef ImageFilePicker = Future<List<XFile>> Function();

Future<List<XFile>> selectImageFiles() => openFiles(
  acceptedTypeGroups: const [
    XTypeGroup(
      label: 'Images (PNG, JPEG, WebP)',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
    ),
  ],
);

class ImportReport {
  ImportReport(this.assets, this.errors);
  final List<MediaAsset> assets;
  final List<String> errors;
}

/// Native file access stays outside widgets and the persistence implementation.
Future<ImportReport> importSelectedImages(
  MediaRepository repository, {
  ImageFilePicker picker = selectImageFiles,
}) async {
  final assets = <MediaAsset>[];
  final errors = <String>[];
  final files = await picker();
  for (final file in files) {
    try {
      if (await file.length() > ImageInfo.maxBytes) {
        throw const RepositoryException('Maximum image size is 20 MB.');
      }
      final asset = await repository.importImage(
        await file.readAsBytes(),
        filename: file.name,
      );
      if (!assets.any((a) => a.id == asset.id)) assets.add(asset);
    } catch (error) {
      errors.add('${file.name}: $error');
    }
  }
  return ImportReport(assets, errors);
}
