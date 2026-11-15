import 'package:flutter_test/flutter_test.dart';
import 'package:workaxis/core/backend/account_callables.dart';
import 'package:workaxis/core/storage/attachment_storage.dart';
import 'package:workaxis/core/storage/attachment_uploader.dart';
import 'package:workaxis/features/employees/data/sql_connect_organization_members_repository.dart';

import '../../contracts/acme_scenario.dart';
import '../../helpers/fake_identity_server.dart';

class _FakeStorage implements AttachmentStorage {
  final List<AttachmentKind> kinds = [];

  @override
  Future<String> upload({
    required String localPath,
    required String organizationId,
    required AttachmentKind kind,
  }) async {
    kinds.add(kind);
    return 'organizations/$organizationId/${kind.folder}/${kinds.length}.jpg';
  }

  @override
  Future<String> resolveUrl(String reference) async => reference;
}

void main() {
  test(
    'saveMember stores picked photos and never sends device paths',
    () async {
      final server = FakeIdentityServer(acmeMemberSeed());
      final storage = _FakeStorage();
      final repo = SqlConnectOrganizationMembersRepository(
        dataSource: FakeMembersDataSource(server),
        accounts: AccountCallables(server),
        attachments: AttachmentUploader(storage),
      );

      await repo.saveMember(
        access: orgAdminAccess(),
        member: memberDraft().copyWith(
          profilePhotoUrl: '/data/cache/profile.jpg',
          aadhaarPhotoUrl: '/data/cache/aadhaar.jpg',
        ),
        initialPassword: 'Str0ng-Pass!',
      );

      final payload = server.callsTo('provisionUser').single.payload;
      expect(
        payload['profilePhotoUrl'],
        startsWith('organizations/org-acme/profile-photos/'),
      );
      expect(
        payload['aadhaarPhotoUrl'],
        startsWith('organizations/org-acme/aadhaar-documents/'),
      );
      expect(storage.kinds, [
        AttachmentKind.profilePhoto,
        AttachmentKind.aadhaarDocument,
      ]);
    },
  );
}
