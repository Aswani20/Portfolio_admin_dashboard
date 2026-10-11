import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../repositories/portfolio_repository.dart';

/// Transient inspection data, independent of physical storage paths.
class ImageInfo {
  const ImageInfo(this.extension, this.width, this.height, this.byteLength);
  final String extension;
  final int width;
  final int height;
  final int byteLength;
  static const maxBytes = 20 * 1024 * 1024;

  static ImageInfo inspect(Uint8List bytes, {bool decode = false}) {
    try {
      if (bytes.isEmpty || bytes.length > maxBytes) {
        throw const RepositoryException('Choose an image smaller than 20 MB.');
      }
      final decoder = img.findDecoderForData(bytes);
      final extension = switch (decoder) {
        img.PngDecoder() => 'png',
        img.JpegDecoder() => 'jpg',
        img.WebPDecoder() => 'webp',
        _ => throw const RepositoryException(
          'Supported images: PNG, JPEG and WebP.',
        ),
      };
      final info = decoder!.startDecode(bytes);
      if (info == null ||
          info.width < 1 ||
          info.height < 1 ||
          info.width * info.height > 40000000) {
        throw const RepositoryException(
          'Invalid image or dimensions exceed 40 megapixels.',
        );
      }
      if (decode && decoder.decodeFrame(0) == null) {
        throw const RepositoryException('This image cannot be decoded.');
      }
      return ImageInfo(extension, info.width, info.height, bytes.length);
    } on RepositoryException {
      rethrow;
    } catch (_) {
      throw const RepositoryException(
        'Invalid or damaged image. Choose another file.',
      );
    }
  }
}
