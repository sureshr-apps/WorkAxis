/// One of the organization's active leave types, as offered to applicants.
///
/// Organizations define their own types (with yearly allowances managed by
/// the leave policy). Days of a [paid] type are paid while they fit the
/// remaining allowance; a type that is not [paid] is always unpaid.
class LeaveTypeOption {
  const LeaveTypeOption({
    required this.id,
    required this.name,
    required this.paid,
  });

  final String id;
  final String name;
  final bool paid;

  @override
  bool operator ==(Object other) =>
      other is LeaveTypeOption &&
      other.id == id &&
      other.name == name &&
      other.paid == paid;

  @override
  int get hashCode => Object.hash(id, name, paid);

  @override
  String toString() => 'LeaveTypeOption($id, $name, paid: $paid)';
}
