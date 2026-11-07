library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_organization.dart';

part 'update_organization.dart';

part 'create_branch.dart';

part 'create_organization_member.dart';

part 'create_return_record.dart';

part 'update_return_record_status.dart';

part 'list_organizations.dart';

part 'get_organization_by_id.dart';

part 'list_branches_by_org.dart';

part 'list_members_by_org.dart';

part 'list_returns_by_branch.dart';

part 'get_commercial_agreement_by_org.dart';

part 'list_license_events_by_org.dart';







class WorkaxisConnectorConnector {
  
  
  CreateOrganizationVariablesBuilder createOrganization ({required String id, required String name, required String code, }) {
    return CreateOrganizationVariablesBuilder(dataConnect, id: id,name: name,code: code,);
  }
  
  
  UpdateOrganizationVariablesBuilder updateOrganization ({required String id, }) {
    return UpdateOrganizationVariablesBuilder(dataConnect, id: id,);
  }
  
  
  CreateBranchVariablesBuilder createBranch ({required String id, required String orgId, required String name, required String code, }) {
    return CreateBranchVariablesBuilder(dataConnect, id: id,orgId: orgId,name: name,code: code,);
  }
  
  
  CreateOrganizationMemberVariablesBuilder createOrganizationMember ({required String id, required String orgId, required String fullName, required String username, required String email, required String role, }) {
    return CreateOrganizationMemberVariablesBuilder(dataConnect, id: id,orgId: orgId,fullName: fullName,username: username,email: email,role: role,);
  }
  
  
  CreateReturnRecordVariablesBuilder createReturnRecord ({required String id, required String orgId, required String branchId, required String employeeId, required String employeeName, required String customerName, required String invoiceNumber, required String returnReason, required double amount, }) {
    return CreateReturnRecordVariablesBuilder(dataConnect, id: id,orgId: orgId,branchId: branchId,employeeId: employeeId,employeeName: employeeName,customerName: customerName,invoiceNumber: invoiceNumber,returnReason: returnReason,amount: amount,);
  }
  
  
  UpdateReturnRecordStatusVariablesBuilder updateReturnRecordStatus ({required String id, required String status, }) {
    return UpdateReturnRecordStatusVariablesBuilder(dataConnect, id: id,status: status,);
  }
  
  
  ListOrganizationsVariablesBuilder listOrganizations () {
    return ListOrganizationsVariablesBuilder(dataConnect, );
  }
  
  
  GetOrganizationByIdVariablesBuilder getOrganizationById ({required String id, }) {
    return GetOrganizationByIdVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListBranchesByOrgVariablesBuilder listBranchesByOrg ({required String orgId, }) {
    return ListBranchesByOrgVariablesBuilder(dataConnect, orgId: orgId,);
  }
  
  
  ListMembersByOrgVariablesBuilder listMembersByOrg ({required String orgId, }) {
    return ListMembersByOrgVariablesBuilder(dataConnect, orgId: orgId,);
  }
  
  
  ListReturnsByBranchVariablesBuilder listReturnsByBranch ({required String branchId, }) {
    return ListReturnsByBranchVariablesBuilder(dataConnect, branchId: branchId,);
  }
  
  
  GetCommercialAgreementByOrgVariablesBuilder getCommercialAgreementByOrg ({required String orgId, }) {
    return GetCommercialAgreementByOrgVariablesBuilder(dataConnect, orgId: orgId,);
  }
  
  
  ListLicenseEventsByOrgVariablesBuilder listLicenseEventsByOrg ({required String orgId, }) {
    return ListLicenseEventsByOrgVariablesBuilder(dataConnect, orgId: orgId,);
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
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
