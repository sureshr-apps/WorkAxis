/// Editable fields of an organization account, declared in form order.
///
/// Used by the policy (required rules, field-level errors) and by the editor
/// (inline errors, scroll-to-first-invalid), so both always agree on identity
/// and order of fields.
enum MemberField {
  profilePhoto,
  employeeCode,
  fullName,
  username,
  phone,
  email,
  password,
  aadhaarNumber,
  aadhaarPhoto,
  dateOfBirth,
  gender,
  address,
  designation,
  salary,
  joiningDate,
  relievingDate,
  assetDetails,
  dailyWorkHours,
  shiftHours,
  role,
  branches,
}
