/// One leave type of an organization with the allowance in force today.
///
/// Approved leave within the remaining [yearlyDays] is paid; days beyond it
/// are unpaid. The built-in unpaid type ([paid] false) has no allowance and
/// cannot be removed.
class LeaveTypePolicy {
  const LeaveTypePolicy({
    required this.id,
    required this.name,
    required this.paid,
    required this.yearlyDays,
    required this.carryForward,
  });

  final String id;
  final String name;

  /// False only for the built-in "Unpaid leave" type.
  final bool paid;

  /// Days per calendar year; always 0 for the unpaid type.
  final double yearlyDays;

  /// Whether unused days carry into the next year instead of lapsing on
  /// 31 December; always false for the unpaid type.
  final bool carryForward;

  /// Whether the type has a yearly allowance that can be edited.
  bool get hasAllowance => paid;

  /// Whether the type may be archived (the unpaid type may not).
  bool get canBeRemoved => paid;

  @override
  bool operator ==(Object other) =>
      other is LeaveTypePolicy &&
      other.id == id &&
      other.name == name &&
      other.paid == paid &&
      other.yearlyDays == yearlyDays &&
      other.carryForward == carryForward;

  @override
  int get hashCode => Object.hash(id, name, paid, yearlyDays, carryForward);
}
