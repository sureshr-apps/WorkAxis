import 'package:workaxis/core/storage/attachment_storage.dart';

/// Uploads freshly picked images exactly once.
///
/// A save can fail after the upload (for example the account callable is
/// rejected). The user retries the same draft, so the uploaded reference is
/// remembered per local path instead of storing a duplicate file each time.
class AttachmentUploader {
  AttachmentUploader(this._storage);

  final AttachmentStorage _storage;
  final Map<String, String> _uploaded = {};

  /// Returns [value] unchanged when it is empty or already a stored reference
  /// or URL; otherwise uploads the local file and returns its reference.
  Future<String?> ensureStored(
    String? value, {
    required String organizationId,
    required AttachmentKind kind,
  }) async {
    if (!AttachmentReference.needsUpload(value)) return value;
    final local = value!;
    final cached = _uploaded[local];
    if (cached != null) return cached;
    final reference = await _storage.upload(
      localPath: local,
      organizationId: organizationId,
      kind: kind,
    );
    _uploaded[local] = reference;
    return reference;
  }
}
