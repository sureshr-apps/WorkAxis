import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';

/// Cloud Storage implementation of [AttachmentStorage].
///
/// Objects live at `organizations/{organizationId}/{kind folder}/
/// {optional scoped path segments}/{uuid}.{ext}`. Only that path is persisted;
/// `storage.rules` decide who may read it, and a download URL is requested at
/// display time.
class FirebaseAttachmentStorage implements ScopedAttachmentStorage {
  FirebaseAttachmentStorage({required this.bucket, FirebaseStorage? storage})
    : _injected = storage;

  /// Bucket name without the `gs://` prefix.
  final String bucket;

  final FirebaseStorage? _injected;

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
    if (bytes.length > kind.maxBytes) {
      throw ValidationException(
        'The image is too large. Choose one under ${kind.maxMegabytes} MB.',
      );
    }
    final isPng =
        (file.mimeType ?? '').toLowerCase() == 'image/png' ||
        localPath.toLowerCase().endsWith('.png');
    final extension = isPng ? 'png' : 'jpg';
    final scopedPath = pathSegments.isEmpty ? '' : '${pathSegments.join('/')}/';
    final path =
        '${AttachmentReference.storagePrefix}$organizationId/'
        '${kind.folder}/$scopedPath${RequestIds.uuidV4()}.$extension';
    await _storage
        .ref(path)
        .putData(
          bytes,
          SettableMetadata(contentType: isPng ? 'image/png' : 'image/jpeg'),
        );
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
