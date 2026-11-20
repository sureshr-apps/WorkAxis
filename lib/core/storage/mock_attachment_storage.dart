import 'package:workaxis/core/storage/attachment_storage.dart';

/// Mock-mode storage: nothing leaves the device, so the picked local path is
/// its own reference.
class MockAttachmentStorage implements ScopedAttachmentStorage {
  const MockAttachmentStorage();

  @override
  Future<String> upload({
    required String localPath,
    required String organizationId,
    required AttachmentKind kind,
  }) async => localPath;

  @override
  Future<String> uploadScoped({
    required String localPath,
    required String organizationId,
    required AttachmentKind kind,
    required List<String> pathSegments,
  }) async => localPath;

  @override
  Future<String> resolveUrl(String reference) async => reference;
}
