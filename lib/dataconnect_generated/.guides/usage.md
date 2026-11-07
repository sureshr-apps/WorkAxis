# Basic Usage

```dart
WorkaxisConnectorConnector.instance.CreateOrganization(createOrganizationVariables).execute();
WorkaxisConnectorConnector.instance.UpdateOrganization(updateOrganizationVariables).execute();
WorkaxisConnectorConnector.instance.CreateBranch(createBranchVariables).execute();
WorkaxisConnectorConnector.instance.CreateOrganizationMember(createOrganizationMemberVariables).execute();
WorkaxisConnectorConnector.instance.CreateReturnRecord(createReturnRecordVariables).execute();
WorkaxisConnectorConnector.instance.UpdateReturnRecordStatus(updateReturnRecordStatusVariables).execute();
WorkaxisConnectorConnector.instance.ListOrganizations().execute();
WorkaxisConnectorConnector.instance.GetOrganizationById(getOrganizationByIdVariables).execute();
WorkaxisConnectorConnector.instance.ListBranchesByOrg(listBranchesByOrgVariables).execute();
WorkaxisConnectorConnector.instance.ListMembersByOrg(listMembersByOrgVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await WorkaxisConnectorConnector.instance.CreateOrganizationMember({ ... })
.phone(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

