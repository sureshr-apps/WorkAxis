import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:workaxis/core/storage/attachment_image_compressor.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';

/// High-quality image compression backed by native encoders and browser Canvas.
class FlutterAttachmentImageCompressor implements AttachmentImageCompressor {
  const FlutterAttachmentImageCompressor();

  static const _maximumDimension = 1920;
  static const _quality = 85;

  @override
  Future<CompressedAttachmentImage> compress({
    required Uint8List bytes,
    required AttachmentKind kind,
  }) async {
    final sourceFormat = _ImageFormat.detect(bytes);
    final keepPng =
        kind == AttachmentKind.organizationLogo &&
        sourceFormat == _ImageFormat.png;
    final outputFormat = keepPng ? _ImageFormat.png : _ImageFormat.jpeg;

    late final Uint8List compressed;
    try {
      compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: _maximumDimension,
        minHeight: _maximumDimension,
        quality: _quality,
        format: keepPng ? CompressFormat.png : CompressFormat.jpeg,
        // Orientation is baked into the pixels; location and camera metadata
        // are intentionally not copied to uploaded files.
        keepExif: false,
      );
    } on UnimplementedError {
      return _originalOrThrow(bytes, sourceFormat);
    } on UnsupportedError {
      return _originalOrThrow(bytes, sourceFormat);
    } on Exception {
      return _originalOrThrow(bytes, sourceFormat);
    }

    if (compressed.isEmpty ||
        (sourceFormat != null && compressed.length >= bytes.length)) {
      return _originalOrThrow(bytes, sourceFormat);
    }

    return CompressedAttachmentImage(
      bytes: compressed,
      extension: outputFormat.extension,
      contentType: outputFormat.contentType,
    );
  }

  CompressedAttachmentImage _originalOrThrow(
    Uint8List bytes,
    _ImageFormat? format,
  ) {
    if (format == null) throw const AttachmentImageCompressionException();
    return CompressedAttachmentImage(
      bytes: bytes,
      extension: format.extension,
      contentType: format.contentType,
    );
  }
}

enum _ImageFormat {
  jpeg('jpg', 'image/jpeg'),
  png('png', 'image/png');

  const _ImageFormat(this.extension, this.contentType);

  final String extension;
  final String contentType;

  static _ImageFormat? detect(Uint8List bytes) {
    const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    if (bytes.length >= pngSignature.length) {
      var isPng = true;
      for (var index = 0; index < pngSignature.length; index++) {
        if (bytes[index] != pngSignature[index]) {
          isPng = false;
          break;
        }
      }
      if (isPng) return _ImageFormat.png;
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return _ImageFormat.jpeg;
    }
    return null;
  }
}
