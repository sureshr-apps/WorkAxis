import 'package:flutter/foundation.dart';
import 'package:workaxis/features/access/domain/models/active_branch_context.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';

/// Application-level controller managing the currently selected active branch context.
///
/// Prevents downstream features from inventing their own branch-selection state.
class BranchContextController extends ChangeNotifier {
  ActiveBranchContext? _activeBranch;
  List<BranchSummary> _assignedBranches = const [];

  ActiveBranchContext? get activeBranch => _activeBranch;
  bool get hasActiveBranch => _activeBranch != null;
  List<BranchSummary> get assignedBranches => _assignedBranches;

  /// Initializes branch context from the resolved access context.
  void initFromAccessContext(UserAccessContext context) {
    _assignedBranches = context.assignedBranches;
    _activeBranch = context.activeBranch;
    notifyListeners();
  }

  /// Sets the active branch for branch-scoped operations.
  ///
  /// Throws [ArgumentError] if the branch is not active or not in the user's assigned set.
  bool selectBranch(BranchSummary branch) {
    if (!branch.isActive) {
      return false;
    }
    final isAssigned = _assignedBranches.any((b) => b.id == branch.id);
    if (!isAssigned) {
      return false;
    }

    _activeBranch = ActiveBranchContext.fromBranch(branch);
    notifyListeners();
    return true;
  }

  /// Clears active branch context (upon branch switch or sign out).
  void clear() {
    _activeBranch = null;
    _assignedBranches = const [];
    notifyListeners();
  }
}
