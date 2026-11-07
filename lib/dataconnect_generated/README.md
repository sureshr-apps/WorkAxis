# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
WorkaxisConnectorConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### ListOrganizations
#### Required Arguments
```dart
// No required arguments
WorkaxisConnectorConnector.instance.listOrganizations().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListOrganizationsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await WorkaxisConnectorConnector.instance.listOrganizations();
ListOrganizationsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = WorkaxisConnectorConnector.instance.listOrganizations().ref();
ref.execute();

ref.subscribe(...);
```


### GetOrganizationById
#### Required Arguments
```dart
String id = ...;
WorkaxisConnectorConnector.instance.getOrganizationById(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetOrganizationByIdData, GetOrganizationByIdVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await WorkaxisConnectorConnector.instance.getOrganizationById(
  id: id,
);
GetOrganizationByIdData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = WorkaxisConnectorConnector.instance.getOrganizationById(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListBranchesByOrg
#### Required Arguments
```dart
String orgId = ...;
WorkaxisConnectorConnector.instance.listBranchesByOrg(
  orgId: orgId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListBranchesByOrgData, ListBranchesByOrgVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await WorkaxisConnectorConnector.instance.listBranchesByOrg(
  orgId: orgId,
);
ListBranchesByOrgData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;

final ref = WorkaxisConnectorConnector.instance.listBranchesByOrg(
  orgId: orgId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListMembersByOrg
#### Required Arguments
```dart
String orgId = ...;
WorkaxisConnectorConnector.instance.listMembersByOrg(
  orgId: orgId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListMembersByOrgData, ListMembersByOrgVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await WorkaxisConnectorConnector.instance.listMembersByOrg(
  orgId: orgId,
);
ListMembersByOrgData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;

final ref = WorkaxisConnectorConnector.instance.listMembersByOrg(
  orgId: orgId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListReturnsByBranch
#### Required Arguments
```dart
String branchId = ...;
WorkaxisConnectorConnector.instance.listReturnsByBranch(
  branchId: branchId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListReturnsByBranchData, ListReturnsByBranchVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await WorkaxisConnectorConnector.instance.listReturnsByBranch(
  branchId: branchId,
);
ListReturnsByBranchData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String branchId = ...;

final ref = WorkaxisConnectorConnector.instance.listReturnsByBranch(
  branchId: branchId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetCommercialAgreementByOrg
#### Required Arguments
```dart
String orgId = ...;
WorkaxisConnectorConnector.instance.getCommercialAgreementByOrg(
  orgId: orgId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetCommercialAgreementByOrgData, GetCommercialAgreementByOrgVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await WorkaxisConnectorConnector.instance.getCommercialAgreementByOrg(
  orgId: orgId,
);
GetCommercialAgreementByOrgData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;

final ref = WorkaxisConnectorConnector.instance.getCommercialAgreementByOrg(
  orgId: orgId,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListLicenseEventsByOrg
#### Required Arguments
```dart
String orgId = ...;
WorkaxisConnectorConnector.instance.listLicenseEventsByOrg(
  orgId: orgId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListLicenseEventsByOrgData, ListLicenseEventsByOrgVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await WorkaxisConnectorConnector.instance.listLicenseEventsByOrg(
  orgId: orgId,
);
ListLicenseEventsByOrgData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;

final ref = WorkaxisConnectorConnector.instance.listLicenseEventsByOrg(
  orgId: orgId,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateOrganization
#### Required Arguments
```dart
String id = ...;
String name = ...;
String code = ...;
WorkaxisConnectorConnector.instance.createOrganization(
  id: id,
  name: name,
  code: code,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateOrganization, we created `CreateOrganizationBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateOrganizationVariablesBuilder {
  ...
   CreateOrganizationVariablesBuilder category(String? t) {
   _category.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder country(String? t) {
   _country.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder currency(String? t) {
   _currency.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.createOrganization(
  id: id,
  name: name,
  code: code,
)
.category(category)
.country(country)
.status(status)
.currency(currency)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateOrganizationData, CreateOrganizationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.createOrganization(
  id: id,
  name: name,
  code: code,
);
CreateOrganizationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String name = ...;
String code = ...;

final ref = WorkaxisConnectorConnector.instance.createOrganization(
  id: id,
  name: name,
  code: code,
).ref();
ref.execute();
```


### UpdateOrganization
#### Required Arguments
```dart
String id = ...;
WorkaxisConnectorConnector.instance.updateOrganization(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateOrganization, we created `UpdateOrganizationBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateOrganizationVariablesBuilder {
  ...
   UpdateOrganizationVariablesBuilder name(String? t) {
   _name.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder category(String? t) {
   _category.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder country(String? t) {
   _country.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.updateOrganization(
  id: id,
)
.name(name)
.status(status)
.category(category)
.country(country)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateOrganizationData, UpdateOrganizationVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.updateOrganization(
  id: id,
);
UpdateOrganizationData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = WorkaxisConnectorConnector.instance.updateOrganization(
  id: id,
).ref();
ref.execute();
```


### CreateBranch
#### Required Arguments
```dart
String id = ...;
String orgId = ...;
String name = ...;
String code = ...;
WorkaxisConnectorConnector.instance.createBranch(
  id: id,
  orgId: orgId,
  name: name,
  code: code,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateBranch, we created `CreateBranchBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateBranchVariablesBuilder {
  ...
   CreateBranchVariablesBuilder location(String? t) {
   _location.value = t;
   return this;
  }
  CreateBranchVariablesBuilder isMainBranch(bool? t) {
   _isMainBranch.value = t;
   return this;
  }
  CreateBranchVariablesBuilder geofenceRadiusMeters(int? t) {
   _geofenceRadiusMeters.value = t;
   return this;
  }
  CreateBranchVariablesBuilder latitude(double? t) {
   _latitude.value = t;
   return this;
  }
  CreateBranchVariablesBuilder longitude(double? t) {
   _longitude.value = t;
   return this;
  }
  CreateBranchVariablesBuilder kioskEnabled(bool? t) {
   _kioskEnabled.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.createBranch(
  id: id,
  orgId: orgId,
  name: name,
  code: code,
)
.location(location)
.isMainBranch(isMainBranch)
.geofenceRadiusMeters(geofenceRadiusMeters)
.latitude(latitude)
.longitude(longitude)
.kioskEnabled(kioskEnabled)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateBranchData, CreateBranchVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.createBranch(
  id: id,
  orgId: orgId,
  name: name,
  code: code,
);
CreateBranchData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String orgId = ...;
String name = ...;
String code = ...;

final ref = WorkaxisConnectorConnector.instance.createBranch(
  id: id,
  orgId: orgId,
  name: name,
  code: code,
).ref();
ref.execute();
```


### CreateOrganizationMember
#### Required Arguments
```dart
String id = ...;
String orgId = ...;
String fullName = ...;
String username = ...;
String email = ...;
String role = ...;
WorkaxisConnectorConnector.instance.createOrganizationMember(
  id: id,
  orgId: orgId,
  fullName: fullName,
  username: username,
  email: email,
  role: role,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateOrganizationMember, we created `CreateOrganizationMemberBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateOrganizationMemberVariablesBuilder {
  ...
   CreateOrganizationMemberVariablesBuilder phone(String? t) {
   _phone.value = t;
   return this;
  }
  CreateOrganizationMemberVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.createOrganizationMember(
  id: id,
  orgId: orgId,
  fullName: fullName,
  username: username,
  email: email,
  role: role,
)
.phone(phone)
.status(status)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateOrganizationMemberData, CreateOrganizationMemberVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.createOrganizationMember(
  id: id,
  orgId: orgId,
  fullName: fullName,
  username: username,
  email: email,
  role: role,
);
CreateOrganizationMemberData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String orgId = ...;
String fullName = ...;
String username = ...;
String email = ...;
String role = ...;

final ref = WorkaxisConnectorConnector.instance.createOrganizationMember(
  id: id,
  orgId: orgId,
  fullName: fullName,
  username: username,
  email: email,
  role: role,
).ref();
ref.execute();
```


### CreateReturnRecord
#### Required Arguments
```dart
String id = ...;
String orgId = ...;
String branchId = ...;
String employeeId = ...;
String employeeName = ...;
String customerName = ...;
String invoiceNumber = ...;
String returnReason = ...;
double amount = ...;
WorkaxisConnectorConnector.instance.createReturnRecord(
  id: id,
  orgId: orgId,
  branchId: branchId,
  employeeId: employeeId,
  employeeName: employeeName,
  customerName: customerName,
  invoiceNumber: invoiceNumber,
  returnReason: returnReason,
  amount: amount,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateReturnRecordData, CreateReturnRecordVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.createReturnRecord(
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
CreateReturnRecordData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String orgId = ...;
String branchId = ...;
String employeeId = ...;
String employeeName = ...;
String customerName = ...;
String invoiceNumber = ...;
String returnReason = ...;
double amount = ...;

final ref = WorkaxisConnectorConnector.instance.createReturnRecord(
  id: id,
  orgId: orgId,
  branchId: branchId,
  employeeId: employeeId,
  employeeName: employeeName,
  customerName: customerName,
  invoiceNumber: invoiceNumber,
  returnReason: returnReason,
  amount: amount,
).ref();
ref.execute();
```


### UpdateReturnRecordStatus
#### Required Arguments
```dart
String id = ...;
String status = ...;
WorkaxisConnectorConnector.instance.updateReturnRecordStatus(
  id: id,
  status: status,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateReturnRecordStatusData, UpdateReturnRecordStatusVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.updateReturnRecordStatus(
  id: id,
  status: status,
);
UpdateReturnRecordStatusData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String status = ...;

final ref = WorkaxisConnectorConnector.instance.updateReturnRecordStatus(
  id: id,
  status: status,
).ref();
ref.execute();
```

