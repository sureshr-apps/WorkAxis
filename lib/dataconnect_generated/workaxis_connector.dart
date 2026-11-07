library dataconnect_generated;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';

import 'dart:convert';

part 'create_organization.dart';

part 'update_organization.dart';

part 'create_commercial_agreement.dart';

part 'update_commercial_agreement.dart';

part 'create_license_event.dart';

part 'create_branch.dart';

part 'add_branch.dart';

part 'update_branch.dart';

part 'create_organization_member.dart';

part 'create_return_record.dart';

part 'submit_return.dart';

part 'update_return_record_review.dart';

part 'update_return_record_status.dart';

part 'list_organizations.dart';

part 'list_organizations_paged.dart';

part 'get_organization_by_id.dart';

part 'get_organization_stats.dart';

part 'get_platform_stats.dart';

part 'list_branches_by_org.dart';

part 'get_branch_by_id.dart';

part 'list_my_branch_assignments.dart';

part 'get_my_member.dart';

part 'list_members_by_org.dart';

part 'list_members_by_org_paged.dart';

part 'list_members_by_branch_paged.dart';

part 'get_member_by_id.dart';

part 'list_returns_by_branch.dart';

part 'list_returns_by_branch_paged.dart';

part 'list_returns_by_org_paged.dart';

part 'list_my_returns.dart';

part 'get_organization_dashboard_counts.dart';

part 'get_return_counts_by_branch.dart';

part 'get_branch_stats.dart';

part 'get_commercial_agreement_by_org.dart';

part 'list_license_events_by_org.dart';

part 'list_platform_members_paged.dart';

class WorkaxisConnectorConnector {
  CreateOrganizationVariablesBuilder createOrganization({
    required String name,
    required String code,
  }) {
    return CreateOrganizationVariablesBuilder(
      dataConnect,
      name: name,
      code: code,
    );
  }

  UpdateOrganizationVariablesBuilder updateOrganization({required String id}) {
    return UpdateOrganizationVariablesBuilder(dataConnect, id: id);
  }

  CreateCommercialAgreementVariablesBuilder createCommercialAgreement({
    required String orgId,
    required String agreementReference,
    required String planName,
    required String planTier,
    required double negotiatedPrice,
    required double annualMaintenancePrice,
    required int maxStores,
    required int maxUsers,
    required DateTime startDate,
    required DateTime expiryDate,
  }) {
    return CreateCommercialAgreementVariablesBuilder(
      dataConnect,
      orgId: orgId,
      agreementReference: agreementReference,
      planName: planName,
      planTier: planTier,
      negotiatedPrice: negotiatedPrice,
      annualMaintenancePrice: annualMaintenancePrice,
      maxStores: maxStores,
      maxUsers: maxUsers,
      startDate: startDate,
      expiryDate: expiryDate,
    );
  }

  UpdateCommercialAgreementVariablesBuilder updateCommercialAgreement({
    required String id,
  }) {
    return UpdateCommercialAgreementVariablesBuilder(dataConnect, id: id);
  }

  CreateLicenseEventVariablesBuilder createLicenseEvent({
    required String orgId,
    required String eventType,
    required String planName,
    required String planTier,
    required String validityPeriod,
    required int storesCount,
    required int usersCount,
    required double oneTimePrice,
    required double annualMaintenancePrice,
  }) {
    return CreateLicenseEventVariablesBuilder(
      dataConnect,
      orgId: orgId,
      eventType: eventType,
      planName: planName,
      planTier: planTier,
      validityPeriod: validityPeriod,
      storesCount: storesCount,
      usersCount: usersCount,
      oneTimePrice: oneTimePrice,
      annualMaintenancePrice: annualMaintenancePrice,
    );
  }

  CreateBranchVariablesBuilder createBranch({
    required String id,
    required String orgId,
    required String name,
    required String code,
  }) {
    return CreateBranchVariablesBuilder(
      dataConnect,
      id: id,
      orgId: orgId,
      name: name,
      code: code,
    );
  }

  AddBranchVariablesBuilder addBranch({
    required String orgId,
    required String name,
    required String code,
  }) {
    return AddBranchVariablesBuilder(
      dataConnect,
      orgId: orgId,
      name: name,
      code: code,
    );
  }

  UpdateBranchVariablesBuilder updateBranch({required String id}) {
    return UpdateBranchVariablesBuilder(dataConnect, id: id);
  }

  CreateOrganizationMemberVariablesBuilder createOrganizationMember({
    required String id,
    required String orgId,
    required String fullName,
    required String username,
    required String email,
    required String role,
  }) {
    return CreateOrganizationMemberVariablesBuilder(
      dataConnect,
      id: id,
      orgId: orgId,
      fullName: fullName,
      username: username,
      email: email,
      role: role,
    );
  }

  CreateReturnRecordVariablesBuilder createReturnRecord({
    required String id,
    required String orgId,
    required String branchId,
    required String employeeId,
    required String employeeName,
    required String customerName,
    required String invoiceNumber,
    required String returnReason,
    required double amount,
  }) {
    return CreateReturnRecordVariablesBuilder(
      dataConnect,
      id: id,
      orgId: orgId,
      branchId: branchId,
      employeeId: employeeId,
      employeeName: employeeName,
      customerName: customerName,
      invoiceNumber: invoiceNumber,
      returnReason: returnReason,
      amount: amount,
    );
  }

  SubmitReturnVariablesBuilder submitReturn({
    required String branchId,
    required String productTitle,
    required String returnReason,
    required double quantity,
    required String unit,
    required String invoiceNumber,
  }) {
    return SubmitReturnVariablesBuilder(
      dataConnect,
      branchId: branchId,
      productTitle: productTitle,
      returnReason: returnReason,
      quantity: quantity,
      unit: unit,
      invoiceNumber: invoiceNumber,
    );
  }

  UpdateReturnRecordReviewVariablesBuilder updateReturnRecordReview({
    required String id,
    required String status,
  }) {
    return UpdateReturnRecordReviewVariablesBuilder(
      dataConnect,
      id: id,
      status: status,
    );
  }

  UpdateReturnRecordStatusVariablesBuilder updateReturnRecordStatus({
    required String id,
    required String status,
  }) {
    return UpdateReturnRecordStatusVariablesBuilder(
      dataConnect,
      id: id,
      status: status,
    );
  }

  ListOrganizationsVariablesBuilder listOrganizations() {
    return ListOrganizationsVariablesBuilder(dataConnect);
  }

  ListOrganizationsPagedVariablesBuilder listOrganizationsPaged({
    required int limit,
    required int offset,
  }) {
    return ListOrganizationsPagedVariablesBuilder(
      dataConnect,
      limit: limit,
      offset: offset,
    );
  }

  GetOrganizationByIdVariablesBuilder getOrganizationById({
    required String id,
  }) {
    return GetOrganizationByIdVariablesBuilder(dataConnect, id: id);
  }

  GetOrganizationStatsVariablesBuilder getOrganizationStats({
    required String orgId,
  }) {
    return GetOrganizationStatsVariablesBuilder(dataConnect, orgId: orgId);
  }

  GetPlatformStatsVariablesBuilder getPlatformStats() {
    return GetPlatformStatsVariablesBuilder(dataConnect);
  }

  ListBranchesByOrgVariablesBuilder listBranchesByOrg({required String orgId}) {
    return ListBranchesByOrgVariablesBuilder(dataConnect, orgId: orgId);
  }

  GetBranchByIdVariablesBuilder getBranchById({required String id}) {
    return GetBranchByIdVariablesBuilder(dataConnect, id: id);
  }

  ListMyBranchAssignmentsVariablesBuilder listMyBranchAssignments() {
    return ListMyBranchAssignmentsVariablesBuilder(dataConnect);
  }

  GetMyMemberVariablesBuilder getMyMember() {
    return GetMyMemberVariablesBuilder(dataConnect);
  }

  ListMembersByOrgVariablesBuilder listMembersByOrg({required String orgId}) {
    return ListMembersByOrgVariablesBuilder(dataConnect, orgId: orgId);
  }

  ListMembersByOrgPagedVariablesBuilder listMembersByOrgPaged({
    required String orgId,
    required int limit,
    required int offset,
  }) {
    return ListMembersByOrgPagedVariablesBuilder(
      dataConnect,
      orgId: orgId,
      limit: limit,
      offset: offset,
    );
  }

  ListMembersByBranchPagedVariablesBuilder listMembersByBranchPaged({
    required String branchId,
    required int limit,
    required int offset,
  }) {
    return ListMembersByBranchPagedVariablesBuilder(
      dataConnect,
      branchId: branchId,
      limit: limit,
      offset: offset,
    );
  }

  GetMemberByIdVariablesBuilder getMemberById({required String id}) {
    return GetMemberByIdVariablesBuilder(dataConnect, id: id);
  }

  ListReturnsByBranchVariablesBuilder listReturnsByBranch({
    required String branchId,
  }) {
    return ListReturnsByBranchVariablesBuilder(dataConnect, branchId: branchId);
  }

  ListReturnsByBranchPagedVariablesBuilder listReturnsByBranchPaged({
    required String branchId,
    required int limit,
    required int offset,
  }) {
    return ListReturnsByBranchPagedVariablesBuilder(
      dataConnect,
      branchId: branchId,
      limit: limit,
      offset: offset,
    );
  }

  ListReturnsByOrgPagedVariablesBuilder listReturnsByOrgPaged({
    required String orgId,
    required int limit,
    required int offset,
  }) {
    return ListReturnsByOrgPagedVariablesBuilder(
      dataConnect,
      orgId: orgId,
      limit: limit,
      offset: offset,
    );
  }

  ListMyReturnsVariablesBuilder listMyReturns({
    required int limit,
    required int offset,
  }) {
    return ListMyReturnsVariablesBuilder(
      dataConnect,
      limit: limit,
      offset: offset,
    );
  }

  GetOrganizationDashboardCountsVariablesBuilder
  getOrganizationDashboardCounts({required String orgId}) {
    return GetOrganizationDashboardCountsVariablesBuilder(
      dataConnect,
      orgId: orgId,
    );
  }

  GetReturnCountsByBranchVariablesBuilder getReturnCountsByBranch({
    required String orgId,
  }) {
    return GetReturnCountsByBranchVariablesBuilder(dataConnect, orgId: orgId);
  }

  GetBranchStatsVariablesBuilder getBranchStats({required String branchId}) {
    return GetBranchStatsVariablesBuilder(dataConnect, branchId: branchId);
  }

  GetCommercialAgreementByOrgVariablesBuilder getCommercialAgreementByOrg({
    required String orgId,
  }) {
    return GetCommercialAgreementByOrgVariablesBuilder(
      dataConnect,
      orgId: orgId,
    );
  }

  ListLicenseEventsByOrgVariablesBuilder listLicenseEventsByOrg({
    required String orgId,
  }) {
    return ListLicenseEventsByOrgVariablesBuilder(dataConnect, orgId: orgId);
  }

  ListPlatformMembersPagedVariablesBuilder listPlatformMembersPaged({
    required int limit,
    required int offset,
  }) {
    return ListPlatformMembersPagedVariablesBuilder(
      dataConnect,
      limit: limit,
      offset: offset,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-south1',
    'workaxis-connector',
    'workaxis-service',
  );

  WorkaxisConnectorConnector({required this.dataConnect});
  static WorkaxisConnectorConnector get instance {
    return WorkaxisConnectorConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
