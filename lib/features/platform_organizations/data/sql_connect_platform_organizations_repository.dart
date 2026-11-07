import 'dart:math';
import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/dataconnect_generated/workaxis_connector.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/repositories/platform_organizations_repository.dart';

/// Production implementation of [PlatformOrganizationsRepository] using Firebase SQL Connect
/// (Cloud SQL for PostgreSQL).
class SqlConnectPlatformOrganizationsRepository
    implements PlatformOrganizationsRepository {
  SqlConnectPlatformOrganizationsRepository({
    WorkaxisConnectorConnector? connector,
  }) : _customConnector = connector;

  final WorkaxisConnectorConnector? _customConnector;
  WorkaxisConnectorConnector get _connector =>
      _customConnector ?? WorkaxisConnectorConnector.instance;

  @override
  Future<List<CustomerOrganization>> getOrganizations({
    String? query,
    OrganizationStatus? statusFilter,
  }) async {
    try {
      final response = await _connector.listOrganizations().execute();
      final orgs = response.data.organizations;

      var results = orgs.map(_mapListOrgToCustomerOrg).toList();

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        results = results
            .where((o) =>
                o.name.toLowerCase().contains(q) ||
                o.code.toLowerCase().contains(q))
            .toList();
      }

      if (statusFilter != null) {
        results = results.where((o) => o.status == statusFilter).toList();
      }

      return results;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to retrieve organizations: ${e.toString()}');
    }
  }

  @override
  Future<CustomerOrganization?> getOrganizationById(String id) async {
    try {
      final response = await _connector.getOrganizationById(id: id).execute();
      final org = response.data.organization;
      if (org == null) return null;

      // Query branch and member counts concurrently
      final branchesFuture = _connector.listBranchesByOrg(orgId: id).execute();
      final membersFuture = _connector.listMembersByOrg(orgId: id).execute();
      final results = await Future.wait([branchesFuture, membersFuture]);

      final branchCount = (results[0] as ListBranchesByOrgData).branches.length;
      final memberCount = (results[1] as ListMembersByOrgData).organizationMembers.length;

      return CustomerOrganization(
        id: org.id,
        name: org.name,
        code: org.code,
        status: _parseStatus(org.status),
        branchCount: branchCount,
        employeeCount: memberCount,
        createdAt: org.createdAt.toDateTime(),
        description: org.category != null ? 'Category: ${org.category}' : null,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to fetch organization "$id": ${e.toString()}');
    }
  }

  @override
  Future<OrganizationLicenseDetails?> getOrganizationLicenseDetails(
    String organizationId,
  ) async {
    try {
      final agreementResponse =
          await _connector.getCommercialAgreementByOrg(orgId: organizationId).execute();
      final agreements = agreementResponse.data.commercialAgreements;
      if (agreements.isEmpty) return null;

      final agreement = agreements.first;
      final historyResponse =
          await _connector.listLicenseEventsByOrg(orgId: organizationId).execute();

      final historyEntries = historyResponse.data.licenseEvents.map((evt) {
        return LicenseHistoryEntry(
          event: evt.eventType,
          occurredAt: evt.createdAt.toDateTime(),
          planName: evt.planName,
          level: 1,
          periodStart: DateTime.now(),
          periodEnd: DateTime.now().add(const Duration(days: 365)),
          stores: evt.storesCount,
          users: evt.usersCount,
          negotiatedPrice: evt.oneTimePrice,
          annualMaintenancePrice: evt.annualMaintenancePrice,
        );
      }).toList();

      return OrganizationLicenseDetails(
        planName: agreement.planName,
        status: agreement.status,
        level: 1,
        agreementId: agreement.agreementReference,
        agreementStart: DateTime.parse(agreement.startDate.toString()),
        agreementExpiry: DateTime.parse(agreement.expiryDate.toString()),
        maximumStores: agreement.maxStores,
        maximumUsers: agreement.maxUsers,
        negotiatedPrice: agreement.negotiatedPrice,
        annualMaintenancePrice: agreement.annualMaintenancePrice,
        currencyCode: 'INR',
        history: historyEntries,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to fetch license details: ${e.toString()}');
    }
  }

  @override
  Future<CustomerOrganization> createOrganization(
    CreateOrganizationRequest request,
  ) async {
    try {
      final code = _generateOrgCode(request.name);
      final id = 'org-${code.toLowerCase()}';

      await _connector
          .createOrganization(id: id, name: request.name, code: code)
          .category(request.description)
          .country('India')
          .status(OrganizationStatus.active.name)
          .currency('INR')
          .execute();

      return CustomerOrganization(
        id: id,
        name: request.name,
        code: code,
        status: OrganizationStatus.active,
        branchCount: 0,
        employeeCount: 0,
        createdAt: DateTime.now(),
        description: request.description,
        contactName: request.contactName,
        contactEmail: request.contactEmail,
        contactPhone: request.contactPhone,
        address: request.address,
        taxIdentification: request.taxIdentification,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to create organization: ${e.toString()}');
    }
  }

  @override
  Future<CustomerOrganization> updateOrganization(
    CustomerOrganization organization,
  ) async {
    try {
      await _connector
          .updateOrganization(id: organization.id)
          .name(organization.name)
          .status(organization.status.name)
          .category(organization.description)
          .execute();

      return organization;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to update organization: ${e.toString()}');
    }
  }

  @override
  Future<CustomerOrganization> updateOrganizationStatus(
    String id,
    OrganizationStatus newStatus,
  ) async {
    try {
      await _connector
          .updateOrganization(id: id)
          .status(newStatus.name)
          .execute();

      final existing = await getOrganizationById(id);
      if (existing == null) {
        throw NotFoundException('Organization with ID "$id" not found.');
      }
      return existing.copyWith(status: newStatus);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to update organization status: ${e.toString()}');
    }
  }

  CustomerOrganization _mapListOrgToCustomerOrg(
    ListOrganizationsOrganizations org,
  ) {
    return CustomerOrganization(
      id: org.id,
      name: org.name,
      code: org.code,
      status: _parseStatus(org.status),
      branchCount: 0,
      employeeCount: 0,
      createdAt: org.createdAt.toDateTime(),
      description: org.category,
    );
  }

  OrganizationStatus _parseStatus(String statusStr) {
    return OrganizationStatus.fromString(statusStr);
  }

  String _generateOrgCode(String orgName) {
    final letters = orgName
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .toUpperCase();
    final prefix = letters.length >= 3 ? letters.substring(0, 3) : 'ORG';
    final randomSuffix = Random().nextInt(900) + 100;
    return '$prefix-$randomSuffix';
  }
}
