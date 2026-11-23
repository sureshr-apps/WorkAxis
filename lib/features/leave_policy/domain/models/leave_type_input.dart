/// Values submitted to create a leave type ([id] null) or update one.
///
/// For the unpaid type only [name] may change; send [yearlyDays] 0 and
/// [carryForward] false.
class LeaveTypeInput {
  const LeaveTypeInput({
    this.id,
    required this.name,
    required this.yearlyDays,
    required this.carryForward,
  });

  final String? id;
  final String name;
  final double yearlyDays;
  final bool carryForward;

  bool get isNew => id == null;
}
