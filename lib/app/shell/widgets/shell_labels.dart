import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Console badge text shown next to the product name for each role area.
String consoleBadgeTextFor(UserRole? role) {
  switch (role) {
    case UserRole.platformOwner:
    case UserRole.platformAdmin:
      return 'PLATFORM CONSOLE';
    case UserRole.orgAdmin:
      return 'ORGANIZATION CONSOLE';
    case UserRole.branchManager:
      return 'BRANCH OPERATIONS';
    case UserRole.employee:
      return 'EMPLOYEE PORTAL';
    case null:
      return 'OPERATIONS CONSOLE';
  }
}
