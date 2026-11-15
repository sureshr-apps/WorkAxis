import 'package:workaxis/features/authentication/domain/models/user_role.dart';

/// Raw, unparsed values of the account editor form, as typed by the user.
///
/// The policy validates this (not a typed member) so it can report errors for
/// text that does not parse, such as a salary of "abc".
class MemberFormValues {
  const MemberFormValues({
    required this.role,
    this.fullName = '',
    this.username = '',
    this.password = '',
    this.phone = '',
    this.email = '',
    this.aadhaarNumber = '',
    this.aadhaarPhotoPath,
    this.designation = '',
    this.salaryText = '',
    this.workHoursText = '',
    this.shiftHours = '',
    this.branchIds = const {},
  });

  final UserRole role;
  final String fullName;
  final String username;
  final String password;
  final String phone;
  final String email;
  final String aadhaarNumber;
  final String? aadhaarPhotoPath;
  final String designation;
  final String salaryText;
  final String workHoursText;
  final String shiftHours;
  final Set<String> branchIds;
}
