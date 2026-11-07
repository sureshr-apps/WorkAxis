import 'package:workaxis/core/pagination/page_result.dart';
import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/platform_users/domain/models/platform_administrator.dart';

/// Remote platform-administrator reads. Thin seam over SQL Connect so the
/// repository can be unit-tested with a fake.
abstract interface class PlatformUsersRemoteDataSource {
  Future<PageResult<PlatformAdministrator>> listPage({
    required int limit,
    required int offset,
    String? nameContains,
    AccountStatus? status,
  });

  Future<int> count({AccountStatus? status});

  /// Null when the member does not exist or is not a platform administrator.
  Future<PlatformAdministrator?> getById(String id);
}
