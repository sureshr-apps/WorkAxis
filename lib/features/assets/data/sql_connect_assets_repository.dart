import 'package:workaxis/core/backend/data_gateway.dart';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/features/access/domain/models/user_access_context.dart';
import 'package:workaxis/features/assets/domain/models/employee_asset.dart';
import 'package:workaxis/features/assets/domain/repositories/assets_repository.dart';
import 'package:workaxis/features/authentication/domain/models/user_role.dart';

class SqlConnectAssetsRepository implements AssetsRepository {
  SqlConnectAssetsRepository({required this.gateway});

  final DataGateway gateway;

  @override
  Future<List<EmployeeAsset>> getAssets({
    required UserAccessContext access,
    String? activeBranchId,
  }) async {
    final role = access.user.role;
    final operation = switch (role) {
      UserRole.employee => 'ListMyEmployeeAssets',
      UserRole.orgAdmin => 'ListOrganizationEmployeeAssets',
      UserRole.branchManager => 'ListBranchEmployeeAssets',
      _ => throw const AccessDeniedException(),
    };
    final vars = <String, dynamic>{};
    if (role == UserRole.branchManager) {
      final branchId = activeBranchId ?? access.activeBranch?.branchId;
      if (branchId == null) {
        throw const BranchAuthorizationException(
          'Active branch context required for asset access.',
        );
      }
      vars['branchId'] = branchId;
      vars['activeBranchId'] = branchId;
    }
    final data = await gateway.call(operation, vars);
    final rows = data['employeeAssets'];
    if (rows is! List) {
      throw const DatabaseException(
        'Asset listing returned an invalid payload.',
      );
    }
    return List.unmodifiable(rows.map(_fromJson));
  }

  @override
  Future<EmployeeAsset> saveAsset({
    required UserAccessContext access,
    required EmployeeAsset asset,
    String? activeBranchId,
  }) async {
    final vars = <String, dynamic>{
      'branchId': asset.branchId,
      'employeeId': asset.employeeId,
      'name': asset.name,
      'category': asset.category,
      'assetTag': asset.assetTag,
      'status': _statusValue(asset.status),
    };
    if (asset.id.isNotEmpty) vars['id'] = asset.id;
    _addOptional(vars, 'serialNumber', asset.serialNumber);
    _addOptional(vars, 'notes', asset.notes);
    if (access.user.role == UserRole.branchManager) {
      final branchId = activeBranchId ?? access.activeBranch?.branchId;
      if (branchId == null) {
        throw const BranchAuthorizationException(
          'Active branch context required for asset changes.',
        );
      }
      vars['activeBranchId'] = branchId;
    }
    final data = await gateway.call('SaveEmployeeAsset', vars);
    return _fromJson(data['employeeAsset']);
  }

  @override
  Future<EmployeeAsset> acknowledgeAsset({
    required UserAccessContext access,
    required String assetId,
  }) async {
    if (access.user.role != UserRole.employee) {
      throw const AccessDeniedException();
    }
    final data = await gateway.call('AcknowledgeMyEmployeeAsset', {
      'assetId': assetId,
    });
    return _fromJson(data['employeeAsset']);
  }

  @override
  Future<void> deleteAsset({
    required UserAccessContext access,
    required String assetId,
    String? activeBranchId,
  }) async {
    final vars = <String, dynamic>{'assetId': assetId};
    if (access.user.role == UserRole.branchManager) {
      final branchId = activeBranchId ?? access.activeBranch?.branchId;
      if (branchId == null) {
        throw const BranchAuthorizationException(
          'Active branch context required for asset changes.',
        );
      }
      vars['activeBranchId'] = branchId;
    }
    await gateway.call('DeleteEmployeeAsset', vars);
  }

  EmployeeAsset _fromJson(Object? value) {
    if (value is! Map) {
      throw const DatabaseException('Asset row is missing or malformed.');
    }
    final row = value.map((key, value) => MapEntry(key.toString(), value));
    String requiredString(String key) {
      final field = row[key];
      if (field is! String) {
        throw DatabaseException('Asset field $key is missing or malformed.');
      }
      return field;
    }

    DateTime? optionalDateTime(String key) {
      final field = row[key];
      if (field is DateTime) return field;
      if (field is String) return DateTime.tryParse(field);
      return null;
    }

    return EmployeeAsset(
      id: requiredString('id'),
      organizationId: requiredString('organizationId'),
      branchId: requiredString('branchId'),
      branchName: requiredString('branchName'),
      employeeId: requiredString('employeeId'),
      employeeName: requiredString('employeeName'),
      name: requiredString('name'),
      category: requiredString('category'),
      assetTag: requiredString('assetTag'),
      status: AssetStatus.fromValue(row['status']),
      acknowledgementRequired: row['acknowledgementRequired'] as bool? ?? false,
      acknowledgementStatus: AssetAcknowledgementStatus.fromValue(
        row['acknowledgementStatus'],
      ),
      assignedByUid: row['assignedByUid'] as String?,
      assignedByName: row['assignedByName'] as String?,
      assignedAt: optionalDateTime('assignedAt'),
      acknowledgedByUid: row['acknowledgedByUid'] as String?,
      acknowledgedByName: row['acknowledgedByName'] as String?,
      acknowledgedAt: optionalDateTime('acknowledgedAt'),
      serialNumber: row['serialNumber'] as String?,
      notes: row['notes'] as String?,
    );
  }

  String _statusValue(AssetStatus status) => switch (status) {
    AssetStatus.assigned => 'assigned',
    AssetStatus.maintenance => 'maintenance',
    AssetStatus.returned => 'returned',
  };

  void _addOptional(Map<String, dynamic> vars, String key, String? value) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) vars[key] = trimmed;
  }
}
