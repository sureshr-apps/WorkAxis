import 'package:workaxis/core/errors/validation_exception.dart';
import 'package:workaxis/features/access/domain/models/branch_summary.dart';
import 'package:workaxis/features/branches/domain/models/branch_record.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

import 'fake_branches_data_source.dart';
import 'fake_identity_server.dart';

/// Applies a trusted SQL transaction's observable contract in memory.
Future<Map<String, dynamic>> fakeBranchSave(
  FakeBranchesDataSource branches,
  FakeIdentityServer identities,
  Map<String, dynamic> p,
) async {
  const orgId = 'org-acme';
  final id = p['id'] as String?;
  final current = id == null ? null : await branches.getById(id);
  final wanted = List<String>.from(p['managerIds'] as List);
  final managers = identities.all
      .where((m) => m.role == UserRole.branchManager)
      .toList();
  final changes = <String, List<String>>{};
  for (final selected in wanted) {
    final manager = identities.byId(selected);
    if (manager == null ||
        manager.role != UserRole.branchManager ||
        manager.organizationId != orgId) {
      throw ValidationException('Manager is outside the organization.');
    }
  }
  for (final manager in managers) {
    final had = id != null && manager.branchIds.contains(id);
    if (!had || wanted.contains(manager.id)) continue;
    final remaining = manager.branchIds.where((b) => b != id).toList();
    if (remaining.isEmpty) {
      throw ValidationException('A manager must keep at least one branch.');
    }
    changes[manager.id] = remaining;
  }
  final code = (p['code'] as String).isEmpty ? 'BR-NEW' : p['code'] as String;
  final draft = BranchRecord(
    summary: BranchSummary(
      id: id ?? '',
      organizationId: orgId,
      name: p['name'] as String,
      code: code,
      location: p['location'] as String,
      isActive: p['status'] == 'active',
    ),
    geofenceRadiusMeters: p['geofenceRadiusMeters'] as int,
    latitude: p['latitude'] as double?,
    longitude: p['longitude'] as double?,
    isMainBranch: p['isMainBranch'] as bool,
    managerIds: wanted,
    kioskStatus: current?.kioskStatus ?? KioskPairingStatus.notPaired,
  );
  final savedId = id ?? await branches.add(draft, organizationId: orgId);
  if (id != null) await branches.update(draft);
  for (final selected in wanted) {
    changes[selected] = {
      ...identities.byId(selected)!.branchIds,
      savedId,
    }.toList();
  }
  identities.applyBranchAssignments(changes);
  return {'id': savedId, 'code': code};
}
