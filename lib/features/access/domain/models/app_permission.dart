import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Capabilities a signed-in user may hold. Granted by role through
/// [AppPermissionSet.forRole] so mock and production resolve identically.
enum AppPermission {
  platformManage,
  platformOwner,
  organizationManage,
  branchManage,
  branchView,
  attendanceManage,
  attendanceReview,
  attendanceRecord,
  attendanceSelf,
  returnsManage,
  returnsSubmit,
}

/// Role to permission mapping.
class AppPermissionSet {
  AppPermissionSet._();

  static Set<AppPermission> forRole(UserRole role) {
    switch (role) {
      case UserRole.platformOwner:
        return const {
          AppPermission.platformManage,
          AppPermission.platformOwner,
        };
      case UserRole.platformAdmin:
        return const {AppPermission.platformManage};
      case UserRole.orgAdmin:
        return const {
          AppPermission.organizationManage,
          AppPermission.branchManage,
          AppPermission.branchView,
          AppPermission.attendanceManage,
          AppPermission.attendanceReview,
          AppPermission.returnsManage,
        };
      case UserRole.branchManager:
        return const {
          AppPermission.branchManage,
          AppPermission.branchView,
          AppPermission.attendanceRecord,
          AppPermission.attendanceReview,
          AppPermission.returnsManage,
        };
      case UserRole.employee:
        return const {
          AppPermission.attendanceSelf,
          AppPermission.returnsSubmit,
        };
    }
  }
}
