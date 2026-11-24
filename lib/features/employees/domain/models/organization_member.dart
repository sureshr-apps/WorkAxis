import 'package:workaxis/features/authentication/domain/models/account_status.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';
import 'package:workaxis/features/employees/domain/models/member_field.dart';

class OrganizationMember {
  const OrganizationMember({
    required this.id,
    required this.organizationId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    required this.branchIds,
    this.branchNamesById = const {},
    required this.status,
    this.phone,
    this.authUid,
    this.dailyWorkHours = 8.0,
    this.shiftHours = '09:00 AM - 05:00 PM',
    this.weeklyDaysOff = const [],
    this.employeeCode,
    this.aadhaarNumber,
    this.aadhaarPhotoUrl,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.profilePhotoUrl,
    this.designation,
    this.joiningDate,
    this.relievingDate,
    this.salary,
    this.assetDetails,
  });

  /// SQL member id (assigned by the server).
  final String id;

  /// Firebase Auth uid of the account; the target of account callables.
  /// Null for seed rows that have no sign-in identity yet.
  final String? authUid;
  final String organizationId;
  final String fullName;
  final String username;
  final String email;
  final String? phone;
  final UserRole role;
  final List<String> branchIds;
  final Map<String, String> branchNamesById;
  final AccountStatus status;
  final double dailyWorkHours;
  final String? shiftHours;

  /// Recurring weekly days off (Sunday = 0). An empty list means none.
  final List<int> weeklyDaysOff;

  /// Human-readable employee code/ID (e.g. 'EMP-10001').
  final String? employeeCode;

  /// 12-digit Aadhaar number.
  final String? aadhaarNumber;

  /// Path or remote URL to Aadhaar photo/document.
  final String? aadhaarPhotoUrl;

  /// Employee's date of birth.
  final DateTime? dateOfBirth;

  /// Gender ('Male', 'Female', 'Other').
  final String? gender;

  /// Residential address.
  final String? address;

  /// Path or URL to profile photo.
  final String? profilePhotoUrl;

  /// Role / designation (e.g. 'Store Associate', 'Branch Supervisor').
  final String? designation;

  /// Date when the employee joined.
  final DateTime? joiningDate;

  /// Optional date when the employee was/will be relieved.
  final DateTime? relievingDate;

  /// Monthly salary/CTC.
  final double? salary;

  /// Legacy free-text data preserved for compatibility. Structured asset
  /// assignments are stored by the Assets feature.
  final String? assetDetails;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    return parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  /// Copies with overrides. A null argument keeps the current value; list a
  /// field in [clear] to set it to null instead.
  OrganizationMember copyWith({
    String? id,
    String? authUid,
    String? fullName,
    String? username,
    String? email,
    String? phone,
    bool clearPhone = false,
    UserRole? role,
    List<String>? branchIds,
    Map<String, String>? branchNamesById,
    AccountStatus? status,
    double? dailyWorkHours,
    String? shiftHours,
    List<int>? weeklyDaysOff,
    String? employeeCode,
    String? aadhaarNumber,
    String? aadhaarPhotoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? profilePhotoUrl,
    String? designation,
    DateTime? joiningDate,
    DateTime? relievingDate,
    bool clearRelievingDate = false,
    double? salary,
    String? assetDetails,
    Set<MemberField> clear = const {},
  }) => OrganizationMember(
    id: id ?? this.id,
    authUid: authUid ?? this.authUid,
    organizationId: organizationId,
    fullName: fullName ?? this.fullName,
    username: username ?? this.username,
    email: email ?? this.email,
    phone: clearPhone ? null : phone ?? this.phone,
    role: role ?? this.role,
    branchIds: branchIds ?? this.branchIds,
    branchNamesById: branchNamesById ?? this.branchNamesById,
    status: status ?? this.status,
    dailyWorkHours: dailyWorkHours ?? this.dailyWorkHours,
    shiftHours: shiftHours ?? this.shiftHours,
    weeklyDaysOff: weeklyDaysOff ?? this.weeklyDaysOff,
    employeeCode: clear.contains(MemberField.employeeCode)
        ? null
        : employeeCode ?? this.employeeCode,
    aadhaarNumber: clear.contains(MemberField.aadhaarNumber)
        ? null
        : aadhaarNumber ?? this.aadhaarNumber,
    aadhaarPhotoUrl: clear.contains(MemberField.aadhaarPhoto)
        ? null
        : aadhaarPhotoUrl ?? this.aadhaarPhotoUrl,
    dateOfBirth: clear.contains(MemberField.dateOfBirth)
        ? null
        : dateOfBirth ?? this.dateOfBirth,
    gender: clear.contains(MemberField.gender) ? null : gender ?? this.gender,
    address: clear.contains(MemberField.address)
        ? null
        : address ?? this.address,
    profilePhotoUrl: clear.contains(MemberField.profilePhoto)
        ? null
        : profilePhotoUrl ?? this.profilePhotoUrl,
    designation: clear.contains(MemberField.designation)
        ? null
        : designation ?? this.designation,
    joiningDate: clear.contains(MemberField.joiningDate)
        ? null
        : joiningDate ?? this.joiningDate,
    relievingDate:
        clearRelievingDate || clear.contains(MemberField.relievingDate)
        ? null
        : relievingDate ?? this.relievingDate,
    salary: clear.contains(MemberField.salary) ? null : salary ?? this.salary,
    assetDetails: clear.contains(MemberField.assetDetails)
        ? null
        : assetDetails ?? this.assetDetails,
  );
}
