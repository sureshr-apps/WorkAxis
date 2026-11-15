import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/storage/attachment_uploader.dart';

class _CountingStorage implements AttachmentStorage {
  final List<String> uploads = [];

  @override
  Future<String> upload({
    required String localPath,
    required String organizationId,
    required AttachmentKind kind,
  }) async {
    uploads.add(localPath);
    return 'organizations/$organizationId/${kind.folder}/${uploads.length}.jpg';
  }

  @override
  Future<String> resolveUrl(String reference) async => 'https://cdn/$reference';
}

void main() {
  group('AttachmentReference', () {
    test('only fresh local paths need uploading', () {
      expect(AttachmentReference.needsUpload(null), isFalse);
      expect(AttachmentReference.needsUpload(''), isFalse);
      expect(
        AttachmentReference.needsUpload('organizations/o1/return-bills/a.jpg'),
        isFalse,
      );
      expect(AttachmentReference.needsUpload('https://x/y.jpg'), isFalse);
      expect(
        AttachmentReference.needsUpload('/data/user/0/cache/p.jpg'),
        isTrue,
      );
      expect(
        AttachmentReference.needsUpload('blob:http://localhost/1'),
        isTrue,
      );
    });
  });

  group('AttachmentUploader', () {
    late _CountingStorage storage;
    late AttachmentUploader uploader;

    setUp(() {
      storage = _CountingStorage();
      uploader = AttachmentUploader(storage);
    });

    test('uploads a local path and returns the stored reference', () async {
      final ref = await uploader.ensureStored(
        '/tmp/bill.jpg',
        organizationId: 'org-1',
        kind: AttachmentKind.returnBill,
      );
      expect(ref, 'organizations/org-1/return-bills/1.jpg');
      expect(storage.uploads, ['/tmp/bill.jpg']);
    });

    test('passes through empty values, stored references and URLs', () async {
      for (final value in [
        null,
        '',
        'organizations/org-1/profile-photos/a.jpg',
        'https://x/y.jpg',
      ]) {
        expect(
          await uploader.ensureStored(
            value,
            organizationId: 'org-1',
            kind: AttachmentKind.profilePhoto,
          ),
          value,
        );
      }
      expect(storage.uploads, isEmpty);
    });

    test('a retried save reuses the earlier upload', () async {
      Future<String?> save() => uploader.ensureStored(
        '/tmp/aadhaar.jpg',
        organizationId: 'org-1',
        kind: AttachmentKind.aadhaarDocument,
      );
      final first = await save();
      final second = await save();
      expect(second, first);
      expect(storage.uploads, hasLength(1));
    });
  });
}
