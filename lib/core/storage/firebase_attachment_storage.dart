import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/core/ids/request_ids.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';

/// Cloud Storage implementation of [AttachmentStorage].
///
/// Objects live at `organizations/{organizationId}/{kind folder}/{uuid}.{ext}`.
/// Only that path is persisted; `storage.rules` decide who may read it, and a
/// short-lived download URL is requested at display time.
class FirebaseAttachmentStorage implements AttachmentStorage {
  FirebaseAttachmentStorage({required this.bucket, FirebaseStorage? storage})
    : _injected = storage;

  /// Bucket name without the `gs://` prefix.
  final String bucket;

  /// Mirrors the limit in `storage.rules`.
  static const int maxBytes = 5 * 1024 * 1024;

  final FirebaseStorage? _injected;

  // Resolved lazily so mocks and tests never touch the Firebase singleton.
  FirebaseStorage get _storage =>
      _injected ?? FirebaseStorage.instanceFor(bucket: 'gs://$bucket');

  @override
  Future<String> upload({
    required String localPath,
    required String organizationId,
    required AttachmentKind kind,
  }) async {
    // XFile reads both file paths (Android) and blob URLs (web).
    final file = XFile(localPath);
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw ValidationException(
        'The photo is too large. Choose one under 5 MB.',
      );
    }
    final isPng =
        (file.mimeType ?? '').toLowerCase() == 'image/png' ||
        localPath.toLowerCase().endsWith('.png');
    final extension = isPng ? 'png' : 'jpg';
    final path =
        '${AttachmentReference.storagePrefix}$organizationId/${kind.folder}/'
        '${RequestIds.uuidV4()}.$extension';
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
