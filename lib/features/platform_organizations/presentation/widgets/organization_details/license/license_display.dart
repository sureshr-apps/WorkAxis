import 'package:workaxis/core/widgets/status_chip.dart';
import 'package:workaxis/features/platform_organizations/domain/models/license_history_event.dart';
import 'package:workaxis/features/platform_organizations/domain/models/organization_license.dart';

/// Labels and chip tones for the license status, as the summary shows them.
extension OrganizationLicenseStatusDisplay on OrganizationLicenseStatus {
  String get label => switch (this) {
    OrganizationLicenseStatus.notAssigned => 'Not Assigned',
    OrganizationLicenseStatus.notYetActive => 'Not Yet Active',
    OrganizationLicenseStatus.active => 'Active',
    OrganizationLicenseStatus.expiringSoon => 'Expiring Soon',
    OrganizationLicenseStatus.expired => 'Expired',
  };

  /// Tone of the status chip. Colour is never the only cue: the label is shown too.
  StatusType get chipType => switch (this) {
    OrganizationLicenseStatus.active => StatusType.active,
    OrganizationLicenseStatus.expiringSoon => StatusType.pending,
    OrganizationLicenseStatus.expired => StatusType.urgent,
    OrganizationLicenseStatus.notYetActive ||
    OrganizationLicenseStatus.notAssigned => StatusType.neutral,
  };
}

/// Human labels for history event types.
extension LicenseEventTypeDisplay on LicenseEventType {
  String get label => switch (this) {
    LicenseEventType.assigned => 'License Assigned',
    LicenseEventType.planChanged => 'Plan Changed',
    LicenseEventType.commercialTermsModified => 'Commercial Terms Modified',
    LicenseEventType.renewed => 'License Renewed',
  };
}
