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


### ListOrganizationsPaged
#### Required Arguments
```dart
int limit = ...;
int offset = ...;
WorkaxisConnectorConnector.instance.listOrganizationsPaged(
  limit: limit,
  offset: offset,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ListOrganizationsPaged, we created `ListOrganizationsPagedBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListOrganizationsPagedVariablesBuilder {
  ...
   ListOrganizationsPagedVariablesBuilder nameContains(String? t) {
   _nameContains.value = t;
   return this;
  }
  ListOrganizationsPagedVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.listOrganizationsPaged(
  limit: limit,
  offset: offset,
)
.nameContains(nameContains)
.status(status)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListOrganizationsPagedData, ListOrganizationsPagedVariables>`
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

final result = await WorkaxisConnectorConnector.instance.listOrganizationsPaged(
  limit: limit,
  offset: offset,
);
ListOrganizationsPagedData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
int limit = ...;
int offset = ...;

final ref = WorkaxisConnectorConnector.instance.listOrganizationsPaged(
  limit: limit,
  offset: offset,
).ref();
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


### GetOrganizationStats
#### Required Arguments
```dart
String orgId = ...;
WorkaxisConnectorConnector.instance.getOrganizationStats(
  orgId: orgId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetOrganizationStatsData, GetOrganizationStatsVariables>`
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

final result = await WorkaxisConnectorConnector.instance.getOrganizationStats(
  orgId: orgId,
);
GetOrganizationStatsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;

final ref = WorkaxisConnectorConnector.instance.getOrganizationStats(
  orgId: orgId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetPlatformStats
#### Required Arguments
```dart
// No required arguments
WorkaxisConnectorConnector.instance.getPlatformStats().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetPlatformStatsData, void>`
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

final result = await WorkaxisConnectorConnector.instance.getPlatformStats();
GetPlatformStatsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = WorkaxisConnectorConnector.instance.getPlatformStats().ref();
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


### GetBranchById
#### Required Arguments
```dart
String id = ...;
WorkaxisConnectorConnector.instance.getBranchById(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetBranchByIdData, GetBranchByIdVariables>`
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

final result = await WorkaxisConnectorConnector.instance.getBranchById(
  id: id,
);
GetBranchByIdData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = WorkaxisConnectorConnector.instance.getBranchById(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListMyBranchAssignments
#### Required Arguments
```dart
// No required arguments
WorkaxisConnectorConnector.instance.listMyBranchAssignments().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListMyBranchAssignmentsData, void>`
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

final result = await WorkaxisConnectorConnector.instance.listMyBranchAssignments();
ListMyBranchAssignmentsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = WorkaxisConnectorConnector.instance.listMyBranchAssignments().ref();
ref.execute();

ref.subscribe(...);
```


### GetMyMember
#### Required Arguments
```dart
// No required arguments
WorkaxisConnectorConnector.instance.getMyMember().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyMemberData, void>`
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

final result = await WorkaxisConnectorConnector.instance.getMyMember();
GetMyMemberData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = WorkaxisConnectorConnector.instance.getMyMember().ref();
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


### ListMembersByOrgPaged
#### Required Arguments
```dart
String orgId = ...;
int limit = ...;
int offset = ...;
WorkaxisConnectorConnector.instance.listMembersByOrgPaged(
  orgId: orgId,
  limit: limit,
  offset: offset,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ListMembersByOrgPaged, we created `ListMembersByOrgPagedBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListMembersByOrgPagedVariablesBuilder {
  ...
   ListMembersByOrgPagedVariablesBuilder nameContains(String? t) {
   _nameContains.value = t;
   return this;
  }
  ListMembersByOrgPagedVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }
  ListMembersByOrgPagedVariablesBuilder role(String? t) {
   _role.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.listMembersByOrgPaged(
  orgId: orgId,
  limit: limit,
  offset: offset,
)
.nameContains(nameContains)
.status(status)
.role(role)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListMembersByOrgPagedData, ListMembersByOrgPagedVariables>`
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

final result = await WorkaxisConnectorConnector.instance.listMembersByOrgPaged(
  orgId: orgId,
  limit: limit,
  offset: offset,
);
ListMembersByOrgPagedData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;
int limit = ...;
int offset = ...;

final ref = WorkaxisConnectorConnector.instance.listMembersByOrgPaged(
  orgId: orgId,
  limit: limit,
  offset: offset,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListMembersByBranchPaged
#### Required Arguments
```dart
String branchId = ...;
int limit = ...;
int offset = ...;
WorkaxisConnectorConnector.instance.listMembersByBranchPaged(
  branchId: branchId,
  limit: limit,
  offset: offset,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ListMembersByBranchPaged, we created `ListMembersByBranchPagedBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListMembersByBranchPagedVariablesBuilder {
  ...
   ListMembersByBranchPagedVariablesBuilder nameContains(String? t) {
   _nameContains.value = t;
   return this;
  }
  ListMembersByBranchPagedVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.listMembersByBranchPaged(
  branchId: branchId,
  limit: limit,
  offset: offset,
)
.nameContains(nameContains)
.status(status)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListMembersByBranchPagedData, ListMembersByBranchPagedVariables>`
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

final result = await WorkaxisConnectorConnector.instance.listMembersByBranchPaged(
  branchId: branchId,
  limit: limit,
  offset: offset,
);
ListMembersByBranchPagedData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String branchId = ...;
int limit = ...;
int offset = ...;

final ref = WorkaxisConnectorConnector.instance.listMembersByBranchPaged(
  branchId: branchId,
  limit: limit,
  offset: offset,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetMemberById
#### Required Arguments
```dart
String id = ...;
WorkaxisConnectorConnector.instance.getMemberById(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMemberByIdData, GetMemberByIdVariables>`
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

final result = await WorkaxisConnectorConnector.instance.getMemberById(
  id: id,
);
GetMemberByIdData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = WorkaxisConnectorConnector.instance.getMemberById(
  id: id,
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


### ListReturnsByBranchPaged
#### Required Arguments
```dart
String branchId = ...;
int limit = ...;
int offset = ...;
WorkaxisConnectorConnector.instance.listReturnsByBranchPaged(
  branchId: branchId,
  limit: limit,
  offset: offset,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ListReturnsByBranchPaged, we created `ListReturnsByBranchPagedBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListReturnsByBranchPagedVariablesBuilder {
  ...
   ListReturnsByBranchPagedVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.listReturnsByBranchPaged(
  branchId: branchId,
  limit: limit,
  offset: offset,
)
.status(status)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListReturnsByBranchPagedData, ListReturnsByBranchPagedVariables>`
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

final result = await WorkaxisConnectorConnector.instance.listReturnsByBranchPaged(
  branchId: branchId,
  limit: limit,
  offset: offset,
);
ListReturnsByBranchPagedData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String branchId = ...;
int limit = ...;
int offset = ...;

final ref = WorkaxisConnectorConnector.instance.listReturnsByBranchPaged(
  branchId: branchId,
  limit: limit,
  offset: offset,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListReturnsByOrgPaged
#### Required Arguments
```dart
String orgId = ...;
int limit = ...;
int offset = ...;
WorkaxisConnectorConnector.instance.listReturnsByOrgPaged(
  orgId: orgId,
  limit: limit,
  offset: offset,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ListReturnsByOrgPaged, we created `ListReturnsByOrgPagedBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListReturnsByOrgPagedVariablesBuilder {
  ...
   ListReturnsByOrgPagedVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }
  ListReturnsByOrgPagedVariablesBuilder branchId(String? t) {
   _branchId.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.listReturnsByOrgPaged(
  orgId: orgId,
  limit: limit,
  offset: offset,
)
.status(status)
.branchId(branchId)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListReturnsByOrgPagedData, ListReturnsByOrgPagedVariables>`
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

final result = await WorkaxisConnectorConnector.instance.listReturnsByOrgPaged(
  orgId: orgId,
  limit: limit,
  offset: offset,
);
ListReturnsByOrgPagedData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;
int limit = ...;
int offset = ...;

final ref = WorkaxisConnectorConnector.instance.listReturnsByOrgPaged(
  orgId: orgId,
  limit: limit,
  offset: offset,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListMyReturns
#### Required Arguments
```dart
int limit = ...;
int offset = ...;
WorkaxisConnectorConnector.instance.listMyReturns(
  limit: limit,
  offset: offset,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ListMyReturns, we created `ListMyReturnsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListMyReturnsVariablesBuilder {
  ...
   ListMyReturnsVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.listMyReturns(
  limit: limit,
  offset: offset,
)
.status(status)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListMyReturnsData, ListMyReturnsVariables>`
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

final result = await WorkaxisConnectorConnector.instance.listMyReturns(
  limit: limit,
  offset: offset,
);
ListMyReturnsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
int limit = ...;
int offset = ...;

final ref = WorkaxisConnectorConnector.instance.listMyReturns(
  limit: limit,
  offset: offset,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetOrganizationDashboardCounts
#### Required Arguments
```dart
String orgId = ...;
WorkaxisConnectorConnector.instance.getOrganizationDashboardCounts(
  orgId: orgId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetOrganizationDashboardCountsData, GetOrganizationDashboardCountsVariables>`
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

final result = await WorkaxisConnectorConnector.instance.getOrganizationDashboardCounts(
  orgId: orgId,
);
GetOrganizationDashboardCountsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;

final ref = WorkaxisConnectorConnector.instance.getOrganizationDashboardCounts(
  orgId: orgId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetReturnCountsByBranch
#### Required Arguments
```dart
String orgId = ...;
WorkaxisConnectorConnector.instance.getReturnCountsByBranch(
  orgId: orgId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For GetReturnCountsByBranch, we created `GetReturnCountsByBranchBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetReturnCountsByBranchVariablesBuilder {
  ...
   GetReturnCountsByBranchVariablesBuilder from(Timestamp? t) {
   _from.value = t;
   return this;
  }
  GetReturnCountsByBranchVariablesBuilder to(Timestamp? t) {
   _to.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.getReturnCountsByBranch(
  orgId: orgId,
)
.from(from)
.to(to)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetReturnCountsByBranchData, GetReturnCountsByBranchVariables>`
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

final result = await WorkaxisConnectorConnector.instance.getReturnCountsByBranch(
  orgId: orgId,
);
GetReturnCountsByBranchData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;

final ref = WorkaxisConnectorConnector.instance.getReturnCountsByBranch(
  orgId: orgId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetBranchStats
#### Required Arguments
```dart
String branchId = ...;
WorkaxisConnectorConnector.instance.getBranchStats(
  branchId: branchId,
).execute();
```

#### Optional Arguments
We return a builder for each query. For GetBranchStats, we created `GetBranchStatsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetBranchStatsVariablesBuilder {
  ...
   GetBranchStatsVariablesBuilder from(Timestamp? t) {
   _from.value = t;
   return this;
  }
  GetBranchStatsVariablesBuilder to(Timestamp? t) {
   _to.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.getBranchStats(
  branchId: branchId,
)
.from(from)
.to(to)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetBranchStatsData, GetBranchStatsVariables>`
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

final result = await WorkaxisConnectorConnector.instance.getBranchStats(
  branchId: branchId,
);
GetBranchStatsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String branchId = ...;

final ref = WorkaxisConnectorConnector.instance.getBranchStats(
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


### ListPlatformMembersPaged
#### Required Arguments
```dart
int limit = ...;
int offset = ...;
WorkaxisConnectorConnector.instance.listPlatformMembersPaged(
  limit: limit,
  offset: offset,
).execute();
```

#### Optional Arguments
We return a builder for each query. For ListPlatformMembersPaged, we created `ListPlatformMembersPagedBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class ListPlatformMembersPagedVariablesBuilder {
  ...
   ListPlatformMembersPagedVariablesBuilder nameContains(String? t) {
   _nameContains.value = t;
   return this;
  }
  ListPlatformMembersPagedVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.listPlatformMembersPaged(
  limit: limit,
  offset: offset,
)
.nameContains(nameContains)
.status(status)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<ListPlatformMembersPagedData, ListPlatformMembersPagedVariables>`
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

final result = await WorkaxisConnectorConnector.instance.listPlatformMembersPaged(
  limit: limit,
  offset: offset,
);
ListPlatformMembersPagedData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
int limit = ...;
int offset = ...;

final ref = WorkaxisConnectorConnector.instance.listPlatformMembersPaged(
  limit: limit,
  offset: offset,
).ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateOrganization
#### Required Arguments
```dart
String name = ...;
String code = ...;
WorkaxisConnectorConnector.instance.createOrganization(
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
 
  CreateOrganizationVariablesBuilder id(String? t) {
   _id.value = t;
   return this;
  }
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
  CreateOrganizationVariablesBuilder taxIdentification(String? t) {
   _taxIdentification.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder contactName(String? t) {
   _contactName.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder contactEmail(String? t) {
   _contactEmail.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder contactPhone(String? t) {
   _contactPhone.value = t;
   return this;
  }
  CreateOrganizationVariablesBuilder address(String? t) {
   _address.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.createOrganization(
  name: name,
  code: code,
)
.id(id)
.category(category)
.country(country)
.status(status)
.currency(currency)
.taxIdentification(taxIdentification)
.description(description)
.contactName(contactName)
.contactEmail(contactEmail)
.contactPhone(contactPhone)
.address(address)
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
String name = ...;
String code = ...;

final ref = WorkaxisConnectorConnector.instance.createOrganization(
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
  UpdateOrganizationVariablesBuilder currency(String? t) {
   _currency.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder logoUrl(String? t) {
   _logoUrl.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder taxIdentification(String? t) {
   _taxIdentification.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder contactName(String? t) {
   _contactName.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder contactEmail(String? t) {
   _contactEmail.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder contactPhone(String? t) {
   _contactPhone.value = t;
   return this;
  }
  UpdateOrganizationVariablesBuilder address(String? t) {
   _address.value = t;
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
.currency(currency)
.logoUrl(logoUrl)
.taxIdentification(taxIdentification)
.description(description)
.contactName(contactName)
.contactEmail(contactEmail)
.contactPhone(contactPhone)
.address(address)
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


### CreateCommercialAgreement
#### Required Arguments
```dart
String orgId = ...;
String agreementReference = ...;
String planName = ...;
String planTier = ...;
double negotiatedPrice = ...;
double annualMaintenancePrice = ...;
int maxStores = ...;
int maxUsers = ...;
DateTime startDate = ...;
DateTime expiryDate = ...;
WorkaxisConnectorConnector.instance.createCommercialAgreement(
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
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateCommercialAgreement, we created `CreateCommercialAgreementBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateCommercialAgreementVariablesBuilder {
  ...
   CreateCommercialAgreementVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.createCommercialAgreement(
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
)
.status(status)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateCommercialAgreementData, CreateCommercialAgreementVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.createCommercialAgreement(
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
CreateCommercialAgreementData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;
String agreementReference = ...;
String planName = ...;
String planTier = ...;
double negotiatedPrice = ...;
double annualMaintenancePrice = ...;
int maxStores = ...;
int maxUsers = ...;
DateTime startDate = ...;
DateTime expiryDate = ...;

final ref = WorkaxisConnectorConnector.instance.createCommercialAgreement(
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
).ref();
ref.execute();
```


### UpdateCommercialAgreement
#### Required Arguments
```dart
String id = ...;
WorkaxisConnectorConnector.instance.updateCommercialAgreement(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateCommercialAgreement, we created `UpdateCommercialAgreementBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateCommercialAgreementVariablesBuilder {
  ...
   UpdateCommercialAgreementVariablesBuilder planName(String? t) {
   _planName.value = t;
   return this;
  }
  UpdateCommercialAgreementVariablesBuilder planTier(String? t) {
   _planTier.value = t;
   return this;
  }
  UpdateCommercialAgreementVariablesBuilder negotiatedPrice(double? t) {
   _negotiatedPrice.value = t;
   return this;
  }
  UpdateCommercialAgreementVariablesBuilder annualMaintenancePrice(double? t) {
   _annualMaintenancePrice.value = t;
   return this;
  }
  UpdateCommercialAgreementVariablesBuilder maxStores(int? t) {
   _maxStores.value = t;
   return this;
  }
  UpdateCommercialAgreementVariablesBuilder maxUsers(int? t) {
   _maxUsers.value = t;
   return this;
  }
  UpdateCommercialAgreementVariablesBuilder startDate(DateTime? t) {
   _startDate.value = t;
   return this;
  }
  UpdateCommercialAgreementVariablesBuilder expiryDate(DateTime? t) {
   _expiryDate.value = t;
   return this;
  }
  UpdateCommercialAgreementVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.updateCommercialAgreement(
  id: id,
)
.planName(planName)
.planTier(planTier)
.negotiatedPrice(negotiatedPrice)
.annualMaintenancePrice(annualMaintenancePrice)
.maxStores(maxStores)
.maxUsers(maxUsers)
.startDate(startDate)
.expiryDate(expiryDate)
.status(status)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateCommercialAgreementData, UpdateCommercialAgreementVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.updateCommercialAgreement(
  id: id,
);
UpdateCommercialAgreementData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = WorkaxisConnectorConnector.instance.updateCommercialAgreement(
  id: id,
).ref();
ref.execute();
```


### CreateLicenseEvent
#### Required Arguments
```dart
String orgId = ...;
String eventType = ...;
String planName = ...;
String planTier = ...;
String validityPeriod = ...;
int storesCount = ...;
int usersCount = ...;
double oneTimePrice = ...;
double annualMaintenancePrice = ...;
WorkaxisConnectorConnector.instance.createLicenseEvent(
  orgId: orgId,
  eventType: eventType,
  planName: planName,
  planTier: planTier,
  validityPeriod: validityPeriod,
  storesCount: storesCount,
  usersCount: usersCount,
  oneTimePrice: oneTimePrice,
  annualMaintenancePrice: annualMaintenancePrice,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateLicenseEventData, CreateLicenseEventVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.createLicenseEvent(
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
CreateLicenseEventData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;
String eventType = ...;
String planName = ...;
String planTier = ...;
String validityPeriod = ...;
int storesCount = ...;
int usersCount = ...;
double oneTimePrice = ...;
double annualMaintenancePrice = ...;

final ref = WorkaxisConnectorConnector.instance.createLicenseEvent(
  orgId: orgId,
  eventType: eventType,
  planName: planName,
  planTier: planTier,
  validityPeriod: validityPeriod,
  storesCount: storesCount,
  usersCount: usersCount,
  oneTimePrice: oneTimePrice,
  annualMaintenancePrice: annualMaintenancePrice,
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


### AddBranch
#### Required Arguments
```dart
String orgId = ...;
String name = ...;
String code = ...;
WorkaxisConnectorConnector.instance.addBranch(
  orgId: orgId,
  name: name,
  code: code,
).execute();
```

#### Optional Arguments
We return a builder for each query. For AddBranch, we created `AddBranchBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class AddBranchVariablesBuilder {
  ...
   AddBranchVariablesBuilder location(String? t) {
   _location.value = t;
   return this;
  }
  AddBranchVariablesBuilder isMainBranch(bool? t) {
   _isMainBranch.value = t;
   return this;
  }
  AddBranchVariablesBuilder geofenceRadiusMeters(int? t) {
   _geofenceRadiusMeters.value = t;
   return this;
  }
  AddBranchVariablesBuilder latitude(double? t) {
   _latitude.value = t;
   return this;
  }
  AddBranchVariablesBuilder longitude(double? t) {
   _longitude.value = t;
   return this;
  }
  AddBranchVariablesBuilder kioskEnabled(bool? t) {
   _kioskEnabled.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.addBranch(
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
`execute()` returns a `OperationResult<AddBranchData, AddBranchVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.addBranch(
  orgId: orgId,
  name: name,
  code: code,
);
AddBranchData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orgId = ...;
String name = ...;
String code = ...;

final ref = WorkaxisConnectorConnector.instance.addBranch(
  orgId: orgId,
  name: name,
  code: code,
).ref();
ref.execute();
```


### UpdateBranch
#### Required Arguments
```dart
String id = ...;
WorkaxisConnectorConnector.instance.updateBranch(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateBranch, we created `UpdateBranchBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateBranchVariablesBuilder {
  ...
   UpdateBranchVariablesBuilder name(String? t) {
   _name.value = t;
   return this;
  }
  UpdateBranchVariablesBuilder code(String? t) {
   _code.value = t;
   return this;
  }
  UpdateBranchVariablesBuilder location(String? t) {
   _location.value = t;
   return this;
  }
  UpdateBranchVariablesBuilder status(String? t) {
   _status.value = t;
   return this;
  }
  UpdateBranchVariablesBuilder isMainBranch(bool? t) {
   _isMainBranch.value = t;
   return this;
  }
  UpdateBranchVariablesBuilder geofenceRadiusMeters(int? t) {
   _geofenceRadiusMeters.value = t;
   return this;
  }
  UpdateBranchVariablesBuilder latitude(double? t) {
   _latitude.value = t;
   return this;
  }
  UpdateBranchVariablesBuilder longitude(double? t) {
   _longitude.value = t;
   return this;
  }
  UpdateBranchVariablesBuilder kioskEnabled(bool? t) {
   _kioskEnabled.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.updateBranch(
  id: id,
)
.name(name)
.code(code)
.location(location)
.status(status)
.isMainBranch(isMainBranch)
.geofenceRadiusMeters(geofenceRadiusMeters)
.latitude(latitude)
.longitude(longitude)
.kioskEnabled(kioskEnabled)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateBranchData, UpdateBranchVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.updateBranch(
  id: id,
);
UpdateBranchData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = WorkaxisConnectorConnector.instance.updateBranch(
  id: id,
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

#### Optional Arguments
We return a builder for each query. For CreateReturnRecord, we created `CreateReturnRecordBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateReturnRecordVariablesBuilder {
  ...
   CreateReturnRecordVariablesBuilder productTitle(String? t) {
   _productTitle.value = t;
   return this;
  }
  CreateReturnRecordVariablesBuilder quantity(double? t) {
   _quantity.value = t;
   return this;
  }
  CreateReturnRecordVariablesBuilder unit(String? t) {
   _unit.value = t;
   return this;
  }
  CreateReturnRecordVariablesBuilder billImageUrl(String? t) {
   _billImageUrl.value = t;
   return this;
  }
  CreateReturnRecordVariablesBuilder remarks(String? t) {
   _remarks.value = t;
   return this;
  }

  ...
}
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
)
.productTitle(productTitle)
.quantity(quantity)
.unit(unit)
.billImageUrl(billImageUrl)
.remarks(remarks)
.execute();
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


### SubmitReturn
#### Required Arguments
```dart
String branchId = ...;
String productTitle = ...;
String returnReason = ...;
double quantity = ...;
String unit = ...;
String invoiceNumber = ...;
WorkaxisConnectorConnector.instance.submitReturn(
  branchId: branchId,
  productTitle: productTitle,
  returnReason: returnReason,
  quantity: quantity,
  unit: unit,
  invoiceNumber: invoiceNumber,
).execute();
```

#### Optional Arguments
We return a builder for each query. For SubmitReturn, we created `SubmitReturnBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class SubmitReturnVariablesBuilder {
  ...
   SubmitReturnVariablesBuilder billImageUrl(String? t) {
   _billImageUrl.value = t;
   return this;
  }
  SubmitReturnVariablesBuilder remarks(String? t) {
   _remarks.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.submitReturn(
  branchId: branchId,
  productTitle: productTitle,
  returnReason: returnReason,
  quantity: quantity,
  unit: unit,
  invoiceNumber: invoiceNumber,
)
.billImageUrl(billImageUrl)
.remarks(remarks)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<SubmitReturnData, SubmitReturnVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.submitReturn(
  branchId: branchId,
  productTitle: productTitle,
  returnReason: returnReason,
  quantity: quantity,
  unit: unit,
  invoiceNumber: invoiceNumber,
);
SubmitReturnData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String branchId = ...;
String productTitle = ...;
String returnReason = ...;
double quantity = ...;
String unit = ...;
String invoiceNumber = ...;

final ref = WorkaxisConnectorConnector.instance.submitReturn(
  branchId: branchId,
  productTitle: productTitle,
  returnReason: returnReason,
  quantity: quantity,
  unit: unit,
  invoiceNumber: invoiceNumber,
).ref();
ref.execute();
```


### UpdateReturnRecordReview
#### Required Arguments
```dart
String id = ...;
String status = ...;
WorkaxisConnectorConnector.instance.updateReturnRecordReview(
  id: id,
  status: status,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateReturnRecordReview, we created `UpdateReturnRecordReviewBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateReturnRecordReviewVariablesBuilder {
  ...
   UpdateReturnRecordReviewVariablesBuilder reviewerNotes(String? t) {
   _reviewerNotes.value = t;
   return this;
  }

  ...
}
WorkaxisConnectorConnector.instance.updateReturnRecordReview(
  id: id,
  status: status,
)
.reviewerNotes(reviewerNotes)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateReturnRecordReviewData, UpdateReturnRecordReviewVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await WorkaxisConnectorConnector.instance.updateReturnRecordReview(
  id: id,
  status: status,
);
UpdateReturnRecordReviewData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String status = ...;

final ref = WorkaxisConnectorConnector.instance.updateReturnRecordReview(
  id: id,
  status: status,
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

