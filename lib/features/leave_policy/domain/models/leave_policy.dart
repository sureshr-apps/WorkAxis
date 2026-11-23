import 'package:workaxis/features/leave_policy/domain/models/leave_type_policy.dart';

/// An organization's leave policy as in force today.
class LeavePolicy {
  const LeavePolicy({required this.monthlyAccrual, required this.leaveTypes});

  /// When true each type's yearly allowance becomes available 1/12 per month
  /// (unused accrual carries to later months of the year); when false the
  /// whole year's allowance is available from January.
  final bool monthlyAccrual;

  /// Active leave types in display order.
  final List<LeaveTypePolicy> leaveTypes;

  LeavePolicy copyWith({
    bool? monthlyAccrual,
    List<LeaveTypePolicy>? leaveTypes,
  }) => LeavePolicy(
    monthlyAccrual: monthlyAccrual ?? this.monthlyAccrual,
    leaveTypes: leaveTypes ?? this.leaveTypes,
  );

  /// Replaces the type with [saved]'s id, or adds [saved] before the unpaid
  /// type (where the server lists newly created types).
  LeavePolicy withSavedType(LeaveTypePolicy saved) {
    final index = leaveTypes.indexWhere((type) => type.id == saved.id);
    final types = [...leaveTypes];
    if (index >= 0) {
      types[index] = saved;
    } else {
      final unpaidIndex = types.indexWhere((type) => !type.paid);
      types.insert(unpaidIndex < 0 ? types.length : unpaidIndex, saved);
    }
    return copyWith(leaveTypes: List.unmodifiable(types));
  }

  /// Drops the type with [leaveTypeId].
  LeavePolicy withoutType(String leaveTypeId) => copyWith(
    leaveTypes: List.unmodifiable(
      leaveTypes.where((type) => type.id != leaveTypeId),
    ),
  );
}
