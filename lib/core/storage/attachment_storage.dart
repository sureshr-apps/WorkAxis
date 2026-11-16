/// Kinds of user-supplied images stored outside the relational database.
enum AttachmentKind {
  profilePhoto('profile-photos'),
  aadhaarDocument('aadhaar-documents'),
  returnBill('return-bills'),
  organizationLogo('logo', maxMegabytes: 2);

  const AttachmentKind(this.folder, {this.maxMegabytes = 5});

  /// Folder below `organizations/{organizationId}/`; storage rules key off it.
  final String folder;

  /// Upload limit. Mirrors the size check in `storage.rules`.
  final int maxMegabytes;

  int get maxBytes => maxMegabytes * 1024 * 1024;
}

/// Contract for storing and displaying attachments.
///
/// Presentation never talks to Cloud Storage directly: repositories call
/// [upload] before saving a record, and widgets call [resolveUrl] to display
/// what the record holds.
abstract interface class AttachmentStorage {
  /// Uploads the picked image at [localPath] and returns the stable storage
  /// reference to persist (never a local path).
  Future<String> upload({
    required String localPath,
    required String organizationId,
    required AttachmentKind kind,
  });

  /// Returns a URL that can be loaded for the persisted [reference].
  Future<String> resolveUrl(String reference);
}

/// Classifies the strings that image fields can hold.
abstract final class AttachmentReference {
  static const String storagePrefix = 'organizations/';

  /// A reference produced by [AttachmentStorage.upload].
  static bool isStored(String value) => value.startsWith(storagePrefix);

  static bool isRemoteUrl(String value) =>
      value.startsWith('https://') || value.startsWith('http://');

  /// True when [value] is a freshly picked local file that must be uploaded
  /// before the record is saved.
  static bool needsUpload(String? value) {
    if (value == null || value.isEmpty) return false;
    return !isStored(value) && !isRemoteUrl(value);
  }
}
