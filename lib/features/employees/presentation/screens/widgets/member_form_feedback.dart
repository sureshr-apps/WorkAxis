import 'package:flutter/widgets.dart';
import 'package:workaxis/features/employees/domain/models/member_field.dart';

/// What the editor tells its form sections about each field: whether it is
/// mandatory (drives the `*` marker), its inline error, and a scroll anchor.
///
/// The required set comes from `OrganizationMemberPolicy.requiredFields`, the
/// same set `validateForSave` enforces, so labels cannot drift from the rules.
class MemberFormFeedback {
  const MemberFormFeedback({
    this.required = const {},
    this.errors = const {},
    this.anchors = const {},
  });

  /// No markers, no errors: for sections used outside the editor.
  static const none = MemberFormFeedback();

  final Set<MemberField> required;
  final Map<MemberField, String> errors;
  final Map<MemberField, GlobalKey> anchors;

  String? errorFor(MemberField field) => errors[field];

  /// [text] with a trailing `*` when [field] is mandatory.
  String label(String text, MemberField field) =>
      required.contains(field) ? '$text *' : text;

  /// Wraps [child] so the editor can scroll to it when it is invalid.
  Widget anchor(MemberField field, Widget child) {
    final key = anchors[field];
    return key == null ? child : KeyedSubtree(key: key, child: child);
  }
}
