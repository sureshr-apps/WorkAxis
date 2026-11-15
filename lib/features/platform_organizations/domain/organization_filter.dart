import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';

/// The longest search the server accepts (`nameContains`). The search field
/// stops input at this length so a longer search never reaches the server.
const int organizationSearchMaxLength = 200;

/// Keeps the organizations that match [status] (when given) and whose name or
/// code contains [query] (ignoring case and surrounding spaces).
///
/// The server applies the same name-or-code match to the paged list, so a
/// search finds the same organizations whether the rows are filtered here or
/// by the server.
List<CustomerOrganization> filterOrganizations(
  Iterable<CustomerOrganization> organizations, {
  OrganizationStatus? status,
  String query = '',
}) {
  final needle = query.trim().toLowerCase();
  return organizations
      .where((org) {
        if (status != null && org.status != status) return false;
        if (needle.isEmpty) return true;
        return org.name.toLowerCase().contains(needle) ||
            org.code.toLowerCase().contains(needle);
      })
      .toList(growable: false);
}
