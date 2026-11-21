import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/core/storage/attachment_image_compressor.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/storage/flutter_attachment_image_compressor.dart';

/// Cloud Storage implementation of [AttachmentStorage].
///
/// Objects live at `organizations/{organizationId}/{kind folder}/
/// {optional scoped path segments}/{uuid}.{ext}`. Only that path is persisted;
/// `storage.rules` decide who may read it, and a download URL is requested at
/// display time.
class FirebaseAttachmentStorage implements ScopedAttachmentStorage {
  FirebaseAttachmentStorage({
    required this.bucket,
    FirebaseStorage? storage,
    AttachmentImageCompressor? compressor,
  }) : _injected = storage,
       _compressor = compressor ?? const FlutterAttachmentImageCompressor();

  /// Bucket name without the `gs://` prefix.
  final String bucket;

  final FirebaseStorage? _injected;
  final AttachmentImageCompressor _compressor;

  // Resolved lazily so mocks and tests never touch the Firebase singleton.
  FirebaseStorage get _storage =>
      _injected ?? FirebaseStorage.instanceFor(bucket: 'gs://$bucket');

  @override
  Future<String> upload({
    required String localPath,
    required String organizationId,
    required AttachmentKind kind,
  }) => uploadScoped(
    localPath: localPath,
    organizationId: organizationId,
    kind: kind,
    pathSegments: const [],
  );

  @override
  Future<String> uploadScoped({
    required String localPath,
    required String organizationId,
    required AttachmentKind kind,
    required List<String> pathSegments,
  }) async {
    final segmentPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
    if (pathSegments.any((segment) => !segmentPattern.hasMatch(segment))) {
      throw ValidationException('The attachment location is invalid.');
    }
    // XFile reads both file paths (Android) and blob URLs (web).
    final file = XFile(localPath);
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw ValidationException('Choose an image before uploading.');
    }

    late final CompressedAttachmentImage image;
    try {
      image = await _compressor.compress(bytes: bytes, kind: kind);
    } on AttachmentImageCompressionException {
      throw ValidationException(
        'This image could not be prepared for upload. Choose another image and try again.',
      );
    }

    // Match the strict `<` limits enforced by storage.rules, after compression
    // has had a chance to bring large camera images under the upload limit.
    if (image.bytes.length >= kind.maxBytes) {
      throw ValidationException(
        'The image is too large. Choose one under ${kind.maxMegabytes} MB.',
      );
    }
    final scopedPath = pathSegments.isEmpty ? '' : '${pathSegments.join('/')}/';
    final path =
        '${AttachmentReference.storagePrefix}$organizationId/'
        '${kind.folder}/$scopedPath${RequestIds.uuidV4()}.${image.extension}';
    await _storage
        .ref(path)
        .putData(image.bytes, SettableMetadata(contentType: image.contentType));
    return path;
  }

  @override
  Future<String> resolveUrl(String reference) {
    if (AttachmentReference.isRemoteUrl(reference)) {
      return Future.value(reference);
    }
    return _storage.ref(reference).getDownloadURL();
  }
}
