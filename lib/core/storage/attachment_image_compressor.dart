import 'dart:typed_data';

import 'package:workaxis/core/storage/attachment_storage.dart';

/// A prepared image and the encoding metadata required for its Storage object.
class CompressedAttachmentImage {
  const CompressedAttachmentImage({
    required this.bytes,
    required this.extension,
    required this.contentType,
  });

  final Uint8List bytes;
  final String extension;
  final String contentType;
}

/// Compresses user-selected image bytes before they leave the device.
abstract interface class AttachmentImageCompressor {
  Future<CompressedAttachmentImage> compress({
    required Uint8List bytes,
    required AttachmentKind kind,
  });
}

/// Raised when the selected data cannot be prepared as a supported image.
class AttachmentImageCompressionException implements Exception {
  const AttachmentImageCompressionException();
}
