import 'dart:typed_data';

import '../models/portfolio_models.dart';

/// Backend-neutral media operations. IDs identify metadata records, not paths.
/// Implementations resolve bytes and storage locations internally. A successful
/// import returns metadata only after its bytes can be read; shared files must
/// not be deleted implicitly when content references are removed.
abstract interface class MediaRepository {
  Future<Uint8List> readMedia(String id);

  /// Imports validated image bytes; identical content may reuse an existing asset.
  Future<MediaAsset> importImage(Uint8List bytes, {required String filename});
}
