import 'package:workaxis/features/platform_organizations/domain/models/customer_organization.dart';
import 'package:workaxis/features/platform_organizations/domain/models/create_organization_request.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_admin_user.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_status.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license_details.dart';

/// In-memory mock data source for Platform Customer Organizations.
class MockPlatformOrganizationsDataSource {
  final List<CustomerOrganization> _organizations = [];
  // Crestline and newly created organizations start without an assigned plan.
  final Set<String> _licenseAssignedOrganizationIds = {
    'org-acme',
    'org-apex',
    'org-xyz',
    'org-northern',
    'org-metro',
    'org-abc',
  };
  int _nextGeneratedOrganizationNumber = 1;

  MockPlatformOrganizationsDataSource() {
    _initDefaultData();
  }

  void _initDefaultData() {
    _organizations.addAll([
      CustomerOrganization(
        id: 'org-acme',
        name: 'Acme Corporation',
        code: 'ORG-ACM-01',
        status: OrganizationStatus.active,
        branchCount: 18,
        employeeCount: 540,
        createdAt: DateTime(2024, 9, 14),
        description: 'Registered enterprise customer organization deployed across regional branch networks.',
        contactName: 'Marcus Sterling',
        contactEmail: 'operations@acmecorp.com',
        contactPhone: '+1 (555) 234-8900',
        taxIdentification: 'US-EIN-12-3456789',
        address: 'Acme Distribution HQ — Suite 400, 742 Evergreen Logistics Blvd, Sector 8, Industrial Corridor, IL 60611',
        admins: const [
          OrganizationAdminUser(
            id: 'admin-dw',
            name: 'David Warner',
            email: 'd.warner@acmecorp.com',
            phone: '+1 (555) 019-4481',
            roleTitle: 'Primary Admin',
            status: 'Active',
          ),
          OrganizationAdminUser(
            id: 'admin-el',
            name: 'Elena Lindqvist',
            email: 'e.lindqvist@acmecorp.com',
            phone: '+1 (555) 018-7729',
            roleTitle: 'Secondary Admin',
            status: 'Active',
          ),
        ],
      ),
      CustomerOrganization(
        id: 'org-apex',
        name: 'Apex Logistics & Freight',
        code: 'ORG-APX-01',
        status: OrganizationStatus.active,
        branchCount: 14,
        employeeCount: 420,
        createdAt: DateTime(2024, 10, 12),
        description:
            'Regional multi-modal logistics hub and freight transport network.',
        contactName: 'Marcus Sterling',
        contactEmail: 'operations@apexlogistics.com',
        contactPhone: '+1 (555) 019-2834',
        address: '742 Evergreen Logistics Blvd, Suite 400, Chicago, IL 60611',
        admins: const [
          OrganizationAdminUser(
            id: 'admin-ms',
            name: 'Marcus Sterling',
            email: 'operations@apexlogistics.com',
            phone: '+1 (555) 019-2834',
            roleTitle: 'Primary Admin',
            status: 'Active',
          ),
        ],
      ),
      CustomerOrganization(
        id: 'org-xyz',
        name: 'XYZ Retail Group',
        code: 'ORG-XYZ-04',
        status: OrganizationStatus.active,
        branchCount: 28,
        employeeCount: 860,
        createdAt: DateTime(2024, 11, 3),
        description:
            'Omnichannel retail operations across 28 metropolitan store hubs.',
        contactName: 'Rachel Adams',
        contactEmail: 'support@xyzretail.com',
        contactPhone: '+1 (555) 345-6789',
        address: '1200 Market Street, Suite 900, San Francisco, CA 94103',
        admins: const [
          OrganizationAdminUser(
            id: 'admin-ra',
            name: 'Rachel Adams',
            email: 'support@xyzretail.com',
            phone: '+1 (555) 345-6789',
            roleTitle: 'Primary Admin',
            status: 'Active',
          ),
        ],
      ),
      CustomerOrganization(
        id: 'org-northern',
        name: 'Northern Supply Chain Ltd',
        code: 'ORG-NSC-19',
        status: OrganizationStatus.suspended,
        branchCount: 8,
        employeeCount: 195,
        createdAt: DateTime(2024, 8, 18),
        description:
            'Cold chain storage and northern regional delivery logistics.',
        contactName: 'Jonathan Drake',
        contactEmail: 'ops@northernsupply.co.uk',
        contactPhone: '+44 20 7946 0912',
        address: 'Unit 4, Riverside Way, Dartford, DA1 5BS',
        admins: const [
          OrganizationAdminUser(
            id: 'admin-jd',
            name: 'Jonathan Drake',
            email: 'ops@northernsupply.co.uk',
            phone: '+44 20 7946 0912',
            roleTitle: 'Primary Admin',
            status: 'Active',
          ),
        ],
      ),
      CustomerOrganization(
        id: 'org-metro',
        name: 'Metro QuickServe Ops',
        code: 'ORG-MQS-52',
        status: OrganizationStatus.active,
        branchCount: 42,
        employeeCount: 1120,
        createdAt: DateTime(2024, 12, 1),
        description:
            'Rapid fulfillment and distribution kiosks for metropolitan zones.',
        contactName: 'Lisa Gomez',
        contactEmail: 'dispatch@metroquickserve.com',
        contactPhone: '+1 (555) 901-2345',
        address: '550 West 34th Street, New York, NY 10001',
        admins: const [
          OrganizationAdminUser(
            id: 'admin-lg',
            name: 'Lisa Gomez',
            email: 'dispatch@metroquickserve.com',
            phone: '+1 (555) 901-2345',
            roleTitle: 'Primary Admin',
            status: 'Active',
          ),
        ],
      ),
      CustomerOrganization(
        id: 'org-abc',
        name: 'ABC Enterprises Global',
        code: 'ORG-ABC-02',
        status: OrganizationStatus.active,
        branchCount: 19,
        employeeCount: 640,
        createdAt: DateTime(2025, 1, 15),
        description:
            'Enterprise commercial distribution and fulfillment centers.',
        contactName: 'Arthur Pendelton',
        contactEmail: 'contact@abcenterprises.com',
        contactPhone: '+1 (555) 432-1098',
        address: '800 Corporate Parkway, Atlanta, GA 30339',
        admins: const [
          OrganizationAdminUser(
            id: 'admin-ap',
            name: 'Arthur Pendelton',
            email: 'contact@abcenterprises.com',
            phone: '+1 (555) 432-1098',
            roleTitle: 'Primary Admin',
            status: 'Active',
          ),
        ],
      ),
      CustomerOrganization(
        id: 'org-crestline',
        name: 'Crestline Cold Storage',
        code: 'ORG-CCS-77',
        status: OrganizationStatus.suspended,
        branchCount: 5,
        employeeCount: 88,
        createdAt: DateTime(2025, 1, 22),
        description: 'Refrigerated warehousing and temperature-controlled freight logistics.',
        contactName: 'Henry Briggs',
        contactEmail: 'ops@crestlinecold.com',
        contactPhone: '+1 (555) 876-5432',
        address: '310 Freezer Lane, Green Bay, WI 54303',
        admins: const [], // Intentionally empty to test empty state
      ),
    ]);
  }

  List<CustomerOrganization> getOrganizations({
    String? query,
    OrganizationStatus? statusFilter,
  }) {
    return _organizations.where((org) {
      if (statusFilter != null && org.status != statusFilter) {
        return false;
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesName = org.name.toLowerCase().contains(q);
        final matchesCode = org.code.toLowerCase().contains(q);
        if (!matchesName && !matchesCode) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  CustomerOrganization? getById(String id) {
    try {
      return _organizations.firstWhere((org) => org.id == id);
    } catch (_) {
      return null;
    }
  }

  OrganizationLicenseDetails? getLicenseDetails(String id) {
    final organization = getById(id);
    if (organization == null || !_licenseAssignedOrganizationIds.contains(id)) {
      return null;
    }

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final expiry = DateTime(start.year + 1, start.month, start.day);
    final maximumStores = organization.branchCount == 0
        ? 1
        : organization.branchCount;
    final maximumUsers = organization.employeeCount < 15
        ? 15
        : organization.employeeCount;
    final agreementId = 'AGR-${organization.code}';
    final historyDate = DateTime(start.year, start.month, start.day, 10, 45);

    return OrganizationLicenseDetails(
      planName: 'Basic',
      status: 'Active',
      level: 1,
      agreementId: agreementId,
      agreementStart: start,
      agreementExpiry: expiry,
      maximumStores: maximumStores,
      maximumUsers: maximumUsers,
      negotiatedPrice: 40000,
      annualMaintenancePrice: 5000,
      history: [
        LicenseHistoryEntry(
          event: 'License Assigned',
          occurredAt: historyDate,
          planName: 'Basic',
          level: 1,
          periodStart: start,
          periodEnd: expiry,
          stores: maximumStores,
          users: maximumUsers,
          negotiatedPrice: 40000,
          annualMaintenancePrice: 5000,
        ),
      ],
    );
  }

  CustomerOrganization create(CreateOrganizationRequest request) {
    final organization = _createOrganizationWithGeneratedIdentifiers(request);
    _organizations.insert(0, organization);
    return organization;
  }

  CustomerOrganization _createOrganizationWithGeneratedIdentifiers(
    CreateOrganizationRequest request,
  ) {
    while (true) {
      final sequence = _nextGeneratedOrganizationNumber++;
      final suffix = sequence.toString().padLeft(3, '0');
      final id = 'org-generated-$suffix';
      final code = 'ORG-$suffix';
      final identifierAlreadyExists = _organizations.any(
        (organization) => organization.id == id || organization.code == code,
      );
      if (identifierAlreadyExists) continue;

      return CustomerOrganization(
        id: id,
        name: request.name,
        code: code,
        status: OrganizationStatus.active,
        branchCount: 0,
        employeeCount: 0,
        createdAt: DateTime.now(),
        taxIdentification: _optionalValue(request.taxIdentification),
        description: _optionalValue(request.description),
        contactName: _optionalValue(request.contactName),
        contactEmail: _optionalValue(request.contactEmail),
        contactPhone: _optionalValue(request.contactPhone),
        address: _optionalValue(request.address),
      );
    }
  }

  String? _optionalValue(String? value) {
    final trimmedValue = value?.trim();
    return trimmedValue == null || trimmedValue.isEmpty ? null : trimmedValue;
  }

  CustomerOrganization update(CustomerOrganization updated) {
    final index = _organizations.indexWhere((o) => o.id == updated.id);
    if (index == -1) {
      throw Exception('Organization not found with ID ${updated.id}');
    }
    _organizations[index] = updated;
    return updated;
  }

  CustomerOrganization setStatus(String id, OrganizationStatus newStatus) {
    final index = _organizations.indexWhere((o) => o.id == id);
    if (index == -1) {
      throw Exception('Organization not found with ID $id');
    }
    final updated = _organizations[index].copyWith(status: newStatus);
    _organizations[index] = updated;
    return updated;
  }
}
